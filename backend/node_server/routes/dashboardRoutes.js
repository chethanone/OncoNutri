const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { authenticateToken } = require('../utils/authMiddleware');

// Get dashboard overview
router.get('/overview', authenticateToken, dashboardController.getDashboard);

module.exports = router;
