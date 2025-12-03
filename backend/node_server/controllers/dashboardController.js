const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

// Get dashboard overview data
exports.getDashboard = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  // Handle guest users who don't have a profile yet
  if (userId === 0 || req.user.type === 'guest') {
    return res.json({
      overview: {
        dietPlanStatus: 'Not Started',
        progressPercentage: 0,
        hasDietPlan: false,
        totalProgressEntries: 0,
        lastEntryDate: null,
        totalRecommendedFoods: 0,
        lastRecommendationDate: null,
      },
      recommendations: [],
      tips: [
        {
          icon: 'water_drop',
          title: 'Stay Hydrated',
          description: 'Drink at least 8-10 glasses of water throughout the day to support your treatment',
        },
        {
          icon: 'bedtime',
          title: 'Rest Well',
          description: 'Aim for 7-9 hours of quality sleep each night to help your body recover',
        },
        {
          icon: 'restaurant',
          title: 'Balanced Nutrition',
          description: 'Focus on a variety of colorful fruits and vegetables in every meal',
        },
        {
          icon: 'directions_walk',
          title: 'Stay Active',
          description: 'Light physical activity like walking can boost energy and improve mood',
        },
      ],
      profile: {
        cancerType: 'Complete your profile for personalized recommendations',
        stage: null,
        age: null,
      }
    });
  }

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT * FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const profile = profileResult.rows[0];
  const patientId = profile.id;

  // Get latest diet recommendation status
  const latestDiet = await pool.query(
    'SELECT id, recommendation, created_at FROM diet_recommendations WHERE patient_id = $1 ORDER BY created_at DESC LIMIT 1',
    [patientId]
  );

  const hasDietPlan = latestDiet.rows.length > 0;
  const dietStatus = hasDietPlan ? 'Active' : 'Not Started';
  
  // Extract recommendations if available
  let recommendations = null;
  let totalFoods = 0;
  if (hasDietPlan && latestDiet.rows[0].recommendation) {
    const recData = latestDiet.rows[0].recommendation;
    recommendations = recData.recommendations || recData;
    if (Array.isArray(recommendations)) {
      totalFoods = recommendations.length;
    }
  }

  // Get progress statistics
  const progressStats = await pool.query(
    `SELECT 
      COUNT(*) as total_entries,
      AVG(adherence_score) as avg_score,
      MAX(date) as last_entry_date
    FROM progress_history 
    WHERE patient_id = $1 
    AND date >= CURRENT_DATE - INTERVAL '30 days'`,
    [patientId]
  );

  const avgAdherence = progressStats.rows[0].avg_score 
    ? Math.round(parseFloat(progressStats.rows[0].avg_score)) 
    : 0;

  // Get personalized tips based on cancer type and stage
  const tips = getPersonalizedTips(profile.cancer_type, profile.stage, avgAdherence);

  res.json({
    overview: {
      dietPlanStatus: dietStatus,
      progressPercentage: avgAdherence,
      hasDietPlan: hasDietPlan,
      totalProgressEntries: parseInt(progressStats.rows[0].total_entries),
      lastEntryDate: progressStats.rows[0].last_entry_date,
      totalRecommendedFoods: totalFoods,
      lastRecommendationDate: hasDietPlan ? latestDiet.rows[0].created_at : null,
    },
    recommendations: recommendations ? recommendations.slice(0, 10) : [],
    tips: tips,
    profile: {
      cancerType: profile.cancer_type,
      stage: profile.stage,
      age: profile.age,
    }
  });
});

// Generate personalized tips based on patient data
function getPersonalizedTips(cancerType, stage, adherenceScore) {
  const tips = [];

  // Hydration tip (always relevant)
  tips.push({
    icon: 'water_drop',
    title: 'Stay Hydrated',
    description: 'Drink at least 8-10 glasses of water throughout the day to support your treatment',
  });

  // Rest tip based on stage
  const restHours = stage.includes('III') || stage.includes('IV') ? '8-10' : '7-9';
  tips.push({
    icon: 'bedtime',
    title: 'Rest Well',
    description: `Aim for ${restHours} hours of quality sleep each night to help your body recover`,
  });

  // Cancer-specific nutrition tips
  const cancerLower = cancerType.toLowerCase();
  
  if (cancerLower.includes('breast')) {
    tips.push({
      icon: 'restaurant',
      title: 'Antioxidant Foods',
      description: 'Include berries, leafy greens, and nuts rich in antioxidants in your diet',
    });
  } else if (cancerLower.includes('colon') || cancerLower.includes('colorectal')) {
    tips.push({
      icon: 'local_dining',
      title: 'High-Fiber Diet',
      description: 'Consume plenty of whole grains, vegetables, and legumes for digestive health',
    });
  } else if (cancerLower.includes('lung')) {
    tips.push({
      icon: 'eco',
      title: 'Breathe Fresh Air',
      description: 'Take short walks outdoors and practice deep breathing exercises daily',
    });
  } else if (cancerLower.includes('prostate')) {
    tips.push({
      icon: 'restaurant_menu',
      title: 'Plant-Based Protein',
      description: 'Include more plant proteins like beans, lentils, and tofu in your meals',
    });
  } else {
    tips.push({
      icon: 'restaurant',
      title: 'Balanced Nutrition',
      description: 'Focus on a variety of colorful fruits and vegetables in every meal',
    });
  }

  // Adherence-based tip
  if (adherenceScore < 60) {
    tips.push({
      icon: 'favorite',
      title: 'Small Steps Matter',
      description: 'Every healthy choice counts. Try to improve your diet adherence gradually',
    });
  } else if (adherenceScore >= 80) {
    tips.push({
      icon: 'emoji_events',
      title: 'Great Progress!',
      description: 'Your adherence is excellent. Keep up the outstanding work!',
    });
  }

  // Activity tip
  tips.push({
    icon: 'directions_walk',
    title: 'Stay Active',
    description: 'Light physical activity like walking can boost energy and improve mood',
  });

  // Return up to 4 tips
  return tips.slice(0, 4);
}

