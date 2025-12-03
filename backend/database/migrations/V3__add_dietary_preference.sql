-- Migration: Add Dietary Preference Column
-- Version: V3__add_dietary_preference.sql
-- Date: 2025-12-02
-- Description: Add dietary_preference column to patient_profiles for proper food filtering

BEGIN;

-- Add dietary_preference column to patient_profiles
-- Using DO block for conditional column creation
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' 
        AND column_name = 'dietary_preference'
    ) THEN
        ALTER TABLE patient_profiles 
        ADD COLUMN dietary_preference VARCHAR(50) DEFAULT 'Pure Veg';
    END IF;
END $$;

-- Add comment for documentation
COMMENT ON COLUMN patient_profiles.dietary_preference IS 'Patient dietary preference: Pure Veg, Veg+Egg, Pescatarian, Non-Veg, Vegan, Jain';

COMMIT;
