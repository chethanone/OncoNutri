const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// POST /api/auth/signup
router.post('/signup', authController.signup);

// POST /api/auth/login
router.post('/login', authController.login);

// POST /api/auth/logout
router.post('/logout', authController.logout);

// POST /api/auth/refresh-token
router.post('/refresh-token', authController.refreshToken);

module.exports = router;
