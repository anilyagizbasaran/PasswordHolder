const departmentModel = require('../DataAccess/department_models');

async function getAllDepartments() {
  return departmentModel.getAllDepartments();
}

async function getDepartmentById(id) {
  return departmentModel.getDepartmentById(id);
}

async function createDepartment(department) {
  return departmentModel.addDepartment(department);
}

async function updateDepartmentById(id, department) {
  return departmentModel.updateDepartment(id, department);
}

async function deleteDepartmentById(id) {
  return departmentModel.deleteDepartment(id);
}

module.exports = {
  getAllDepartments,
  getDepartmentById,
  createDepartment,
  updateDepartmentById,
  deleteDepartmentById,
};

