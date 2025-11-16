-- OncoNutri+ PostgreSQL Database Schema
-- Version: 1.0.0
-- Description: Database schema for OncoNutri+ application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===================================
-- USERS TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    language_preference VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster email lookups
CREATE INDEX idx_users_email ON users(email);

-- ===================================
-- PATIENT PROFILES TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS patient_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    age INTEGER NOT NULL CHECK (age > 0 AND age < 150),
    weight DECIMAL(5,2) NOT NULL CHECK (weight > 0),
    cancer_type VARCHAR(100) NOT NULL,
    stage VARCHAR(50) NOT NULL,
    allergies TEXT,
    other_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster user_id lookups
CREATE INDEX idx_patient_profiles_user_id ON patient_profiles(user_id);

-- ===================================
-- DIET RECOMMENDATIONS TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS diet_recommendations (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patient_profiles(id) ON DELETE CASCADE,
    recommendation JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster patient_id lookups
CREATE INDEX idx_diet_recommendations_patient_id ON diet_recommendations(patient_id);

-- Index for faster date-based queries
CREATE INDEX idx_diet_recommendations_created_at ON diet_recommendations(created_at);

-- GIN index for JSONB queries
CREATE INDEX idx_diet_recommendations_jsonb ON diet_recommendations USING GIN (recommendation);

-- ===================================
-- PROGRESS HISTORY TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS progress_history (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patient_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    adherence_score INTEGER NOT NULL CHECK (adherence_score >= 0 AND adherence_score <= 100),
    notes TEXT,
    UNIQUE(patient_id, date)
);

-- Index for faster patient_id and date lookups
CREATE INDEX idx_progress_history_patient_id ON progress_history(patient_id);
CREATE INDEX idx_progress_history_date ON progress_history(date);

-- ===================================
-- ANALYTICS LOGS TABLE
-- ===================================
CREATE TABLE IF NOT EXISTS analytics_logs (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patient_profiles(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster queries
CREATE INDEX idx_analytics_logs_patient_id ON analytics_logs(patient_id);
CREATE INDEX idx_analytics_logs_action ON analytics_logs(action);
CREATE INDEX idx_analytics_logs_timestamp ON analytics_logs(timestamp);

-- ===================================
-- TRIGGER FUNCTIONS
-- ===================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for users table
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for patient_profiles table
CREATE TRIGGER update_patient_profiles_updated_at 
    BEFORE UPDATE ON patient_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===================================
-- VIEWS
-- ===================================

-- View for patient summary with latest recommendation
CREATE OR REPLACE VIEW patient_summary AS
SELECT 
    u.id as user_id,
    u.name,
    u.email,
    pp.id as patient_id,
    pp.age,
    pp.weight,
    pp.cancer_type,
    pp.stage,
    pp.allergies,
    pp.other_conditions,
    (
        SELECT created_at 
        FROM diet_recommendations dr 
        WHERE dr.patient_id = pp.id 
        ORDER BY created_at DESC 
        LIMIT 1
    ) as last_recommendation_date,
    (
        SELECT COUNT(*) 
        FROM progress_history ph 
        WHERE ph.patient_id = pp.id
    ) as progress_entries_count,
    (
        SELECT AVG(adherence_score) 
        FROM progress_history ph 
        WHERE ph.patient_id = pp.id
    ) as avg_adherence_score
FROM users u
LEFT JOIN patient_profiles pp ON u.id = pp.user_id;

-- ===================================
-- SAMPLE DATA (Optional - for testing)
-- ===================================

-- Uncomment to insert sample data
/*
-- Sample user
INSERT INTO users (name, email, password_hash, language_preference) 
VALUES ('John Doe', 'john.doe@example.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'en');

-- Sample patient profile
INSERT INTO patient_profiles (user_id, age, weight, cancer_type, stage, allergies, other_conditions)
VALUES (1, 45, 70.5, 'Breast Cancer', 'Stage II', 'peanuts', 'none');

-- Sample diet recommendation
INSERT INTO diet_recommendations (patient_id, recommendation)
VALUES (1, '{"breakfast": ["Oatmeal with fruits"], "lunch": ["Grilled chicken"], "dinner": ["Salmon"], "snacks": ["Nuts"], "notes": "Stay hydrated"}');

-- Sample progress entry
INSERT INTO progress_history (patient_id, date, adherence_score, notes)
VALUES (1, CURRENT_DATE, 85, 'Followed diet plan well today');

-- Sample analytics log
INSERT INTO analytics_logs (patient_id, action, metadata)
VALUES (1, 'user_login', '{"ip": "192.168.1.1"}');
*/

-- ===================================
-- GRANT PERMISSIONS (Adjust as needed)
-- ===================================

-- Grant permissions to application user
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO onconutri_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO onconutri_app;
