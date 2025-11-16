-- Migration: Initial Schema
-- Version: V1__initial_schema.sql
-- Date: 2025-11-16
-- Description: Create initial database schema for OncoNutri+ application

BEGIN;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    language_preference VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Create patient_profiles table
CREATE TABLE patient_profiles (
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

CREATE INDEX idx_patient_profiles_user_id ON patient_profiles(user_id);

-- Create diet_recommendations table
CREATE TABLE diet_recommendations (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patient_profiles(id) ON DELETE CASCADE,
    recommendation JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_diet_recommendations_patient_id ON diet_recommendations(patient_id);
CREATE INDEX idx_diet_recommendations_created_at ON diet_recommendations(created_at);
CREATE INDEX idx_diet_recommendations_jsonb ON diet_recommendations USING GIN (recommendation);

-- Create progress_history table
CREATE TABLE progress_history (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patient_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    adherence_score INTEGER NOT NULL CHECK (adherence_score >= 0 AND adherence_score <= 100),
    notes TEXT,
    UNIQUE(patient_id, date)
);

CREATE INDEX idx_progress_history_patient_id ON progress_history(patient_id);
CREATE INDEX idx_progress_history_date ON progress_history(date);

-- Create analytics_logs table
CREATE TABLE analytics_logs (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patient_profiles(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_logs_patient_id ON analytics_logs(patient_id);
CREATE INDEX idx_analytics_logs_action ON analytics_logs(action);
CREATE INDEX idx_analytics_logs_timestamp ON analytics_logs(timestamp);

-- Create update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patient_profiles_updated_at 
    BEFORE UPDATE ON patient_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMIT;
