const express = require('express');
const router = express.Router();
const dietController = require('../controllers/dietController');
const { authenticateToken } = require('../utils/authMiddleware');

// GET /api/diet/recommendation
router.get('/recommendation', authenticateToken, dietController.getRecommendation);

// POST /api/diet/recommendation/refresh
router.post('/recommendation/refresh', authenticateToken, dietController.refreshRecommendation);

// GET /api/diet/history
router.get('/history', authenticateToken, dietController.getHistory);

module.exports = router;
