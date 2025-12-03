"""
Database-driven food recommendation system - 100% reliable dietary filtering
Uses curated food database with verified dietary categorization
"""

import json
import random
import os
from typing import List, Dict, Optional
import requests

# Load Google API keys for images
from dotenv import load_dotenv
load_dotenv(dotenv_path='../datasets/cancer_data/.env')
GOOGLE_SEARCH_API_KEY = os.getenv('GOOGLE_SEARCH_API_KEY', os.getenv('GOOGLE_API_KEY'))
GOOGLE_SEARCH_ENGINE_ID = os.getenv('GOOGLE_SEARCH_ENGINE_ID', '')
GOOGLE_IMAGE_SEARCH_URL = "https://www.googleapis.com/customsearch/v1"


def load_curated_database():
    """Load curated food database"""
    db_path = os.path.join(os.path.dirname(__file__), '../data/curated_food_database.json')
    with open(db_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_food_image(food_name: str, cuisine: str = "") -> str:
    """Fetch food image from Google Custom Search"""
    # Check for missing or placeholder Search Engine ID
    if not GOOGLE_SEARCH_API_KEY or not GOOGLE_SEARCH_ENGINE_ID or GOOGLE_SEARCH_ENGINE_ID == 'YOUR_SEARCH_ENGINE_ID':
        # Fallback to Unsplash immediately
        return f"https://source.unsplash.com/400x300/?{food_name.replace(' ', '+')},food"
    
    try:
        search_query = f"{food_name} {cuisine} food dish".strip()
        params = {
            'key': GOOGLE_SEARCH_API_KEY,
            'cx': GOOGLE_SEARCH_ENGINE_ID,
            'q': search_query,
            'searchType': 'image',
            'num': 1,
            'imgSize': 'medium',
            'safe': 'active'
        }
        
        response = requests.get(GOOGLE_IMAGE_SEARCH_URL, params=params, timeout=3)
        if response.status_code == 200:
            data = response.json()
            if 'items' in data and len(data['items']) > 0:
                return data['items'][0]['link']
    except Exception as e:
        print(f"  [IMAGE] Failed to fetch for '{food_name}': {e}")
    
    return f"https://via.placeholder.com/400x300.png?text={food_name.replace(' ', '+')}"


def score_food_for_patient(food: Dict, patient_profile: Dict) -> float:
    """
    Score a food item based on how well it matches patient needs
    Higher score = better match
    """
    score = 100.0  # Base score
    
    # Match symptoms
    symptoms = patient_profile.get('symptoms', [])
    food_symptoms = food.get('suitable_for_symptoms', [])
    if symptoms and food_symptoms:
        symptom_match = len(set(symptoms) & set(food_symptoms))
        score += symptom_match * 15  # +15 per matched symptom
    
    # Match treatment stage
    treatment = patient_profile.get('treatment_stage', '').lower()
    food_treatments = [t.lower() for t in food.get('suitable_for_treatments', [])]
    if treatment:
        if any(treatment in ft or ft in treatment for ft in food_treatments):
            score += 20
    
    # Eating ability preferences
    eating_ability = patient_profile.get('eating_ability', 'normal').lower()
    if eating_ability in ['soft', 'difficulty_chewing']:
        # Prefer softer foods
        if any(word in food['preparation'].lower() for word in ['soup', 'blend', 'mash', 'soft', 'porridge', 'khichdi']):
            score += 25
    
    # Nausea severity
    nausea = patient_profile.get('nausea_severity', 0)
    if nausea >= 6:
        # Prefer bland, easy to digest foods
        if any(word in food['name'].lower() for word in ['khichdi', 'soup', 'porridge', 'idli', 'dalia']):
            score += 30
        if any(word in food['preparation'].lower() for word in ['bland', 'easy to digest', 'light', 'mild']):
            score += 20
    
    # Appetite level
    appetite = patient_profile.get('appetite_level', 'normal').lower()
    if appetite == 'low':
        # Prefer smaller, nutrient-dense foods
        if food['meal_type'] == 'snack':
            score += 15
        if food['calories'] < 200:
            score += 10
    elif appetite == 'high':
        # Prefer calorie-dense foods
        if food['calories'] > 300:
            score += 15
    
    # Add randomness to avoid same foods every time
    score += random.uniform(0, 20)
    
    return score


def check_allergen_conflict(food: Dict, allergies: List[str]) -> bool:
    """
    Check if food contains any allergens
    Returns True if there's a conflict (food should be excluded)
    """
    if not allergies or allergies == ['None']:
        return False
    
    food_text = f"{food['name']} {food['preparation']} {food.get('cuisine', '')}".lower()
    
    for allergen in allergies:
        allergen_lower = allergen.lower()
        
        # Dairy allergens
        if allergen_lower in ['dairy', 'lactose']:
            dairy_keywords = ['milk', 'paneer', 'cheese', 'yogurt', 'butter', 'ghee', 'cream', 'curd', 'dahi', 'lassi']
            if any(keyword in food_text for keyword in dairy_keywords):
                return True
        
        # Gluten allergens
        elif allergen_lower == 'gluten':
            gluten_keywords = ['wheat', 'bread', 'paratha', 'roti', 'naan', 'pasta']
            if any(keyword in food_text for keyword in gluten_keywords):
                return True
        
        # Nuts allergens
        elif allergen_lower == 'nuts':
            nut_keywords = ['almond', 'cashew', 'peanut', 'walnut', 'pistachio', 'nut']
            if any(keyword in food_text for keyword in nut_keywords):
                return True
        
        # Soy allergens
        elif allergen_lower == 'soy':
            soy_keywords = ['soy', 'tofu', 'soya']
            if any(keyword in food_text for keyword in soy_keywords):
                return True
        
        # Eggs allergens
        elif allergen_lower == 'eggs':
            egg_keywords = ['egg', 'omelette', 'bhurji']
            if any(keyword in food_text for keyword in egg_keywords):
                return True
        
        # Seafood allergens
        elif allergen_lower == 'seafood':
            seafood_keywords = ['fish', 'prawn', 'shrimp', 'crab', 'lobster', 'salmon', 'tuna', 'seafood']
            if any(keyword in food_text for keyword in seafood_keywords):
                return True
        
        # Meat allergens
        elif allergen_lower in ['red meat', 'red_meat', 'meat']:
            meat_keywords = ['beef', 'pork', 'lamb', 'mutton', 'meat']
            if any(keyword in food_text for keyword in meat_keywords):
                return True
        
        # Poultry allergens
        elif allergen_lower == 'poultry':
            poultry_keywords = ['chicken', 'turkey', 'duck']
            if any(keyword in food_text for keyword in poultry_keywords):
                return True
    
    return False


def get_curated_food_recommendations(patient_profile: Dict) -> List[Dict]:
    """
    Generate food recommendations from curated database
    100% reliable dietary filtering - no AI uncertainty
    
    Args:
        patient_profile: Patient information including dietary preferences
        
    Returns:
        List of 15 recommended foods with images and nutrition info
    """
    
    print(f"\n[CURATED SYSTEM] Starting recommendation generation")
    print(f"[CURATED SYSTEM] Dietary: {patient_profile.get('dietary_preference', 'Any')}")
    print(f"[CURATED SYSTEM] Symptoms: {patient_profile.get('symptoms', [])}")
    print(f"[CURATED SYSTEM] Allergies: {patient_profile.get('allergies', [])}")
    
    # Load database
    database = load_curated_database()
    
    # Normalize dietary preference robustly: strip, lower, remove punctuation,
    # convert spaces/plus/hyphen to underscore and collapse repeated underscores
    import re
    raw_pref = str(patient_profile.get('dietary_preference', 'non_veg') or 'non_veg')
    dietary_pref = raw_pref.strip().lower()
    # replace common separators with underscore
    dietary_pref = re.sub(r'[\s\-\+]+', '_', dietary_pref)
    # remove any characters that are not alphanumeric or underscore
    dietary_pref = re.sub(r'[^a-z0-9_]', '', dietary_pref)
    # collapse multiple underscores
    dietary_pref = re.sub(r'__+', '_', dietary_pref).strip('_')
    
    # Map to database key
    dietary_mapping = {
        'pure_veg': 'pure_veg',
        'vegetarian': 'pure_veg',
        'veg': 'pure_veg',
        'vegan': 'vegan',
        'jain': 'jain',
        'veg_egg': 'veg_egg',
        'veg_eggs': 'veg_egg',
        'eggetarian': 'veg_egg',
        'vegetarian_egg': 'veg_egg',
        'pesc': 'pescatarian',
        'pescatarian': 'pescatarian',
        'pescetarian': 'pescatarian',
        'non_veg': 'non_veg',
        'non_vegetarian': 'non_veg',
        'any': 'non_veg'
    }
    
    db_key = dietary_mapping.get(dietary_pref)

    # If direct mapping failed, attempt a keyword-based fallback from the raw input
    if not db_key:
        low_raw = raw_pref.lower()
        if 'vegan' in low_raw:
            db_key = 'vegan'
        elif 'jain' in low_raw:
            db_key = 'jain'
        elif 'pesc' in low_raw or 'fish' in low_raw:
            db_key = 'pescatarian'
        elif 'egg' in low_raw or 'egge' in low_raw:
            db_key = 'veg_egg'
        elif 'veg' in low_raw and 'non' not in low_raw:
            db_key = 'pure_veg'
        else:
            db_key = 'non_veg'

    print(f"[CURATED SYSTEM] Mapped raw '{raw_pref}' -> normalized '{dietary_pref}' -> database key '{db_key}'")
    
    # Get foods for dietary preference
    # [FIX] Combine lists for mixed diets (e.g., Non-Veg should include Veg items)
    available_foods = []
    
    if db_key == 'pure_veg':
        available_foods = database.get('pure_veg', [])
    elif db_key == 'vegan':
        available_foods = database.get('vegan', [])
    elif db_key == 'jain':
        available_foods = database.get('jain', [])
    elif db_key == 'veg_egg':
        # Veg + Egg includes Pure Veg items + Egg items
        available_foods = database.get('pure_veg', []) + database.get('veg_egg', [])
    elif db_key == 'pescatarian':
        # Pescatarian includes Pure Veg + Egg + Fish items
        available_foods = database.get('pure_veg', []) + database.get('veg_egg', []) + database.get('pescatarian', [])
    elif db_key == 'non_veg':
        # Non-Veg includes EVERYTHING (Veg + Egg + Fish + Meat)
        # We prioritize variety by mixing them
        available_foods = (
            database.get('pure_veg', []) + 
            database.get('veg_egg', []) + 
            database.get('pescatarian', []) + 
            database.get('non_veg', [])
        )
    else:
        # Fallback
        available_foods = database.get(db_key, [])
    
    if not available_foods:
        print(f"[ERROR] No foods found for dietary preference: {db_key}")
        return []
    
    print(f"[CURATED SYSTEM] Found {len(available_foods)} foods in database (Combined List)")
    
    # Filter out allergens
    allergies = patient_profile.get('allergies', [])
    if allergies and allergies != ['None']:
        filtered_foods = []
        for food in available_foods:
            if not check_allergen_conflict(food, allergies):
                filtered_foods.append(food)
            else:
                print(f"  [EXCLUDED]: '{food['name']}' (allergen conflict)")
        available_foods = filtered_foods
        print(f"[CURATED SYSTEM] After allergen filtering: {len(available_foods)} foods remain")
    
    if len(available_foods) == 0:
        print(f"[ERROR] No foods available after allergen filtering!")
        return []
    
    # Score and sort foods
    scored_foods = []
    for food in available_foods:
        score = score_food_for_patient(food, patient_profile)
        scored_foods.append((score, food))
    
    scored_foods.sort(reverse=True, key=lambda x: x[0])
    print(f"[CURATED SYSTEM] Scored and sorted {len(scored_foods)} foods")
    
    # Select foods with meal type distribution
    # Target: 3 Breakfast, 4 Lunch, 4 Dinner, 4 Snacks = 15 total
    meal_targets = {
        'breakfast': 3,
        'lunch': 4,
        'dinner': 4,
        'snack': 4
    }
    
    selected_foods = []
    selected_names = set()  # Avoid duplicates
    
    # First pass: Try to meet targets
    for meal_type, target in meal_targets.items():
        meal_foods = [(score, food) for score, food in scored_foods 
                     if food['meal_type'] == meal_type and food['name'] not in selected_names]
        
        # Take top scoring foods for this meal type
        for i in range(min(target, len(meal_foods))):
            food = meal_foods[i][1]
            selected_foods.append(food)
            selected_names.add(food['name'])
            print(f"  [SELECTED]: {food['name']} ({meal_type}, score: {meal_foods[i][0]:.1f})")
    
    # Second pass: Fill remaining slots with best available
    while len(selected_foods) < 15 and len(selected_foods) < len(available_foods):
        for score, food in scored_foods:
            if food['name'] not in selected_names:
                selected_foods.append(food)
                selected_names.add(food['name'])
                print(f"  [SELECTED] (filler): {food['name']} ({food['meal_type']}, score: {score:.1f})")
                break
        else:
            break  # No more foods available
    
    # Fetch images for selected foods
    final_recommendations = []
    for food in selected_foods:
        # Fetch image
        image_url = get_food_image(food['name'], food.get('cuisine', ''))
        
        # Format response
        recommendation = {
            'name': food['name'],
            'meal_type': food['meal_type'],
            'cuisine': food.get('cuisine', 'Various'),
            'calories': food.get('calories', 0),
            'protein': food.get('protein', 0),
            'carbs': food.get('carbs', 0),
            'fiber': food.get('fiber', 0),
            'preparation': food['preparation'],
            'benefits': food['cancer_benefits'],
            'image_url': image_url
        }
        final_recommendations.append(recommendation)
    
    print(f"\n[CURATED SYSTEM] Generated {len(final_recommendations)} recommendations")
    print(f"[CURATED SYSTEM] Meal distribution: "
          f"Breakfast={sum(1 for f in final_recommendations if f['meal_type']=='breakfast')}, "
          f"Lunch={sum(1 for f in final_recommendations if f['meal_type']=='lunch')}, "
          f"Dinner={sum(1 for f in final_recommendations if f['meal_type']=='dinner')}, "
          f"Snacks={sum(1 for f in final_recommendations if f['meal_type']=='snack')}")
    
    return final_recommendations
