-- Migration: Add height and dietary_preference columns to patient_profiles table
-- Version: V4
-- Date: 2025-12-03

-- Add height column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'height'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN height DECIMAL(5,2) CHECK (height > 0);
    END IF;
END $$;

-- Add dietary_preference column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'dietary_preference'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN dietary_preference VARCHAR(50) DEFAULT 'Pure Veg';
    END IF;
END $$;
