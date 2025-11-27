const passwordholderService = require('../Service/passwordholderService');
const departmentService = require('../Service/departmentService');

const parseUserIds = (payload) => {
  const source = Array.isArray(payload?.userIds)
    ? payload.userIds
    : payload?.userId !== undefined
        ? [payload.userId]
        : [];
  const parsed = source
    .map((value) => parseInt(value, 10))
    .filter((value) => !Number.isNaN(value));
  return [...new Set(parsed)];
};

const parseDepartmentId = (raw) => {
  if (raw === null || raw === undefined) {
    return null;
  }
  const parsed = parseInt(raw, 10);
  if (Number.isNaN(parsed)) {
    return NaN;
  }
  return parsed;
};

const normalizeLoginUrl = (value) => {
  if (typeof value !== 'string') {
    return null;
  }
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return null;
  }
  return trimmed;
};

async function getUserHolder(req, res) {
  try {
    const department = (req.user.department ?? '').toString().trim().toLowerCase();
    const isAdmin = department == 'admin';
    const currentUserId = parseInt(req.user.id, 10);
    const departmentId = parseDepartmentId(req.user.departmentId);
    const normalizedDepartmentId = Number.isNaN(departmentId) ? null : departmentId;
    const holders = isAdmin
      ? await passwordholderService.getAllUserHolders()
      : await passwordholderService.getUserHoldersForUser({
          userId: currentUserId,
          departmentId: normalizedDepartmentId,
        });
    return res.json(holders);
  } catch (error) {
    console.error('getUserHolder error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function createUserHolder(req, res) {
  try {
    const department = (req.user.department ?? '').toString().trim().toLowerCase();
    const isAdmin = department === 'admin';
    const currentUserId = parseInt(req.user.id, 10);
    if (Number.isNaN(currentUserId)) {
      return res.status(400).json({ message: 'Geçersiz oturum kullanıcısı kimliği' });
    }

    const resolvedDepartmentId = parseDepartmentId(
      req.body.departmentId ?? req.body.department_id,
    );
    if (resolvedDepartmentId !== null && Number.isNaN(resolvedDepartmentId)) {
      return res.status(400).json({ message: 'Geçersiz departman kimliği' });
    }

    let departmentId = null;
    if (resolvedDepartmentId !== null) {
      if (!isAdmin) {
        return res
          .status(403)
          .json({ message: 'Departman bazlı kart oluşturmak için yetkiniz yok' });
      }
      const departmentRecord = await departmentService.getDepartmentById(resolvedDepartmentId);
      if (!departmentRecord) {
        return res.status(400).json({ message: 'Departman bulunamadı' });
      }
      departmentId = resolvedDepartmentId;
    }

    let targetUserIds = departmentId === null ? parseUserIds(req.body) : [];
    if (departmentId === null && (!isAdmin || targetUserIds.length === 0)) {
      targetUserIds = [currentUserId];
    }

    if (departmentId === null && targetUserIds.length === 0) {
      return res.status(400).json({ message: 'Atanacak kullanıcı bulunamadı' });
    }

    console.log('createUserHolder req.body:', req.body);
    console.log('createUserHolder resolved ids -> targetUserIds:', targetUserIds);

    const created = await passwordholderService.createUserHolder({
      name: req.body.name,
      email: req.body.email,
      password: req.body.password,
      loginUrl: normalizeLoginUrl(req.body.loginUrl ?? req.body.login_url),
      userIds: targetUserIds,
      departmentId,
      control: isAdmin ? 1 : 0,
    });
    if (!created) {
      return res.status(400).json({ message: 'Şifre kaydı oluşturulamadı' });
    }
    return res.status(201).json(created);
  } catch (error) {
    console.error('createUserHolder error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function updateUserHolder(req, res) {
  try {
    const department = (req.user.department ?? '').toString().trim().toLowerCase();
    const isAdmin = department === 'admin';
    const currentUserId = parseInt(req.user.id, 10);
    if (Number.isNaN(currentUserId)) {
      return res.status(400).json({ message: 'Geçersiz oturum kullanıcısı kimliği' });
    }

    const resolvedDepartmentId = parseDepartmentId(
      req.body.departmentId ?? req.body.department_id,
    );
    if (resolvedDepartmentId !== null && Number.isNaN(resolvedDepartmentId)) {
      return res.status(400).json({ message: 'Geçersiz departman kimliği' });
    }

    let departmentId = null;
    if (resolvedDepartmentId !== null) {
      if (!isAdmin) {
        return res
          .status(403)
          .json({ message: 'Departman bazlı kart güncellemek için yetkiniz yok' });
      }
      const departmentRecord = await departmentService.getDepartmentById(resolvedDepartmentId);
      if (!departmentRecord) {
        return res.status(400).json({ message: 'Departman bulunamadı' });
      }
      departmentId = resolvedDepartmentId;
    }

    let targetUserIds = departmentId === null ? parseUserIds(req.body) : [];
    if (departmentId === null && (!isAdmin || targetUserIds.length === 0)) {
      targetUserIds = [currentUserId];
    }

    if (departmentId === null && targetUserIds.length === 0) {
      return res.status(400).json({ message: 'Atanacak kullanıcı bulunamadı' });
    }

    console.log('updateUserHolder req.body:', req.body);
    console.log('updateUserHolder resolved ids -> targetUserIds:', targetUserIds);

    const updated = await passwordholderService.updateUserHolderById(
      parseInt(req.params.id, 10),
      {
        name: req.body.name,
        email: req.body.email,
        password: req.body.password,
        loginUrl: normalizeLoginUrl(req.body.loginUrl ?? req.body.login_url),
        userIds: targetUserIds,
        departmentId,
        control: isAdmin ? 1 : 0,
      },
      { isAdmin, requestingUserId: currentUserId },
    );
    if (!updated) {
      return res.status(404).json({ message: 'Güncellenecek şifre kaydı bulunamadı' });
    }
    return res.json(updated);
  } catch (error) {
    if (error?.code === 'FORBIDDEN') {
      return res.status(403).json({ message: error.message });
    }
    console.error('updateUserHolder error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function deleteUserHolder(req, res) {
  try {
    const department = (req.user.department ?? '').toString().trim().toLowerCase();
    const isAdmin = department === 'admin';
    const userId = parseInt(req.user.id, 10);
    if (Number.isNaN(userId)) {
      return res.status(400).json({ message: 'Geçersiz oturum kullanıcısı kimliği' });
    }
    const deleted = await passwordholderService.deleteUserHolderById(
      parseInt(req.params.id, 10),
      userId,
      { isAdmin, requestingUserId: userId },
    );
    if (!deleted) {
      return res.status(404).json({ message: 'Silinecek şifre kaydı bulunamadı' });
    }
    return res.json({ message: 'Şifre kaydı silindi' });
  } catch (error) {
    if (error?.code === 'FORBIDDEN') {
      return res.status(403).json({ message: error.message });
    }
    console.error('deleteUserHolder error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

module.exports = {
  getUserHolder,
  createUserHolder,
  updateUserHolder,
  deleteUserHolder,
};
