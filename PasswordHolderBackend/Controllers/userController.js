const jwt = require('jsonwebtoken');
const userService = require('../Service/userService');
const departmentService = require('../Service/departmentService');

const jwtSecret = process.env.JWT_SECRET || 'development-secret';
const jwtExpiresIn = process.env.JWT_EXPIRES_IN || '9999h';

async function getUser(req, res) {
  try {
    const user = await userService.getUserByEmail(req.params.email);
    if (!user) {
      return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
    }
    const { password, ...safeUser } = user;
    return res.json(safeUser);
  } catch (error) {
    console.error('getUser error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function createUser(req, res) {
  try {
    const payload = { ...req.body };
    let departmentId = null;

    if (payload.departmentId !== undefined && payload.departmentId !== null) {
      const parsedDepartmentId = parseInt(payload.departmentId, 10);
      if (Number.isNaN(parsedDepartmentId)) {
        return res.status(400).json({ message: 'Geçersiz departman kimliği' });
      }
      const department = await departmentService.getDepartmentById(parsedDepartmentId);
      if (!department) {
        return res.status(400).json({ message: 'Departman bulunamadı' });
      }
      departmentId = parsedDepartmentId;
    }

    delete payload.department;
    payload.departmentId = departmentId;

    const created = await userService.createUser(payload);
    if (!created) {
      return res.status(400).json({ message: 'Kullanıcı oluşturulamadı' });
    }
    const { password, ...safeUser } = created;
    return res.status(201).json(safeUser);
  } catch (error) {
    console.error('createUser error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function updateUser(req, res) {
  try {
    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ message: 'Geçersiz kullanıcı kimliği' });
    }

    const payload = { ...req.body };
    if (payload.departmentId !== undefined && payload.departmentId !== null) {
      const parsedDepartmentId = parseInt(payload.departmentId, 10);
      if (Number.isNaN(parsedDepartmentId)) {
        return res.status(400).json({ message: 'Geçersiz departman kimliği' });
      }
      const department = await departmentService.getDepartmentById(parsedDepartmentId);
      if (!department) {
        return res.status(400).json({ message: 'Departman bulunamadı' });
      }
      payload.departmentId = parsedDepartmentId;
    }

    delete payload.department;

    const updated = await userService.updateUserById(id, payload);
    if (!updated) {
      return res.status(404).json({ message: 'Güncellenecek kullanıcı bulunamadı' });
    }
    const { password, ...safeUser } = updated;
    return res.json(safeUser);
  } catch (error) {
    console.error('updateUser error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function deleteUser(req, res) {
  try {
    const deleted = await userService.deleteUserById(parseInt(req.params.id, 10));
    if (!deleted) {
      return res.status(404).json({ message: 'Silinecek kullanıcı bulunamadı' });
    }
    return res.json({ message: 'Kullanıcı silindi' });
  } catch (error) {
    console.error('deleteUser error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function loginUser(req, res) {
  try {
    const user = await userService.getUserByEmail(req.body.email);
    if (!user || user.password !== req.body.password) {
      return res.status(401).json({ message: 'E-posta veya şifre hatalı' });
    }

    const { password, ...safeUser } = user;
    const token = jwt.sign(
      {
        sub: user.id,
        email: user.email,
        name: user.name,
        department: user.department,
        departmentId: user.departmentId,
      },
      jwtSecret,
      { expiresIn: jwtExpiresIn },
    );

    return res.json({ message: 'Giriş başarılı', token, user: safeUser });
  } catch (error) {
    console.error('loginUser error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function logoutUser(req, res) {
  return res.json({ message: 'Tokenınızı silerek çıkış yapabilirsiniz' });
}

async function listUsers(req, res) {
  try {
    if (!req.user || (req.user.department || '').toLowerCase() !== 'admin') {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }

    const users = await userService.getAllUsers();
    const safeUsers = users.map((user) => {
      const { password, ...safe } = user;
      return safe;
    });
    return res.json(safeUsers);
  } catch (error) {
    console.error('listUsers error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

module.exports = {
  getUser,
  createUser,
  updateUser,
  deleteUser,
  loginUser,
  logoutUser,
  listUsers,
};
