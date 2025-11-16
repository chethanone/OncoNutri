-- Seed Data for OncoNutri+ Database
-- Description: Insert sample data for testing and development

BEGIN;

-- Sample Users
INSERT INTO users (name, email, password_hash, language_preference) VALUES
('John Doe', 'john.doe@example.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'en'),
('Maria Garcia', 'maria.garcia@example.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'es'),
('Priya Sharma', 'priya.sharma@example.com', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'hi');

-- Sample Patient Profiles
INSERT INTO patient_profiles (user_id, age, weight, cancer_type, stage, allergies, other_conditions) VALUES
(1, 45, 70.5, 'Breast Cancer', 'Stage II', 'peanuts', 'none'),
(2, 52, 68.0, 'Colorectal Cancer', 'Stage III', 'shellfish', 'diabetes'),
(3, 38, 55.0, 'Lung Cancer', 'Stage I', '', 'hypertension');

-- Sample Diet Recommendations
INSERT INTO diet_recommendations (patient_id, recommendation) VALUES
(1, '{
    "breakfast": ["Greek yogurt with berries and honey", "Scrambled eggs with whole wheat toast", "Oatmeal with nuts and banana"],
    "lunch": ["Grilled chicken with quinoa and vegetables", "Lentil soup with whole grain bread", "Baked salmon with sweet potato"],
    "dinner": ["Grilled chicken breast with steamed broccoli", "Chicken curry with brown rice", "Mixed vegetable khichdi"],
    "snacks": ["Fresh fruit salad", "Mixed nuts (almonds, walnuts, cashews)", "Hummus with carrot and cucumber sticks", "Greek yogurt with berries"],
    "notes": "Stay hydrated - drink at least 8 glasses of water daily. Include foods rich in antioxidants like berries and leafy greens. Always consult with your oncologist before making major dietary changes."
}'),
(2, '{
    "breakfast": ["White rice porridge with ginger", "Plain yogurt with honey", "Banana and almond butter"],
    "lunch": ["Mixed vegetable curry with rice", "Dal tadka with steamed rice", "Vegetable biryani with raita"],
    "dinner": ["Vegetable soup with whole grain crackers", "Mixed vegetable khichdi", "Stir-fried tofu with vegetables"],
    "snacks": ["Fresh fruit salad", "Apple slices with peanut butter", "Greek yogurt with berries", "Roasted chickpeas"],
    "notes": "Stay hydrated - drink at least 8 glasses of water daily. Include high-fiber foods and probiotics for digestive health. Eat smaller, frequent meals if you experience appetite loss. Always consult with your oncologist before making major dietary changes."
}'),
(3, '{
    "breakfast": ["Greek yogurt with berries and honey", "Protein smoothie with spinach and fruits", "Quinoa porridge with almond milk"],
    "lunch": ["Grilled chicken with quinoa and vegetables", "Tofu stir-fry with brown rice", "Chickpea curry with roti"],
    "dinner": ["Baked fish with asparagus", "Grilled salmon with quinoa", "Lentil dal with roti and salad"],
    "snacks": ["Fresh fruit salad", "Mixed nuts (almonds, walnuts, cashews)", "Trail mix with dried fruits", "Hummus with carrot and cucumber sticks"],
    "notes": "Stay hydrated - drink at least 8 glasses of water daily. Focus on calorie-dense, nutritious foods to maintain healthy weight. Foods rich in vitamin C and E may support lung health. Always consult with your oncologist before making major dietary changes."
}');

-- Sample Progress History
INSERT INTO progress_history (patient_id, date, adherence_score, notes) VALUES
(1, CURRENT_DATE - INTERVAL '7 days', 85, 'Followed diet plan well, felt energetic'),
(1, CURRENT_DATE - INTERVAL '6 days', 90, 'Great day, all meals on track'),
(1, CURRENT_DATE - INTERVAL '5 days', 75, 'Missed some snacks but main meals were good'),
(1, CURRENT_DATE - INTERVAL '4 days', 80, 'Back on track today'),
(1, CURRENT_DATE - INTERVAL '3 days', 95, 'Excellent adherence'),
(2, CURRENT_DATE - INTERVAL '5 days', 70, 'Had some digestive issues'),
(2, CURRENT_DATE - INTERVAL '4 days', 80, 'Feeling better today'),
(2, CURRENT_DATE - INTERVAL '3 days', 85, 'Good progress'),
(3, CURRENT_DATE - INTERVAL '6 days', 90, 'Following plan strictly'),
(3, CURRENT_DATE - INTERVAL '5 days', 88, 'Slight deviation but overall good');

-- Sample Analytics Logs
INSERT INTO analytics_logs (patient_id, action, metadata) VALUES
(1, 'user_login', '{"ip": "192.168.1.1", "device": "mobile"}'),
(1, 'view_recommendation', '{"screen": "diet_recommendation"}'),
(1, 'progress_entry_added', '{"score": 85}'),
(2, 'user_login', '{"ip": "192.168.1.2", "device": "web"}'),
(2, 'profile_updated', '{"fields": ["weight"]}'),
(3, 'user_login', '{"ip": "192.168.1.3", "device": "mobile"}'),
(3, 'view_recommendation', '{"screen": "diet_recommendation"}');

COMMIT;

-- Display summary
SELECT 'Seed data inserted successfully!' as message;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_patients FROM patient_profiles;
SELECT COUNT(*) as total_recommendations FROM diet_recommendations;
SELECT COUNT(*) as total_progress_entries FROM progress_history;
