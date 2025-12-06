const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'onconutri',
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432
});

async function updateProfile() {
  try {
    const result = await pool.query(
      `UPDATE patient_profiles 
       SET cancer_type = $1, 
           stage = $2, 
           age = $3, 
           dietary_preference = $4, 
           updated_at = NOW() 
       WHERE user_id = $5 
       RETURNING *`,
      ['Skin Cancer', 'pre_treatment', 30, 'Pure Veg', 1]
    );
    
    console.log('✅ Updated profile:');
    console.log(JSON.stringify(result.rows[0], null, 2));
  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    pool.end();
  }
}

updateProfile();
