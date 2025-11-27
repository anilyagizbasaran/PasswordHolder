const departmentService = require('../Service/departmentService');

const isAdminUser = (req) => {
  const department = (req.user?.department ?? '').toString().trim().toLowerCase();
  return department === 'admin';
};

async function listDepartments(req, res) {
  try {
    const departments = await departmentService.getAllDepartments();
    return res.json(departments);
  } catch (error) {
    console.error('listDepartments error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function getDepartment(req, res) {
  try {
    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ message: 'Geçersiz departman kimliği' });
    }

    const department = await departmentService.getDepartmentById(id);
    if (!department) {
      return res.status(404).json({ message: 'Departman bulunamadı' });
    }
    return res.json(department);
  } catch (error) {
    console.error('getDepartment error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function createDepartment(req, res) {
  try {
    if (!isAdminUser(req)) {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }

    const name = (req.body.name ?? '').toString().trim();
    if (!name) {
      return res.status(400).json({ message: 'Departman adı gereklidir' });
    }

    const created = await departmentService.createDepartment({
      name,
      description: req.body.description ?? null,
    });
    if (!created) {
      return res.status(400).json({ message: 'Departman oluşturulamadı' });
    }
    return res.status(201).json(created);
  } catch (error) {
    console.error('createDepartment error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function updateDepartment(req, res) {
  try {
    if (!isAdminUser(req)) {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }

    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ message: 'Geçersiz departman kimliği' });
    }

    const name = (req.body.name ?? '').toString().trim();
    if (!name) {
      return res.status(400).json({ message: 'Departman adı gereklidir' });
    }

    const updated = await departmentService.updateDepartmentById(id, {
      name,
      description: req.body.description ?? null,
    });
    if (!updated) {
      return res.status(404).json({ message: 'Güncellenecek departman bulunamadı' });
    }
    return res.json(updated);
  } catch (error) {
    console.error('updateDepartment error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

async function deleteDepartment(req, res) {
  try {
    if (!isAdminUser(req)) {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }

    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ message: 'Geçersiz departman kimliği' });
    }

    const deleted = await departmentService.deleteDepartmentById(id);
    if (!deleted) {
      return res.status(404).json({ message: 'Silinecek departman bulunamadı' });
    }
    return res.json({ message: 'Departman silindi' });
  } catch (error) {
    console.error('deleteDepartment error:', error);
    return res.status(500).json({ message: 'Sunucu hatası' });
  }
}

module.exports = {
  listDepartments,
  getDepartment,
  createDepartment,
  updateDepartment,
  deleteDepartment,
};

