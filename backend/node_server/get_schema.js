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

async function getSchema() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'patient_profiles' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📊 patient_profiles table columns:');
    result.rows.forEach(row => {
      console.log(`   - ${row.column_name} (${row.data_type})`);
    });
    
    await pool.end();
  } catch (err) {
    console.error('❌ Error:', err.message);
    await pool.end();
  }
}

getSchema();
