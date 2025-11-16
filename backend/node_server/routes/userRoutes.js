const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../utils/authMiddleware');

// GET /api/user/profile
router.get('/profile', authenticateToken, userController.getProfile);

// PUT /api/user/profile
router.put('/profile', authenticateToken, userController.updateProfile);

// DELETE /api/user/account
router.delete('/account', authenticateToken, userController.deleteAccount);

module.exports = router;
