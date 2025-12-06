const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../../.env') });

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'onconutri',
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
});

const cancerType = process.argv[2] || 'Breast Cancer';

async function updateCancerType() {
  try {
    const result = await pool.query(
      'UPDATE patient_profiles SET cancer_type = $1 WHERE user_id = 1 RETURNING *',
      [cancerType]
    );
    
    if (result.rows.length > 0) {
      console.log(`✅ Updated cancer type to: ${cancerType}`);
      console.log('Profile:', result.rows[0]);
    } else {
      console.log('❌ No profile found for user_id = 1');
    }
  } catch (error) {
    console.error('❌ Error updating cancer type:', error.message);
  } finally {
    await pool.end();
  }
}

updateCancerType();
