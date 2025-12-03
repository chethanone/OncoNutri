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
    const mlResponse = await axios.post(`${ML_SERVICE_URL}/api/recommend`, {
      age: profile.age,
      weight: profile.weight,
      cancer_type: profile.cancer_type,
      treatment_stage: profile.stage,
      allergies: profile.allergies,
      symptoms: profile.other_conditions ? [profile.other_conditions] : [],
      dietary_preference: profile.dietary_preference || 'Pure Veg',
      height: 170,
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
    const mlResponse = await axios.post(`${ML_SERVICE_URL}/api/recommend`, {
      age: profile.age,
      weight: profile.weight,
      cancer_type: profile.cancer_type,
      treatment_stage: profile.stage,
      allergies: profile.allergies,
      symptoms: profile.other_conditions ? [profile.other_conditions] : [],
      dietary_preference: profile.dietary_preference || 'Pure Veg',
      height: 170,
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

// Save a food item to diet plan
exports.saveFoodToDietPlan = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const {
    food_name,
    fdc_id,
    score,
    key_nutrients,
    cuisine,
    texture,
    preparation,
    benefits,
    food_type,
    image_url,
    category,
    meal_type
  } = req.body;

  // Validate required fields
  if (!food_name || !fdc_id) {
    return res.status(400).json({ error: 'food_name and fdc_id are required' });
  }

  // Get or create patient profile
  let profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  let patientId;
  
  // If no profile exists (guest user), create a basic profile
  if (profileResult.rows.length === 0) {
    const createResult = await pool.query(
      `INSERT INTO patient_profiles 
        (user_id, age, weight, cancer_type, stage, dietary_preference, created_at) 
       VALUES ($1, 30, 65, 'Not specified', 'Not specified', 'Pure Veg', CURRENT_TIMESTAMP)
       RETURNING id`,
      [userId]
    );
    patientId = createResult.rows[0].id;
    console.log(`Created patient profile for guest user ${userId}`);
  } else {
    patientId = profileResult.rows[0].id;
  }

  try {
    // Insert or update the food item
    const result = await pool.query(
      `INSERT INTO saved_diet_items 
        (patient_id, food_name, fdc_id, score, key_nutrients, cuisine, texture, 
         preparation, benefits, food_type, image_url, category, meal_type) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       ON CONFLICT (patient_id, fdc_id) 
       DO UPDATE SET 
         food_name = EXCLUDED.food_name,
         score = EXCLUDED.score,
         meal_type = EXCLUDED.meal_type,
         added_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [
        patientId, food_name, fdc_id, score, 
        key_nutrients ? JSON.stringify(key_nutrients) : null,
        cuisine, texture, preparation, benefits, food_type, 
        image_url, category, meal_type || 'snack'
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Food item added to diet plan',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error saving food to diet plan:', error);
    res.status(500).json({ error: 'Failed to save food to diet plan' });
  }
});

// Get all saved diet plan items
exports.getSavedDietPlan = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  // Get or create patient profile
  let profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  let patientId;
  
  // If no profile exists, return empty list
  if (profileResult.rows.length === 0) {
    return res.json({
      success: true,
      count: 0,
      data: []
    });
  }

  patientId = profileResult.rows[0].id;

  // Get all saved items
  const result = await pool.query(
    `SELECT * FROM saved_diet_items 
     WHERE patient_id = $1 
     ORDER BY added_at DESC`,
    [patientId]
  );

  res.json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

// Toggle completion status of a diet item
exports.toggleFoodCompletion = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const { itemId } = req.params;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const patientId = profileResult.rows[0].id;

  // Toggle completion
  const result = await pool.query(
    `UPDATE saved_diet_items 
     SET is_completed = NOT is_completed,
         completed_at = CASE 
           WHEN is_completed = FALSE THEN CURRENT_TIMESTAMP 
           ELSE NULL 
         END
     WHERE id = $1 AND patient_id = $2
     RETURNING *`,
    [itemId, patientId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Diet item not found' });
  }

  res.json({
    success: true,
    message: 'Completion status updated',
    data: result.rows[0]
  });
});

// Remove a food item from diet plan
exports.removeFoodFromDietPlan = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const { itemId } = req.params;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const patientId = profileResult.rows[0].id;

  // Delete the item
  const result = await pool.query(
    `DELETE FROM saved_diet_items 
     WHERE id = $1 AND patient_id = $2
     RETURNING *`,
    [itemId, patientId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Diet item not found' });
  }

  res.json({
    success: true,
    message: 'Food item removed from diet plan',
    data: result.rows[0]
  });
});

// Get diet plan progress statistics
exports.getDietPlanProgress = asyncHandler(async (req, res) => {
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

  // Get statistics
  const statsResult = await pool.query(
    `SELECT 
       COUNT(*) as total_items,
       COUNT(*) FILTER (WHERE is_completed = TRUE) as completed_items,
       COUNT(*) FILTER (WHERE is_completed = FALSE) as pending_items,
       COUNT(*) FILTER (WHERE DATE(completed_at) = CURRENT_DATE) as completed_today,
       ROUND(
         (COUNT(*) FILTER (WHERE is_completed = TRUE)::DECIMAL / 
          NULLIF(COUNT(*), 0) * 100), 2
       ) as completion_percentage
     FROM saved_diet_items 
     WHERE patient_id = $1`,
    [patientId]
  );

  // Get streak (consecutive days with completed items)
  const streakResult = await pool.query(
    `WITH daily_completions AS (
       SELECT DATE(completed_at) as completion_date
       FROM saved_diet_items
       WHERE patient_id = $1 AND is_completed = TRUE
       GROUP BY DATE(completed_at)
       HAVING COUNT(*) > 0
       ORDER BY completion_date DESC
     ),
     streak_calc AS (
       SELECT 
         completion_date,
         completion_date - (ROW_NUMBER() OVER (ORDER BY completion_date))::INTEGER as streak_group
       FROM daily_completions
     )
     SELECT COUNT(*) as streak_days
     FROM streak_calc
     WHERE streak_group = (SELECT MAX(streak_group) FROM streak_calc)`,
    [patientId]
  );

  const stats = statsResult.rows[0];
  const streak = streakResult.rows[0]?.streak_days || 0;

  res.json({
    success: true,
    data: {
      total_items: parseInt(stats.total_items),
      completed_items: parseInt(stats.completed_items),
      pending_items: parseInt(stats.pending_items),
      completed_today: parseInt(stats.completed_today),
      completion_percentage: parseFloat(stats.completion_percentage) || 0,
      streak_days: parseInt(streak)
    }
  });
});
