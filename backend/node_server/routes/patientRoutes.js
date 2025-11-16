const express = require('express');
const router = express.Router();
const patientController = require('../controllers/patientController');
const { authenticateToken } = require('../utils/authMiddleware');

// POST /api/patient/profile
router.post('/profile', authenticateToken, patientController.createProfile);

// GET /api/patient/profile
router.get('/profile', authenticateToken, patientController.getProfile);

// PUT /api/patient/profile
router.put('/profile', authenticateToken, patientController.updateProfile);

module.exports = router;
