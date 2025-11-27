const express = require('express');
const passwordholderController = require('../Controllers/passwordholderController');
const requireAuth = require('../Middleware/requireAuth');

const router = express.Router();

router.use(requireAuth);

router.get('/', passwordholderController.getUserHolder);
router.post('/', passwordholderController.createUserHolder);
router.put('/:id', passwordholderController.updateUserHolder);
router.delete('/:id', passwordholderController.deleteUserHolder);

module.exports = router;
