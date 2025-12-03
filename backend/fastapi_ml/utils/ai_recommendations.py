"""
Enhanced ML Service with Real-time Gemini API Integration
Combines dataset with AI-powered personalized recommendations
"""

import os
from dotenv import load_dotenv
import requests
import json
from functools import lru_cache
import time

# Load API key
load_dotenv(dotenv_path='../datasets/cancer_data/.env')
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GOOGLE_API_KEY}"

@lru_cache(maxsize=100)
def get_ai_recommendations(cancer_type, treatment_stage, symptoms, dietary_preference, appetite, nausea_level):
    """Get AI-enhanced recommendations using Gemini"""
    
    # Build dietary instruction based on preference
    dietary_instruction = ""
    if dietary_preference == 'Pure Veg':
        dietary_instruction = "\n⚠️ CRITICAL: Recommend ONLY Pure Vegetarian foods. ABSOLUTELY NO eggs, fish, chicken, meat, or any animal products except dairy (milk, yogurt, paneer). Only plant-based + dairy foods."
    elif dietary_preference == 'Vegan':
        dietary_instruction = "\n⚠️ CRITICAL: Recommend ONLY Vegan foods. ABSOLUTELY NO animal products (no dairy, eggs, fish, meat)."
    elif dietary_preference == 'Non-Veg':
        dietary_instruction = "\nInclude mix of vegetarian and non-vegetarian foods (eggs, fish, chicken allowed)."
    elif dietary_preference == 'Pescatarian':
        dietary_instruction = "\nInclude vegetarian foods and fish/seafood. NO chicken, meat, or poultry."
    
    # Create a concise prompt for fast response
    prompt = f"""As a cancer nutrition expert, recommend 5 specific Indian/World foods for:
- Cancer: {cancer_type}, Stage: {treatment_stage}
- Symptoms: {symptoms}
- Diet: {dietary_preference}{dietary_instruction}
- Appetite: {appetite}
- Nausea: {nausea_level}/10

Return ONLY a JSON array with food names and brief reason (max 20 words):
[{{"name": "Dal Tadka", "reason": "Easy to digest, high protein, good for low appetite"}}]

Focus on: protein-rich, easy to digest, anti-inflammatory, available in India.
STRICTLY follow the dietary restrictions above."""

    try:
        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.2,
                "maxOutputTokens": 500,
            }
        }
        
        response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, 
                                json=data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            if 'candidates' in result and len(result['candidates']) > 0:
                text = result['candidates'][0]['content']['parts'][0]['text']
                
                # Extract JSON
                json_start = text.find('[')
                json_end = text.rfind(']') + 1
                if json_start != -1 and json_end > json_start:
                    text = text[json_start:json_end]
                
                ai_recs = json.loads(text)
                return ai_recs if isinstance(ai_recs, list) else []
    except Exception as e:
        print(f"AI recommendation error: {e}")
    
    return []


def enhance_recommendations_with_ai(recommendations, patient_profile):
    """Enhance dataset recommendations with AI insights"""
    
    try:
        # Get AI recommendations (cached for same parameters)
        symptoms_str = ','.join(patient_profile.get('symptoms', [])) if patient_profile.get('symptoms') else 'None'
        dietary_pref = patient_profile.get('dietary_preference', 'Any')
        appetite = patient_profile.get('appetite_score', 7)
        nausea = patient_profile.get('nausea_severity', 0)
        
        ai_recs = get_ai_recommendations(
            patient_profile.get('cancer_type', 'General'),
            patient_profile.get('treatment_stage', 'Active Treatment'),
            symptoms_str,
            dietary_pref,
            'Low' if appetite < 5 else 'Moderate' if appetite < 8 else 'Good',
            nausea
        )
        
        # Boost scores for AI-recommended foods
        if ai_recs:
            ai_food_names = {rec['name'].lower() for rec in ai_recs}
            ai_reasons = {rec['name'].lower(): rec.get('reason', '') for rec in ai_recs}
            
            for rec in recommendations:
                food_name_lower = rec['name'].lower()
                # Check for partial matches
                for ai_name in ai_food_names:
                    if ai_name in food_name_lower or food_name_lower in ai_name:
                        rec['score'] = min(rec['score'] * 1.15, 1.0)  # Boost by 15%
                        rec['ai_recommended'] = True
                        rec['ai_reason'] = ai_reasons.get(ai_name, 'AI recommended')
                        break
        
        return recommendations, len(ai_recs)
    except Exception as e:
        print(f"AI enhancement error: {e}")
        return recommendations, 0


def get_quick_nutrition_advice(patient_profile):
    """Get quick AI-generated nutrition advice"""
    
    try:
        prompt = f"""Give 3 brief nutrition tips for {patient_profile.get('cancer_type', 'cancer')} patient during {patient_profile.get('treatment_stage', 'treatment')}. 
Max 15 words per tip. Return JSON: [{{"tip": "..."}}]"""

        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.3, "maxOutputTokens": 300}
        }
        
        response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'},
                                json=data, timeout=8)
        
        if response.status_code == 200:
            result = response.json()
            text = result['candidates'][0]['content']['parts'][0]['text']
            
            json_start = text.find('[')
            json_end = text.rfind(']') + 1
            if json_start != -1:
                text = text[json_start:json_end]
                tips = json.loads(text)
                return [t['tip'] for t in tips if isinstance(t, dict) and 'tip' in t]
    except:
        pass
    
    return []


def get_medically_accurate_foods(patient_profile):
    """
    Generate medically accurate food recommendations using Gemini AI
    Based on cancer type, treatment stage, and especially EATING ABILITY
    """
    
    cancer_type = patient_profile.get('cancer_type', 'Cancer')
    treatment_stage = patient_profile.get('treatment_stage', 'Active Treatment')
    dietary_pref = patient_profile.get('dietary_preference', 'Any')
    eating_ability = patient_profile.get('eating_ability', 'normal')
    appetite = patient_profile.get('appetite_level', 'normal')
    water_intake = patient_profile.get('water_intake', 'normal')
    nausea = patient_profile.get('nausea_severity', 0)
    
    # Build detailed dietary restriction instruction
    dietary_instruction = ""
    if dietary_pref == 'Pure Veg':
        dietary_instruction = """
⚠️ CRITICAL DIETARY RESTRICTION: Pure Vegetarian Only
- ALLOWED: All vegetables, fruits, grains, pulses, dairy (milk, yogurt, paneer, cheese, ghee, butter), nuts, seeds
- ABSOLUTELY FORBIDDEN: Eggs, Fish, Chicken, Meat, Seafood, ANY animal flesh
- If you suggest ANY non-vegetarian item, it will cause serious dietary violation"""
    elif dietary_pref == 'Vegan':
        dietary_instruction = """
⚠️ CRITICAL DIETARY RESTRICTION: Vegan Only (Strict Plant-Based)
- ALLOWED: Only plant foods - vegetables, fruits, grains, pulses, nuts, seeds, plant milks
- ABSOLUTELY FORBIDDEN: Dairy (milk, yogurt, paneer, ghee, butter, cheese), Eggs, Fish, Chicken, Meat, Seafood, ANY animal products"""
    elif dietary_pref == 'Non-Veg':
        dietary_instruction = """
Dietary Preference: Non-Vegetarian (All foods allowed)
- Can include: Vegetables, fruits, grains, dairy, eggs, fish, chicken, meat"""
    elif dietary_pref == 'Pescatarian':
        dietary_instruction = """
Dietary Preference: Pescatarian
- ALLOWED: Vegetables, fruits, grains, dairy, eggs, fish, seafood
- FORBIDDEN: Chicken, meat, poultry"""
    
    # Build eating ability instruction
    eating_instruction = ""
    if eating_ability == 'liquids_only':
        eating_instruction = """
🚨 CRITICAL: Patient can ONLY consume LIQUIDS and SEMI-LIQUIDS
Medical Context: Severe difficulty swallowing, post-surgery, or extreme nausea

ONLY recommend these texture categories:
1. SMOOTH LIQUIDS: Soups (strained/blended), Smoothies, Juices, Broths, Buttermilk, Lassi
2. SEMI-LIQUIDS: Dal (thin consistency), Rasam, Porridge (very smooth), Kheer (liquid consistency), Custard
3. PUREES: Completely smooth pureed vegetables/fruits, no chunks

ABSOLUTELY FORBIDDEN:
- Solid foods of any kind
- Foods requiring chewing
- Foods with chunks, pieces, or texture
- Rice, bread, roti, idli, dosa (unless pureed)
- Any food that's not drinkable or pourable

Food texture must be: Smooth, Pourable, Drinkable, No chewing required"""
    elif eating_ability == 'soft_only':
        eating_instruction = """
⚠️ IMPORTANT: Patient can ONLY eat VERY SOFT foods
Medical Context: Difficulty swallowing, mouth sores, or digestive issues

ONLY recommend foods that are:
1. VERY SOFT: Melt in mouth, minimal chewing needed
2. MOIST: Not dry or hard
3. Categories: Khichdi, Curd Rice, Soft Idli, Upma, Dosa (soft), Dal, Kheer, Soft Pulaos, Mashed foods, Soft curries

FORBIDDEN:
- Hard or crunchy foods
- Dry foods (dry rotis, crackers)
- Raw vegetables
- Nuts (whole)
- Fried items"""
    elif eating_ability == 'reduced':
        eating_instruction = """
Patient has reduced eating ability - prefer easy-to-digest, smaller portions"""
    else:
        eating_instruction = """
Patient can eat normally - recommend nutritious, balanced foods"""
    
    # Build the comprehensive medical prompt
    prompt = f"""You are a certified oncology nutritionist with expertise in Indian and international cuisine.

PATIENT PROFILE:
- Cancer Type: {cancer_type}
- Treatment Stage: {treatment_stage}
- Eating Ability: {eating_ability}
- Appetite Level: {appetite}
- Nausea Severity: {nausea}/10
- Water Intake: {water_intake}

{dietary_instruction}

{eating_instruction}

TASK: Recommend exactly 30 medically appropriate foods with complete nutritional information.

CRITICAL REQUIREMENTS:
1. STRICTLY follow dietary restrictions above (especially vegetarian/non-veg)
2. STRICTLY match eating ability requirements (liquid/soft texture)
3. Base recommendations on actual medical oncology nutrition guidelines
4. Focus on foods available in India
5. Include protein content, calories, and key benefits
6. Prioritize: High protein, Anti-inflammatory, Easy to digest, Nutrient-dense

OUTPUT FORMAT (JSON Array):
[
  {{
    "name": "Food Name (specific dish)",
    "category": "Protein/Pulses/Vegetable/Fruit/Grain/Dairy/Liquid",
    "texture": "Liquid/Semi-liquid/Soft/Normal",
    "protein_per_100g": 0.0,
    "calories_per_100g": 0,
    "key_nutrients": "Vitamin A, Iron, Fiber",
    "benefits": "Helps with nausea, High protein for healing",
    "preparation_note": "How to prepare for this patient"
  }}
]

Return ONLY the JSON array, no other text.
Ensure ALL 30 foods match the dietary and texture requirements."""

    try:
        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.3,
                "maxOutputTokens": 8000,
                "topP": 0.95,
            }
        }
        
        print(f"🤖 Calling Gemini API for medically accurate recommendations...")
        print(f"   Patient: {cancer_type}, {treatment_stage}, Eating: {eating_ability}, Diet: {dietary_pref}")
        
        response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, 
                                json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if 'candidates' in result and len(result['candidates']) > 0:
                text = result['candidates'][0]['content']['parts'][0]['text']
                
                # Extract JSON array
                json_start = text.find('[')
                json_end = text.rfind(']') + 1
                if json_start != -1 and json_end > json_start:
                    json_text = text[json_start:json_end]
                    ai_foods = json.loads(json_text)
                    
                    if isinstance(ai_foods, list) and len(ai_foods) > 0:
                        print(f"✅ Generated {len(ai_foods)} medically accurate foods")
                        return ai_foods
                    else:
                        print(f"⚠️ AI returned invalid format")
                else:
                    print(f"⚠️ Could not extract JSON from AI response")
            else:
                print(f"⚠️ No candidates in AI response")
        else:
            print(f"❌ API error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ AI food generation error: {e}")
    
    return None
