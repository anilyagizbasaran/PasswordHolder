const express = require('express');
const userController = require('../Controllers/userController');
const requireAuth = require('../Middleware/requireAuth');

const router = express.Router();

router.post('/login', userController.loginUser);
router.post('/logout', userController.logoutUser);
router.post('/', userController.createUser);
router.get('/', requireAuth, userController.listUsers);
router.get('/:email', userController.getUser);
router.put('/:id', userController.updateUser);
router.delete('/:id', userController.deleteUser);

module.exports = router;
