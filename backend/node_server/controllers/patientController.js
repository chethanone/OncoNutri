const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

// Create or update patient profile (upsert)
exports.createProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const {
    age,
    age_range,
    weight,
    height,
    cancer_type,
    stage,
    treatment_stage,
    allergies,
    other_conditions,
    dietary_preference,
    symptoms,
    water_intake,
    appetite_level,
    eating_ability,
    activity_level,
    gender
  } = req.body;

  // Use age_range if age is not provided
  const ageValue = age || (age_range ? parseInt(age_range.split('-')[0]) : null);
  const stageValue = stage || treatment_stage;
  const cancerTypeValue = cancer_type;

  // Check if profile already exists
  const existing = await pool.query(
    'SELECT * FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  let result;
  if (existing.rows.length > 0) {
    // Update existing profile
    result = await pool.query(
      `UPDATE patient_profiles 
       SET age = COALESCE($2, age),
           age_range = COALESCE($3, age_range),
           weight = COALESCE($4, weight),
           height = COALESCE($5, height),
           cancer_type = COALESCE($6, cancer_type),
           stage = COALESCE($7, stage),
           allergies = COALESCE($8, allergies),
           other_conditions = COALESCE($9, other_conditions),
           dietary_preference = COALESCE($10, dietary_preference),
           symptoms = COALESCE($11, symptoms),
           water_intake = COALESCE($12, water_intake),
           appetite_level = COALESCE($13, appetite_level),
           eating_ability = COALESCE($14, eating_ability),
           activity_level = COALESCE($15, activity_level),
           gender = COALESCE($16, gender),
           updated_at = NOW()
       WHERE user_id = $1
       RETURNING *`,
      [userId, ageValue, age_range, weight, height, cancerTypeValue, stageValue, 
       Array.isArray(allergies) ? allergies.join(', ') : allergies,
       other_conditions,
       dietary_preference,
       Array.isArray(symptoms) ? symptoms.join(', ') : symptoms,
       water_intake, appetite_level, eating_ability, activity_level, gender]
    );
  } else {
    // Create new profile
    result = await pool.query(
      `INSERT INTO patient_profiles (
         user_id, age, age_range, weight, height, cancer_type, stage, 
         allergies, other_conditions, dietary_preference, symptoms,
         water_intake, appetite_level, eating_ability, activity_level, gender,
         created_at, updated_at
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW(), NOW())
       RETURNING *`,
      [userId, ageValue, age_range, weight, height, cancerTypeValue, stageValue,
       Array.isArray(allergies) ? allergies.join(', ') : allergies,
       other_conditions,
       dietary_preference,
       Array.isArray(symptoms) ? symptoms.join(', ') : symptoms,
       water_intake, appetite_level, eating_ability, activity_level, gender]
    );
  }

  res.status(existing.rows.length > 0 ? 200 : 201).json({
    message: existing.rows.length > 0 ? 'Profile updated successfully' : 'Profile created successfully',
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
