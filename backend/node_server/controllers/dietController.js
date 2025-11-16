const axios = require('axios');
const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';

// Get diet recommendation
exports.getRecommendation = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT * FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const profile = profileResult.rows[0];

  // Check for existing recent recommendation (within 24 hours)
  const recentRec = await pool.query(
    'SELECT * FROM diet_recommendations WHERE patient_id = $1 AND created_at > NOW() - INTERVAL \'24 hours\' ORDER BY created_at DESC LIMIT 1',
    [profile.id]
  );

  if (recentRec.rows.length > 0) {
    return res.json(recentRec.rows[0]);
  }

  // Call ML service to get recommendation
  try {
    const mlResponse = await axios.post(`${ML_SERVICE_URL}/recommend`, {
      age: profile.age,
      weight: profile.weight,
      cancer_type: profile.cancer_type,
      stage: profile.stage,
      allergies: profile.allergies,
      other_conditions: profile.other_conditions,
    });

    const recommendation = mlResponse.data;

    // Save recommendation to database
    const saveResult = await pool.query(
      'INSERT INTO diet_recommendations (patient_id, recommendation, created_at) VALUES ($1, $2, NOW()) RETURNING *',
      [profile.id, JSON.stringify(recommendation)]
    );

    res.json(saveResult.rows[0]);
  } catch (error) {
    console.error('ML service error:', error);
    return res.status(503).json({ error: 'Unable to generate recommendation at this time' });
  }
});

// Refresh diet recommendation (force new)
exports.refreshRecommendation = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT * FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const profile = profileResult.rows[0];

  // Call ML service
  try {
    const mlResponse = await axios.post(`${ML_SERVICE_URL}/recommend`, {
      age: profile.age,
      weight: profile.weight,
      cancer_type: profile.cancer_type,
      stage: profile.stage,
      allergies: profile.allergies,
      other_conditions: profile.other_conditions,
    });

    const recommendation = mlResponse.data;

    // Save recommendation
    const saveResult = await pool.query(
      'INSERT INTO diet_recommendations (patient_id, recommendation, created_at) VALUES ($1, $2, NOW()) RETURNING *',
      [profile.id, JSON.stringify(recommendation)]
    );

    res.json(saveResult.rows[0]);
  } catch (error) {
    console.error('ML service error:', error);
    return res.status(503).json({ error: 'Unable to generate recommendation at this time' });
  }
});

// Get diet history
exports.getHistory = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const patientId = profileResult.rows[0].id;

  // Get all recommendations
  const result = await pool.query(
    'SELECT * FROM diet_recommendations WHERE patient_id = $1 ORDER BY created_at DESC',
    [patientId]
  );

  res.json(result.rows);
});
