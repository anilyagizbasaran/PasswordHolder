const { sql, poolPromise } = require('./db');

const mapUserRecord = (record) => {
  if (!record) {
    return null;
  }
  return {
    id: record.id,
    name: record.name,
    email: record.email,
    password: record.password,
    departmentId: record.department_id ?? null,
    departmentName: record.department_name ?? null,
    department: record.department_name ?? null,
  };
};

const getUserById = async (id) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('id', sql.Int, id);
    const result = await request.query(
      `SELECT u.id,
              u.name,
              u.email,
              u.password,
              u.department_id,
              d.name AS department_name
       FROM users u
       LEFT JOIN departments d ON d.id = u.department_id
       WHERE u.id = @id`,
    );
    return mapUserRecord(result.recordset[0]);
  } catch (err) {
    console.log(err);
    return null;
  }
};

const getUser = async (email) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('email', sql.VarChar, email);
    const result = await request.query(
      `SELECT u.id,
              u.name,
              u.email,
              u.password,
              u.department_id,
              d.name AS department_name
       FROM users u
       LEFT JOIN departments d ON d.id = u.department_id
       WHERE u.email = @email`,
    );
    return mapUserRecord(result.recordset[0]);
  } catch (err) {
    console.log(err);
    return null;
  }
};

const addUser = async (user) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('name', sql.NVarChar, user.name);
    request.input('email', sql.VarChar, user.email);
    request.input('password', sql.VarChar, user.password);
    request.input('department_id', sql.Int, user.departmentId ?? null);
    const result = await request.query(
      `INSERT INTO users (name, email, password, department_id)
       OUTPUT INSERTED.id
       VALUES (@name, @email, @password, @department_id)`,
    );
    if (!result.recordset[0]) {
      return null;
    }
    return getUserById(result.recordset[0].id);
  } catch (err) {
    console.log(err);
    return null;
  }
};

const updateUser = async (id, user) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('id', sql.Int, id);
    request.input('name', sql.NVarChar, user.name);
    request.input('email', sql.VarChar, user.email);
    request.input('password', sql.VarChar, user.password);
    request.input('department_id', sql.Int, user.departmentId ?? null);
    const result = await request.query(
      `UPDATE users
       SET name = @name,
           email = @email,
           password = @password,
           department_id = @department_id
       OUTPUT INSERTED.id
       WHERE id = @id`,
    );
    if (!result.recordset[0]) {
      return null;
    }
    return getUserById(result.recordset[0].id);
  } catch (err) {
    console.log(err);
    return null;
  }
};

const deleteUser = async (id) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('id', sql.Int, id);
    const result = await request.query('DELETE FROM users WHERE id = @id');
    return result.rowsAffected[0] > 0;
  } catch (err) {
    console.log(err);
    return false;
  }
};

const getAllUsers = async () => {
  try {
    const pool = await poolPromise;
    const result = await pool
      .request()
      .query(
        `SELECT u.id,
                u.name,
                u.email,
                u.password,
                u.department_id,
                d.name AS department_name
         FROM users u
         LEFT JOIN departments d ON d.id = u.department_id
         ORDER BY u.id DESC`,
      );
    return result.recordset.map(mapUserRecord);
  } catch (err) {
    console.log(err);
    return [];
  }
};

module.exports = {
  getUser,
  addUser,
  updateUser,
  deleteUser,
  getAllUsers,
  getUserById,
};