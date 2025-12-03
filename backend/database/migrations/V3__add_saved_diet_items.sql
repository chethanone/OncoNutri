-- Add table for saved diet plan items
-- This allows users to save individual food items from recommendations to their personal diet plan

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
    meal_type VARCHAR(50), -- breakfast, lunch, dinner, snack
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(patient_id, fdc_id)
);

-- Indexes for faster queries
CREATE INDEX idx_saved_diet_items_patient_id ON saved_diet_items(patient_id);
CREATE INDEX idx_saved_diet_items_meal_type ON saved_diet_items(meal_type);
CREATE INDEX idx_saved_diet_items_is_completed ON saved_diet_items(is_completed);
CREATE INDEX idx_saved_diet_items_added_at ON saved_diet_items(added_at DESC);

-- GIN index for JSONB queries on nutrients
CREATE INDEX idx_saved_diet_items_nutrients ON saved_diet_items USING GIN (key_nutrients);

-- Add dietary preference to patient profiles if not exists
ALTER TABLE patient_profiles 
ADD COLUMN IF NOT EXISTS dietary_preference VARCHAR(50) DEFAULT 'Pure Veg';

COMMENT ON TABLE saved_diet_items IS 'Stores individual food items saved by users from recommendations to their personal diet plan';
COMMENT ON COLUMN saved_diet_items.is_completed IS 'Tracks if the user has consumed this food item';
COMMENT ON COLUMN saved_diet_items.meal_type IS 'Categorizes the food by meal time: breakfast, lunch, dinner, snack';
