const express = require('express');
const axios = require('axios');
const router = express.Router();
const { pool } = require('../config/database');
const { authenticateToken } = require('../utils/authMiddleware');

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';

// Helper function to convert age range to number
function convertAgeRange(ageRange) {
    if (!ageRange) return 40; // default
    
    const ranges = {
        '18-29': 24,
        '30-39': 35,
        '40-49': 45,
        '50-59': 55,
        '60-69': 65,
        '70-79': 75,
        '80+': 85
    };
    
    return ranges[ageRange] || 40;
}

// Get food recommendations
router.post('/', authenticateToken, async (req, res) => {
    try {
        console.log('\n🎯 ========== NEW RECOMMENDATION REQUEST ==========');
        console.log('📥 Received intake data:', JSON.stringify(req.body, null, 2));
        console.log('🔑 User ID:', req.user?.userId);
        
        const userId = req.user?.userId;
        
        // Save intake data to patient profile if user is authenticated
        if (userId) {
            try {
                const {
                    age_range,
                    cancer_type,
                    treatment_stage,
                    dietary_preference,
                    allergies,
                    symptoms,
                    water_intake,
                    appetite_level,
                    eating_ability,
                    activity_level,
                    weight,
                    height,
                    gender
                } = req.body;

                console.log('📋 Extracted values for DB:');
                console.log('   - cancer_type:', cancer_type);
                console.log('   - treatment_stage:', treatment_stage);
                console.log('   - age_range:', age_range);
                console.log('   - dietary_preference:', dietary_preference);

                // Check if profile exists
                const existing = await pool.query(
                    'SELECT * FROM patient_profiles WHERE user_id = $1',
                    [userId]
                );

                const ageValue = age_range ? parseInt(age_range.split('-')[0]) : null;

                if (existing.rows.length > 0) {
                    // Update existing profile - only update columns that exist in DB
                    console.log('🔄 Updating profile with:', {
                        age: ageValue,
                        cancer_type,
                        stage: treatment_stage,
                        dietary_preference,
                        weight
                    });
                    
                    const result = await pool.query(
                        `UPDATE patient_profiles 
                         SET age = $2,
                             cancer_type = $3,
                             stage = $4,
                             dietary_preference = $5,
                             allergies = $6,
                             weight = $7,
                             updated_at = NOW()
                         WHERE user_id = $1
                         RETURNING cancer_type, stage, dietary_preference, age`,
                        [userId, ageValue, cancer_type, treatment_stage,
                         dietary_preference,
                         Array.isArray(allergies) ? allergies.join(', ') : allergies,
                         weight]
                    );
                    console.log('✅ Updated patient profile for user:', userId, 'New values:', result.rows[0]);
                } else {
                    // Create new profile - only use columns that exist in DB
                    await pool.query(
                        `INSERT INTO patient_profiles (
                           user_id, age, cancer_type, stage, dietary_preference,
                           allergies, weight, created_at, updated_at
                         ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())`,
                        [userId, ageValue, cancer_type, treatment_stage, dietary_preference,
                         Array.isArray(allergies) ? allergies.join(', ') : allergies,
                         weight]
                    );
                    console.log('✅ Created patient profile for user:', userId);
                }
            } catch (dbError) {
                console.error('⚠️ Failed to save patient profile:', dbError.message);
                // Continue even if profile save fails
            }
        }
        
        // Transform frontend data to ML service format
        const mlPayload = {
            cancer_type: req.body.cancer_type || 'Breast Cancer',
            treatment_stage: req.body.treatment_stage || 'Active Treatment',
            age: convertAgeRange(req.body.age_range),
            weight: parseFloat(req.body.weight) || 70,
            height: parseFloat(req.body.height) || 170,
            
            // CRITICAL: Pass dietary preference as the main dietary restriction
            dietary_preference: req.body.dietary_preference || 'Any',
            
            // CRITICAL: Pass eating ability
            eating_ability: req.body.eating_ability || 'normal',
            
            // CRITICAL: Pass appetite level
            appetite_level: req.body.appetite_level || 'normal',
            
            // CRITICAL: Pass symptoms as array
            symptoms: req.body.symptoms || [],
            
            // CRITICAL: Pass allergies as array (NOT string!)
            allergies: req.body.allergies || [],
            
            // Pass other dietary restrictions
            dietary_restrictions: req.body.dietary_restrictions || []
        };
        
        console.log('🚀 Sending to ML service:', JSON.stringify(mlPayload, null, 2));
        
        // Forward transformed request to ML service
        const response = await axios.post(`${ML_SERVICE_URL}/api/recommend`, mlPayload);
        res.json(response.data);
    } catch (error) {
        console.error('Error calling ML service:', error.message);
        if (error.response) {
            console.error('ML service error details:', error.response.data);
        }
        res.status(500).json({ 
            error: 'Failed to get recommendations',
            details: error.response?.data || error.message
        });
    }
});

module.exports = router;
