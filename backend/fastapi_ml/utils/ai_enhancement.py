"""
Enhanced curated recommendations with AI-powered cancer-specific benefits
Uses existing database but adds intelligent, cancer-type specific benefits
"""

import json
import os
import requests
from typing import List, Dict
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from root .env file (same as main.py)
env_path = Path(__file__).resolve().parent.parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
# Use gemini-2.0-flash-exp (latest experimental model)
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={GOOGLE_API_KEY}"


def get_cancer_specific_benefits(food_name: str, cancer_type: str, food_details: Dict, treatment_stage: str = None) -> str:
    """
    Get AI-generated cancer-specific benefits for a food
    
    Args:
        food_name: Name of the food
        cancer_type: Specific cancer type (e.g., "Breast Cancer", "Lung Cancer")
        food_details: Dictionary with food info (protein, calories, preparation, etc.)
        treatment_stage: Treatment stage (e.g., "chemotherapy", "radiation", "surgery", etc.)
        
    Returns:
        Cancer-specific benefit description tailored to treatment stage
    """
    
    if not GOOGLE_API_KEY or len(GOOGLE_API_KEY.strip()) < 39:
        # Fallback to generic benefits if no valid API key
        print(f"[AI] WARNING: No valid Google API key found! Using generic benefits.")
        return f"Nutrient-rich food suitable for {cancer_type} patients"
    
    print(f"[AI] Generating benefit for: {food_name} ({cancer_type} - {treatment_stage or 'general'})")
    
    # Add treatment stage context to the prompt
    stage_context = ""
    if treatment_stage:
        stage_map = {
            'chemotherapy': 'undergoing chemotherapy (focus on managing nausea, maintaining energy, and supporting immune function)',
            'radiation': 'undergoing radiation therapy (focus on tissue healing, reducing inflammation, and supporting recovery)',
            'surgery': 'recovering from surgery (focus on wound healing, protein for tissue repair, and easy digestion)',
            'pre_treatment': 'preparing for treatment (focus on building strength, optimizing nutrition, and boosting immunity)',
            'post_treatment': 'in post-treatment recovery (focus on rebuilding health, restoring energy, and preventing recurrence)',
            'maintenance': 'in maintenance phase (focus on long-term health, preventing recurrence, and sustaining wellness)'
        }
        stage_context = f"\nPatient is {stage_map.get(treatment_stage, 'in active treatment')}."
    
    prompt = f"""You are an oncology nutrition expert. Explain in 1-2 SHORT sentences why "{food_name}" is specifically beneficial for {cancer_type} patients.{stage_context}

Food details:
- Protein: {food_details.get('protein', 0)}g
- Calories: {food_details.get('calories', 0)}
- Preparation: {food_details.get('preparation', '')}

CRITICAL RULES:
1. Mention SPECIFIC bioactive compounds (lycopene, omega-3, curcumin, sulforaphane, anthocyanins, beta-carotene, quercetin, etc.)
2. Explain the EXACT mechanism (anti-angiogenic, anti-inflammatory, DNA repair, apoptosis induction, etc.)
3. NEVER use generic phrases like:
   - "supports immune function"
   - "promotes recovery"
   - "helps healing"
   - "provides nutrition"
4. Focus on cancer-type SPECIFIC benefits related to the treatment stage
5. Keep it under 30 words

GOOD Examples:
- "Lycopene inhibits prostate cancer cell growth through anti-angiogenic effects"
- "Curcumin reduces chemotherapy-induced inflammation while omega-3 supports cellular repair"
- "Sulforaphane activates detoxification enzymes that help eliminate carcinogens in lung tissue"

BAD Examples (DO NOT USE):
- "Supports immune system and promotes recovery"
- "Rich in nutrients beneficial for cancer patients"
- "Helps with overall health and healing"

Your response (1-2 sentences, under 30 words):"""

    try:
        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 200,
                "topP": 0.95,
                "topK": 40
            },
            "safetySettings": [
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
            ]
        }
        
        response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, json=data, timeout=15)
        
        print(f"[AI] API Response Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            if 'candidates' in result and len(result['candidates']) > 0:
                candidate = result['candidates'][0]
                
                # Try to extract text from different response structures
                text = None
                
                # Method 1: Standard parts structure
                if 'content' in candidate and 'parts' in candidate['content'] and len(candidate['content']['parts']) > 0:
                    if 'text' in candidate['content']['parts'][0]:
                        text = candidate['content']['parts'][0]['text'].strip()
                
                # Method 2: Direct text in content
                elif 'content' in candidate and 'text' in candidate['content']:
                    text = candidate['content']['text'].strip()
                
                # Method 3: Text directly in candidate
                elif 'text' in candidate:
                    text = candidate['text'].strip()
                
                if text:
                    print(f"[AI] ✓ Generated: {text[:100]}...")
                    return text
                else:
                    print(f"[AI] ✗ No text found in response")
        else:
            print(f"[AI] ✗ API Error: {response.status_code} - {response.text[:200]}")
                    
    except Exception as e:
        print(f"[AI] ✗ Exception: {e}")  # Debug output
        pass  # Silently fall through to fallback
    
    # Fallback
    return f"Rich in protein ({food_details.get('protein', 0)}g) and nutrients beneficial for {cancer_type} recovery"


def enhance_recommendations_with_ai(foods: List[Dict], cancer_type: str, treatment_stage: str = None) -> List[Dict]:
    """
    Enhance food recommendations with AI-generated cancer-specific benefits
    
    Args:
        foods: List of food dictionaries from curated database
        cancer_type: Patient's cancer type
        treatment_stage: Patient's treatment stage for tailored recommendations
        
    Returns:
        Enhanced food list with cancer-specific benefits tailored to treatment stage
    """
    stage_info = f" ({treatment_stage})" if treatment_stage else ""
    print(f"\n[AI ENHANCEMENT] Adding cancer-specific benefits for {cancer_type}{stage_info}...")
    
    enhanced_foods = []
    for idx, food in enumerate(foods[:15]):  # Only enhance first 15 for speed
        food_copy = food.copy()
        
        # Get AI-powered cancer-specific benefit with treatment stage context
        benefit = get_cancer_specific_benefits(
            food_name=food['name'],
            cancer_type=cancer_type,
            food_details={
                'protein': food.get('protein', 0),
                'calories': food.get('calories', 0),
                'preparation': food.get('preparation', ''),
                'cuisine': food.get('cuisine', '')
            },
            treatment_stage=treatment_stage
        )
        
        food_copy['cancer_specific_benefit'] = benefit
        enhanced_foods.append(food_copy)
        
        print(f"  ✓ {idx + 1}/15: {food['name']}")
    
    print(f"[AI ENHANCEMENT] Complete\n")
    return enhanced_foods


# Test function
if __name__ == "__main__":
    test_food = {
        'name': 'Palak Paneer',
        'protein': 12,
        'calories': 250,
        'preparation': 'Spinach cooked with cottage cheese',
        'cuisine': 'Indian'
    }
    
    benefit = get_cancer_specific_benefits('Palak Paneer', 'Breast Cancer', test_food)
    print(f"Benefit: {benefit}")
