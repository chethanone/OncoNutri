const express = require('express');
const router = express.Router();
const progressController = require('../controllers/progressController');
const { authenticateToken } = require('../utils/authMiddleware');

// GET /api/progress/history
router.get('/history', authenticateToken, progressController.getHistory);

// POST /api/progress/add
router.post('/add', authenticateToken, progressController.addEntry);

// PUT /api/progress/:id
router.put('/:id', authenticateToken, progressController.updateEntry);

// DELETE /api/progress/:id
router.delete('/:id', authenticateToken, progressController.deleteEntry);

module.exports = router;
