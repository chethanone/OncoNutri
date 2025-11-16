const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const dietRoutes = require('./routes/dietRoutes');
const patientRoutes = require('./routes/patientRoutes');
const progressRoutes = require('./routes/progressRoutes');

const { errorHandler } = require('./utils/errorHandler');
const { connectDB } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/diet', dietRoutes);
app.use('/api/patient', patientRoutes);
app.use('/api/progress', progressRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'OncoNutri+ API is running' });
});

// Error handling
app.use(errorHandler);

// Connect to database and start server
connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Failed to connect to database:', err);
    process.exit(1);
  });

module.exports = app;
