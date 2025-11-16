const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

// Get user profile
exports.getProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  const result = await pool.query(
    'SELECT id, name, email, language_preference, created_at, updated_at FROM users WHERE id = $1',
    [userId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'User not found' });
  }

  res.json(result.rows[0]);
});

// Update user profile
exports.updateProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const { name, language_preference } = req.body;

  const result = await pool.query(
    'UPDATE users SET name = COALESCE($1, name), language_preference = COALESCE($2, language_preference), updated_at = NOW() WHERE id = $3 RETURNING id, name, email, language_preference, updated_at',
    [name, language_preference, userId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'User not found' });
  }

  res.json({
    message: 'Profile updated successfully',
    user: result.rows[0],
  });
});

// Delete user account
exports.deleteAccount = asyncHandler(async (req, res) => {
  const userId = req.user.userId;

  // Delete user and all related data (cascade)
  await pool.query('DELETE FROM users WHERE id = $1', [userId]);

  res.json({ message: 'Account deleted successfully' });
});
