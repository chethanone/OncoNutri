const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

// Create patient profile
exports.createProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const { age, weight, cancer_type, stage, allergies, other_conditions } = req.body;

  // Validate input
  if (!age || !weight || !cancer_type || !stage) {
    return res.status(400).json({ error: 'Age, weight, cancer type, and stage are required' });
  }

  // Check if profile already exists
  const existing = await pool.query(
    'SELECT * FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (existing.rows.length > 0) {
    return res.status(409).json({ error: 'Profile already exists. Use PUT to update.' });
  }

  // Create profile
  const result = await pool.query(
    'INSERT INTO patient_profiles (user_id, age, weight, cancer_type, stage, allergies, other_conditions, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW()) RETURNING *',
    [userId, age, weight, cancer_type, stage, allergies || '', other_conditions || '']
  );

  res.status(201).json({
    message: 'Profile created successfully',
    profile: result.rows[0],
  });
});

// Get patient profile
exports.getProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  const result = await pool.query(
    'SELECT * FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Profile not found' });
  }

  res.json(result.rows[0]);
});

// Update patient profile
exports.updateProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const { age, weight, cancer_type, stage, allergies, other_conditions } = req.body;

  const result = await pool.query(
    'UPDATE patient_profiles SET age = COALESCE($1, age), weight = COALESCE($2, weight), cancer_type = COALESCE($3, cancer_type), stage = COALESCE($4, stage), allergies = COALESCE($5, allergies), other_conditions = COALESCE($6, other_conditions), updated_at = NOW() WHERE user_id = $7 RETURNING *',
    [age, weight, cancer_type, stage, allergies, other_conditions, userId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Profile not found' });
  }

  res.json({
    message: 'Profile updated successfully',
    profile: result.rows[0],
  });
});
