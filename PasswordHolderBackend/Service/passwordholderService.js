const userHolderModel = require('../DataAccess/passwordholder_models');

async function getUserHoldersForUser(context) {
  const { userId, departmentId = null } = context;
  return userHolderModel.getUserHolder(userId, departmentId);
}

async function getAllUserHolders() {
  return userHolderModel.getAllUserHolders();
}

async function createUserHolder(holder) {
  return userHolderModel.addUserHolder(holder);
}

async function updateUserHolderById(id, holder, options = {}) {
  return userHolderModel.updateUserHolder(id, holder, options);
}

async function deleteUserHolderById(id, userId, options = {}) {
  return userHolderModel.deleteUserHolder(id, userId, options);
}

module.exports = {
  getUserHoldersForUser,
  getAllUserHolders,
  createUserHolder,
  updateUserHolderById,
  deleteUserHolderById,
};
