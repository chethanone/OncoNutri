const { pool } = require('../config/database');
const { asyncHandler } = require('../utils/asyncHandler');

// Get progress history
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

  // Get progress history
  const result = await pool.query(
    'SELECT * FROM progress_history WHERE patient_id = $1 ORDER BY date DESC',
    [patientId]
  );

  res.json(result.rows);
});

// Add progress entry
exports.addEntry = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const { date, adherence_score, notes } = req.body;

  // Validate input
  if (!date || adherence_score === undefined) {
    return res.status(400).json({ error: 'Date and adherence score are required' });
  }

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const patientId = profileResult.rows[0].id;

  // Add entry
  const result = await pool.query(
    'INSERT INTO progress_history (patient_id, date, adherence_score, notes) VALUES ($1, $2, $3, $4) RETURNING *',
    [patientId, date, adherence_score, notes || '']
  );

  // Log analytics
  await pool.query(
    'INSERT INTO analytics_logs (patient_id, action, timestamp) VALUES ($1, $2, NOW())',
    [patientId, 'progress_entry_added']
  );

  res.status(201).json({
    message: 'Progress entry added successfully',
    entry: result.rows[0],
  });
});

// Update progress entry
exports.updateEntry = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const entryId = req.params.id;
  const { adherence_score, notes } = req.body;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const patientId = profileResult.rows[0].id;

  // Update entry
  const result = await pool.query(
    'UPDATE progress_history SET adherence_score = COALESCE($1, adherence_score), notes = COALESCE($2, notes) WHERE id = $3 AND patient_id = $4 RETURNING *',
    [adherence_score, notes, entryId, patientId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Entry not found' });
  }

  res.json({
    message: 'Progress entry updated successfully',
    entry: result.rows[0],
  });
});

// Delete progress entry
exports.deleteEntry = asyncHandler(async (req, res) => {
  const userId = req.user.userId;
  const entryId = req.params.id;

  // Get patient profile
  const profileResult = await pool.query(
    'SELECT id FROM patient_profiles WHERE user_id = $1',
    [userId]
  );

  if (profileResult.rows.length === 0) {
    return res.status(404).json({ error: 'Patient profile not found' });
  }

  const patientId = profileResult.rows[0].id;

  // Delete entry
  const result = await pool.query(
    'DELETE FROM progress_history WHERE id = $1 AND patient_id = $2 RETURNING *',
    [entryId, patientId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Entry not found' });
  }

  res.json({ message: 'Progress entry deleted successfully' });
});
