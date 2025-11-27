const { sql, poolPromise } = require('./db');

const createForbiddenError = (message) => {
  const error = new Error(message);
  error.code = 'FORBIDDEN';
  return error;
};

const normalizeUserIds = (input) => {
  const source = Array.isArray(input) ? input : input !== undefined ? [input] : [];
  const parsed = source
    .map((value) => Number.parseInt(value, 10))
    .filter((value) => Number.isInteger(value));
  return [...new Set(parsed)];
};

const assertNonAdminCanManageHolder = async (transaction, holderId, userId) => {
  if (!Number.isInteger(userId)) {
    throw createForbiddenError('Bu işlem için yetkiniz bulunmuyor.');
  }

  const accessRequest = new sql.Request(transaction);
  accessRequest.input('holder_id', sql.Int, holderId);
  accessRequest.input('user_id', sql.Int, userId);
  const accessResult = await accessRequest.query(
    `SELECT h.control
     FROM holder h
     INNER JOIN holder_assignments ha ON ha.holder_id = h.id
     WHERE h.id = @holder_id
       AND ha.user_id = @user_id
       AND h.is_deleted = 0`,
  );
  const record = accessResult.recordset[0];
  if (!record) {
    throw createForbiddenError('Bu kart üzerinde işlem yetkiniz yok.');
  }
  if (Number(record.control) === 1) {
    throw createForbiddenError('Bu kartı yalnızca admin düzenleyebilir veya silebilir.');
  }
};

const mapHolderRows = (rows) => {
  const byId = new Map();
  rows.forEach((row) => {
    if (!byId.has(row.id)) {
      byId.set(row.id, {
        id: row.id,
        holder_title: row.holder_title,
        holder_email: row.holder_email,
        holder_password: row.holder_password,
        login_url: row.login_url ?? null,
        control: row.control,
        user_id: null,
        user_name: null,
        assigned_to: null,
        ownerName: null,
        assigned_users: [],
        assigned_user_ids: [],
        departmentId: row.department_id ?? null,
        departmentName: row.department_name ?? null,
      });
    }
    const holder = byId.get(row.id);
    if (row.assigned_user_id) {
      holder.assigned_users.push({
        id: row.assigned_user_id,
        name: row.assigned_user_name,
        email: row.assigned_user_email,
      });
    }
  });

  return Array.from(byId.values()).map((holder) => {
    if (holder.assigned_users.length > 0) {
      holder.assigned_user_ids = holder.assigned_users
        .map((user) => user.id)
        .filter((id) => Number.isInteger(id));
      const primary = holder.assigned_users[0];
      holder.user_id = primary?.id ?? null;
      holder.user_name = primary?.name ?? null;
      const assignedNames = holder.assigned_users
        .map((user) => user.name)
        .filter((name) => Boolean(name && name.trim().length > 0));
      if (assignedNames.length > 0) {
        const label = assignedNames.join(', ');
        holder.assigned_to = label;
        holder.ownerName = label;
      }
    }
    return holder;
  });
};

const buildHolderQuery = (filterClause = '') => `
  SELECT h.id,
         h.holder_title,
         h.holder_email,
         h.holder_password,
         h.login_url,
         h.control,
         h.department_id,
         d.name AS department_name,
         ha.user_id AS assigned_user_id,
         u.name AS assigned_user_name,
         u.email AS assigned_user_email
  FROM holder h
  LEFT JOIN departments d ON d.id = h.department_id
  LEFT JOIN holder_assignments ha ON ha.holder_id = h.id
  LEFT JOIN users u ON u.id = ha.user_id
  WHERE h.is_deleted = 0
  ${filterClause}
  ORDER BY h.id DESC, ha.user_id ASC
`;

const getUserHolder = async (userId, departmentId = null) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('user_id', sql.Int, userId);
    let filterClause = 'AND ha.user_id = @user_id';
    if (Number.isInteger(departmentId)) {
      request.input('department_id', sql.Int, departmentId);
      filterClause = `AND (ha.user_id = @user_id OR h.department_id = @department_id)`;
    }
    const result = await request.query(buildHolderQuery(filterClause));
    const holders = mapHolderRows(result.recordset);
    return enrichHoldersWithDepartmentMembers(holders);
  } catch (err) {
    console.log(err);
    return [];
  }
};

const getAllUserHolders = async () => {
  try {
    const pool = await poolPromise;
    const result = await pool.request().query(buildHolderQuery());
    const holders = mapHolderRows(result.recordset);
    return enrichHoldersWithDepartmentMembers(holders);
  } catch (err) {
    console.log(err);
    return [];
  }
};

const getHolderById = async (id, transaction = null) => {
  const request = transaction
    ? new sql.Request(transaction)
    : (await poolPromise).request();
  request.input('holder_id', sql.Int, id);
  const result = await request.query(buildHolderQuery('AND h.id = @holder_id'));
  const holders = mapHolderRows(result.recordset);
  if (holders.length === 0) {
    return null;
  }
  const enriched = await enrichHoldersWithDepartmentMembers(holders);
  return enriched[0] ?? null;
};

const replaceAssignments = async (transaction, holderId, userIds) => {
  const deleteRequest = new sql.Request(transaction);
  deleteRequest.input('holder_id', sql.Int, holderId);
  await deleteRequest.query('DELETE FROM holder_assignments WHERE holder_id = @holder_id');

  if (!Array.isArray(userIds) || userIds.length === 0) {
    return;
  }

  for (const userId of userIds) {
    const insertRequest = new sql.Request(transaction);
    insertRequest.input('holder_id', sql.Int, holderId);
    insertRequest.input('user_id', sql.Int, userId);
    await insertRequest.query(
      `INSERT INTO holder_assignments (holder_id, user_id)
       VALUES (@holder_id, @user_id)`,
    );
  }
};

const fetchUsersGroupedByDepartment = async (departmentIds) => {
  const uniqueIds = Array.from(
    new Set(
      (departmentIds ?? []).filter((value) => Number.isInteger(value)),
    ),
  );
  if (uniqueIds.length === 0) {
    return new Map();
  }
  const pool = await poolPromise;
  const request = pool.request();
  const placeholders = uniqueIds.map((id, index) => {
    const param = `department_id_${index}`;
    request.input(param, sql.Int, id);
    return `@${param}`;
  });
  const result = await request.query(
    `SELECT u.id,
            u.name,
            u.email,
            u.department_id
     FROM users u
     WHERE u.department_id IN (${placeholders.join(', ')})
     ORDER BY u.id ASC`,
  );
  const grouped = new Map();
  result.recordset.forEach((user) => {
    if (!Number.isInteger(user.department_id)) {
      return;
    }
    if (!grouped.has(user.department_id)) {
      grouped.set(user.department_id, []);
    }
    grouped.get(user.department_id).push({
      id: user.id,
      name: user.name,
      email: user.email,
    });
  });
  return grouped;
};

const applyDepartmentMembers = (holder, members) => {
  holder.assigned_users = members;
  holder.assigned_user_ids = members.map((member) => member.id).filter((id) => Number.isInteger(id));
  holder.user_id = members[0]?.id ?? holder.user_id;
  holder.user_name = members[0]?.name ?? holder.user_name;
  const assignedNames = members
    .map((member) => member.name)
    .filter((name) => Boolean(name && name.trim().length > 0));
  if (assignedNames.length > 0) {
    const label = assignedNames.join(', ');
    holder.ownerName = label;
    holder.assigned_to = label;
  }
};

const enrichHoldersWithDepartmentMembers = async (holders) => {
  const departmentIds = holders
    .map((holder) => holder.departmentId)
    .filter((value) => Number.isInteger(value));
  if (departmentIds.length === 0) {
    return holders;
  }
  const groupedMembers = await fetchUsersGroupedByDepartment(departmentIds);
  holders.forEach((holder) => {
    if (!Number.isInteger(holder.departmentId)) {
      return;
    }
    const members = groupedMembers.get(holder.departmentId) ?? [];
    applyDepartmentMembers(holder, members);
  });
  return holders;
};

const addUserHolder = async (holder_user) => {
  const departmentId = Number.isInteger(holder_user.departmentId)
    ? holder_user.departmentId
    : null;
  const assignedUserIds =
    departmentId === null
      ? normalizeUserIds(holder_user.userIds ?? holder_user.userId)
      : [];
  if (departmentId === null && assignedUserIds.length === 0) {
    throw new Error('Atanacak en az bir kullanıcı seçilmelidir.');
  }
  const primaryUserId = assignedUserIds[0] ?? null;

  const pool = await poolPromise;
  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    const request = new sql.Request(transaction);
    request.input('holder_title', sql.NVarChar, holder_user.name);
    request.input('holder_email', sql.NVarChar, holder_user.email);
    request.input('holder_password', sql.NVarChar, holder_user.password);
    request.input('login_url', sql.NVarChar, holder_user.loginUrl ?? null);
    request.input('control', sql.Int, holder_user.control ?? 0);
    request.input('user_id', sql.Int, primaryUserId);
    request.input('department_id', sql.Int, departmentId);
    request.input('is_deleted', sql.Bit, 0);
    const result = await request.query(
      `INSERT INTO holder (holder_title, holder_email, holder_password, login_url, control, user_id, department_id, is_deleted)
       OUTPUT INSERTED.id
       VALUES (@holder_title, @holder_email, @holder_password, @login_url, @control, @user_id, @department_id, @is_deleted)`,
    );
    const holderId = result.recordset[0]?.id;
    if (!holderId) {
      throw new Error('Şifre kaydı oluşturulamadı.');
    }

    await replaceAssignments(transaction, holderId, assignedUserIds);
    await transaction.commit();
    return await getHolderById(holderId);
  } catch (err) {
    await transaction.rollback();
    console.log(err);
    return null;
  }
};

const updateUserHolder = async (id, holder_user, options = {}) => {
  const { isAdmin = false, requestingUserId } = options;
  const departmentId = Number.isInteger(holder_user.departmentId)
    ? holder_user.departmentId
    : null;
  const assignedUserIds =
    departmentId === null
      ? normalizeUserIds(holder_user.userIds ?? holder_user.userId)
      : [];
  if (departmentId === null && assignedUserIds.length === 0) {
    throw new Error('Atanacak en az bir kullanıcı seçilmelidir.');
  }
  const primaryUserId = assignedUserIds[0] ?? null;

  const pool = await poolPromise;
  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    if (!isAdmin) {
      await assertNonAdminCanManageHolder(transaction, id, requestingUserId);
    }

    const request = new sql.Request(transaction);
    request.input('id', sql.Int, id);
    request.input('holder_title', sql.NVarChar, holder_user.name);
    request.input('holder_email', sql.NVarChar, holder_user.email);
    request.input('holder_password', sql.NVarChar, holder_user.password);
    request.input('login_url', sql.NVarChar, holder_user.loginUrl ?? null);
    request.input('control', sql.Int, holder_user.control ?? 0);
    request.input('user_id', sql.Int, primaryUserId);
    request.input('department_id', sql.Int, departmentId);
    const updateResult = await request.query(
      `UPDATE holder
       SET holder_title = @holder_title,
           holder_email = @holder_email,
           holder_password = @holder_password,
           login_url = @login_url,
           control = @control,
           user_id = @user_id,
           department_id = @department_id
       WHERE id = @id
       SELECT @@ROWCOUNT AS affected`,
    );
    const affected = updateResult.recordset[0]?.affected ?? 0;
    if (affected === 0) {
      await transaction.rollback();
      return null;
    }

    await replaceAssignments(transaction, id, assignedUserIds);
    await transaction.commit();
    return await getHolderById(id);
  } catch (err) {
    await transaction.rollback();
    if (err?.code === 'FORBIDDEN') {
      throw err;
    }
    console.log(err);
    return null;
  }
};

const deleteUserHolder = async (id, userId, options = {}) => {
  const { isAdmin = false } = options;
  const pool = await poolPromise;
  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    if (!isAdmin) {
      await assertNonAdminCanManageHolder(transaction, id, userId);
    }

    const deleteHolderRequest = new sql.Request(transaction);
    deleteHolderRequest.input('holder_id', sql.Int, id);
    const deleteResult = await deleteHolderRequest.query(
      `UPDATE holder
       SET is_deleted = 1
       WHERE id = @holder_id AND is_deleted = 0;
       SELECT @@ROWCOUNT AS affected;`,
    );
    const affected = deleteResult.recordset[0]?.affected ?? 0;
    if (affected === 0) {
      await transaction.rollback();
      return false;
    }

    const deleteAssignments = new sql.Request(transaction);
    deleteAssignments.input('holder_id', sql.Int, id);
    await deleteAssignments.query('DELETE FROM holder_assignments WHERE holder_id = @holder_id');

    await transaction.commit();
    return true;
  } catch (err) {
    await transaction.rollback();
    if (err?.code === 'FORBIDDEN') {
      throw err;
    }
    console.log(err);
    return false;
  }
};

module.exports = {
  getUserHolder,
  getAllUserHolders,
  addUserHolder,
  updateUserHolder,
  deleteUserHolder,
};