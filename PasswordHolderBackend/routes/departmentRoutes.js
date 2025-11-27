const express = require('express');
const departmentController = require('../Controllers/departmentController');
const requireAuth = require('../Middleware/requireAuth');

const router = express.Router();

router.use(requireAuth);

router.get('/', departmentController.listDepartments);
router.get('/:id', departmentController.getDepartment);
router.post('/', departmentController.createDepartment);
router.put('/:id', departmentController.updateDepartment);
router.delete('/:id', departmentController.deleteDepartment);

module.exports = router;

