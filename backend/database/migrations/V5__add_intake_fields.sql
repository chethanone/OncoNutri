-- Migration: Add comprehensive intake fields to patient_profiles table
-- Version: V5
-- Date: 2025-12-03

-- Add age_range column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'age_range'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN age_range VARCHAR(20);
    END IF;
END $$;

-- Add symptoms column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'symptoms'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN symptoms TEXT;
    END IF;
END $$;

-- Add water_intake column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'water_intake'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN water_intake VARCHAR(50);
    END IF;
END $$;

-- Add appetite_level column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'appetite_level'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN appetite_level VARCHAR(50);
    END IF;
END $$;

-- Add eating_ability column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'eating_ability'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN eating_ability VARCHAR(50);
    END IF;
END $$;

-- Add activity_level column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'activity_level'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN activity_level VARCHAR(50);
    END IF;
END $$;

-- Add gender column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'patient_profiles' AND column_name = 'gender'
    ) THEN
        ALTER TABLE patient_profiles ADD COLUMN gender VARCHAR(20);
    END IF;
END $$;

-- Make age and weight nullable (since we might only have age_range)
DO $$ 
BEGIN
    ALTER TABLE patient_profiles ALTER COLUMN age DROP NOT NULL;
    ALTER TABLE patient_profiles ALTER COLUMN weight DROP NOT NULL;
    ALTER TABLE patient_profiles ALTER COLUMN cancer_type DROP NOT NULL;
    ALTER TABLE patient_profiles ALTER COLUMN stage DROP NOT NULL;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;
