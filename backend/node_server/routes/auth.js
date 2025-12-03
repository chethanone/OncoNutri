const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const authController = require('../controllers/authController');

// Register/Signup
router.post('/register', authController.signup);
router.post('/signup', authController.signup);

// Login
router.post('/login', authController.login);

// Logout
router.post('/logout', authController.logout);

// Refresh token
router.post('/refresh', authController.refreshToken);

// Guest login
router.post('/guest', (req, res) => {
    const guestUser = {
        userId: 0,
        type: 'guest',
        id: 'guest_' + Date.now()
    };
    
    const token = jwt.sign(
        guestUser,
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '7d' }
    );
    
    res.json({ 
        success: true,
        token: token,
        user_id: 0,
        user: guestUser,
        has_completed_intake: false
    });
});

module.exports = router;
