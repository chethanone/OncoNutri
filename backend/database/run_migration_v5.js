const { pool } = require('../node_server/config/database');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    console.log('🔄 Running migration V5__add_intake_fields.sql...');
    
    const migrationPath = path.join(__dirname, 'migrations', 'V5__add_intake_fields.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    await pool.query(sql);
    
    console.log('✅ Migration completed successfully!');
    
    // Verify the columns were added
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'patient_profiles'
      ORDER BY ordinal_position;
    `);
    
    console.log('\n📋 Patient Profiles Table Columns:');
    result.rows.forEach(row => {
      console.log(`  - ${row.column_name} (${row.data_type})`);
    });
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
    process.exit(0);
  }
}

runMigration();
