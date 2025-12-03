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

// POST /api/diet/plan/save - Save a food item to diet plan
router.post('/plan/save', authenticateToken, dietController.saveFoodToDietPlan);

// GET /api/diet/plan - Get all saved diet plan items
router.get('/plan', authenticateToken, dietController.getSavedDietPlan);

// PATCH /api/diet/plan/:itemId/toggle - Toggle completion status
router.patch('/plan/:itemId/toggle', authenticateToken, dietController.toggleFoodCompletion);

// DELETE /api/diet/plan/:itemId - Remove item from diet plan
router.delete('/plan/:itemId', authenticateToken, dietController.removeFoodFromDietPlan);

// GET /api/diet/plan/progress - Get diet plan progress statistics
router.get('/plan/progress', authenticateToken, dietController.getDietPlanProgress);

module.exports = router;
