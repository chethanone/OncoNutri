const { pool } = require('../node_server/config/database');

async function setupDietPlanTable() {
  try {
    console.log('🔧 Setting up saved_diet_items table...');
    
    // Create the table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS saved_diet_items (
        id SERIAL PRIMARY KEY,
        patient_id INTEGER NOT NULL REFERENCES patient_profiles(id) ON DELETE CASCADE,
        food_name VARCHAR(255) NOT NULL,
        fdc_id INTEGER,
        score DECIMAL(3,2),
        key_nutrients JSONB,
        cuisine VARCHAR(100),
        texture VARCHAR(100),
        preparation TEXT,
        benefits TEXT,
        food_type VARCHAR(50),
        image_url TEXT,
        category VARCHAR(100),
        meal_type VARCHAR(50),
        is_completed BOOLEAN DEFAULT FALSE,
        completed_at TIMESTAMP,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(patient_id, fdc_id)
      );
    `);
    
    console.log('✅ Table created/verified');
    
    // Create indexes
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_saved_diet_items_patient_id ON saved_diet_items(patient_id);
    `);
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_saved_diet_items_meal_type ON saved_diet_items(meal_type);
    `);
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_saved_diet_items_is_completed ON saved_diet_items(is_completed);
    `);
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_saved_diet_items_added_at ON saved_diet_items(added_at DESC);
    `);
    
    console.log('✅ Indexes created');
    
    // Check if table has data
    const result = await pool.query('SELECT COUNT(*) FROM saved_diet_items');
    console.log(`📊 Total saved diet items: ${result.rows[0].count}`);
    
    console.log('✅ Setup complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

setupDietPlanTable();
