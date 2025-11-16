-- Migration: Add Patient Summary View
-- Version: V2__add_patient_summary_view.sql
-- Date: 2025-11-16
-- Description: Create view for patient summary with aggregated data

BEGIN;

-- Create patient summary view
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

COMMIT;
