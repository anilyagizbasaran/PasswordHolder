const userModel = require('../DataAccess/user_models');

async function getUserByEmail(email) {
  return userModel.getUser(email);
}

async function getAllUsers() {
  return userModel.getAllUsers();
}

async function createUser(user) {
  return userModel.addUser(user);
}

async function updateUserById(id, user) {
  return userModel.updateUser(id, user);
}

async function deleteUserById(id) {
  return userModel.deleteUser(id);
}

module.exports = {
  getUserByEmail,
  getAllUsers,
  createUser,
  updateUserById,
  deleteUserById,
};


