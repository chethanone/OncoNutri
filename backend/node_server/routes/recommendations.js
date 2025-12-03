const express = require('express');
const axios = require('axios');
const router = express.Router();

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
router.post('/', async (req, res) => {
    try {
        console.log('📥 Received intake data:', JSON.stringify(req.body, null, 2));
        
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
