const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'onconutri',
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
});

async function checkProfile() {
  try {
    const result = await pool.query(
      'SELECT id, user_id, age, cancer_type, stage, dietary_preference, updated_at FROM patient_profiles WHERE user_id = 1'
    );
    
    console.log('\n📊 Current Profile in Database:');
    console.log(JSON.stringify(result.rows[0], null, 2));
    
    await pool.end();
  } catch (err) {
    console.error('❌ Error:', err.message);
    await pool.end();
  }
}

checkProfile();
