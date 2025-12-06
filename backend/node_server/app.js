const express = require('express');
const cors = require('cors');
const path = require('path');

// Load environment variables from root .env file
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'OncoNutri+ Backend' });
});

// Routes - with error handling
try {
    app.use('/api/auth', require('./routes/auth'));
} catch(e) { console.log('Auth route error:', e.message); }

try {
    app.use('/api/patients', require('./routes/patients'));
} catch(e) { console.log('Patients route error:', e.message); }

try {
    app.use('/api/patient', require('./routes/patientRoutes'));
} catch(e) { console.log('Patient route error:', e.message); }

try {
    app.use('/api/recommendations', require('./routes/recommendations'));
} catch(e) { console.log('Recommendations route error:', e.message); }

try {
    app.use('/api/dashboard', require('./routes/dashboardRoutes'));
} catch(e) { console.log('Dashboard route error:', e.message); }

try {
    app.use('/api/diet', require('./routes/dietRoutes'));
} catch(e) { console.log('Diet route error:', e.message); }

try {
    app.use('/api/videos', require('./routes/videoRoutes'));
} catch(e) { console.log('Video route error:', e.message); }

// Fallback dashboard route
app.get('/api/dashboard/overview', (req, res) => {
    res.json({
        status: 'ok',
        totalPatients: 0,
        activeRecommendations: 0,
        avgCompliance: 0,
        recentActivity: []
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Network access: http://192.168.10.37:${PORT}`);
});
