const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

// Signup
exports.signup = asyncHandler(async (req, res) => {
  const { name, email, password, language_preference } = req.body;

  // Validate input
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }

  // Check if user already exists
  const existingUser = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );

  if (existingUser.rows.length > 0) {
    return res.status(409).json({ error: 'User already exists' });
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);

  // Create user
  const result = await pool.query(
    'INSERT INTO users (name, email, password_hash, language_preference, created_at, updated_at) VALUES ($1, $2, $3, $4, NOW(), NOW()) RETURNING id, name, email, language_preference, created_at',
    [name, email, hashedPassword, language_preference || 'en']
  );

  const user = result.rows[0];

  // Generate JWT token
  const token = jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET || 'your-secret-key',
    { expiresIn: '7d' }
  );

  res.status(201).json({
    message: 'User created successfully',
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      language_preference: user.language_preference,
    },
  });
});

// Login
exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  // Check if user exists
  const result = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );

  if (result.rows.length === 0) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const user = result.rows[0];

  // Verify password
  const isPasswordValid = await bcrypt.compare(password, user.password_hash);
  if (!isPasswordValid) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // Generate JWT token
  const token = jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET || 'your-secret-key',
    { expiresIn: '7d' }
  );

  res.json({
    message: 'Login successful',
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      language_preference: user.language_preference,
    },
  });
});

// Logout
exports.logout = asyncHandler(async (req, res) => {
  // In a stateless JWT system, logout is handled client-side
  res.json({ message: 'Logout successful' });
});

// Refresh Token
exports.refreshToken = asyncHandler(async (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // Generate new token
    const newToken = jwt.sign(
      { userId: decoded.userId, email: decoded.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.json({ token: newToken });
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
});
