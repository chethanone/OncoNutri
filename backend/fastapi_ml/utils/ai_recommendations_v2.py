"""
Enhanced AI-Powered Food Recommendations with Maximum Variety + Google Images
Uses Google Gemini AI to generate fresh, diverse recommendations every time
Fetches real food images from Google Custom Search API
"""

import os
from dotenv import load_dotenv
import requests
import json
import random
from typing import List, Dict, Optional

# Load API keys
load_dotenv(dotenv_path='../datasets/cancer_data/.env')
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
GOOGLE_SEARCH_API_KEY = os.getenv('GOOGLE_SEARCH_API_KEY', GOOGLE_API_KEY)
GOOGLE_SEARCH_ENGINE_ID = os.getenv('GOOGLE_SEARCH_ENGINE_ID', '')
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={GOOGLE_API_KEY}"
GOOGLE_IMAGE_SEARCH_URL = "https://www.googleapis.com/customsearch/v1"


def get_diverse_food_recommendations(patient_profile):
    """
    Generate TRULY DIVERSE food recommendations using Google Gemini AI.
    Creates completely different recommendations for MAXIMUM variety.
    
    Includes:
    - 1000+ global cuisines (Indian, Chinese, Thai, Japanese, Korean, Italian, Mexican, Mediterranean, etc.)
    - All textures: Crunchy, Soft, Liquid, Semi-solid, Chewy, Creamy
    - All food types: Veg, Non-Veg, Vegan, Jain, Eggetarian
    - All meal types: Breakfast, Lunch, Dinner, Snacks, Beverages, Desserts
    - Traditional + Modern fusion foods
    
    Args:
        patient_profile (dict): Patient information
        
    Returns:
        list: 30 diverse food recommendations with nutritional info + images
    """
    
    cancer_type = patient_profile.get('cancer_type', 'Cancer')
    treatment_stage = patient_profile.get('treatment_stage', 'Active Treatment')
    dietary_pref = patient_profile.get('dietary_preference', 'Any')
    eating_ability = patient_profile.get('eating_ability', 'normal')
    appetite = patient_profile.get('appetite_level', 'normal')
    nausea = patient_profile.get('nausea_severity', 0)
    symptoms = patient_profile.get('symptoms', [])
    allergies = patient_profile.get('allergies', [])
    
    # Log what we're processing
    print(f"[AI REQUEST] Dietary: {dietary_pref}, Eating: {eating_ability}, Symptoms: {symptoms}, Allergies: {allergies}")
    
    # Normalize dietary preference for conditional checks
    dietary_pref_normalized = dietary_pref.lower().replace(' ', '_').replace('-', '_')
    
    # Build dietary restrictions
    dietary_instruction = _get_dietary_instructions(dietary_pref)
    
    # Build eating ability instructions with MAXIMUM variety
    eating_instruction = _get_eating_ability_instructions(eating_ability)
    
    # Add STRONG randomization for unique results every time
    variety_seed = random.randint(1, 1000000)
    cuisine_focus = random.choice([
        "Indian Regional (North, South, East, West, Northeast)",
        "Asian (Chinese, Thai, Japanese, Korean, Vietnamese, Malaysian)",
        "Mediterranean (Greek, Italian, Turkish, Lebanese, Moroccan)",
        "Western (American, Mexican, Continental, French)",
        "Fusion & Modern (Indo-Chinese, Thai-Italian, Mexican-Indian)",
        "Traditional & Authentic (Village recipes, Royal cuisines, Street foods)",
        "Health-focused (Organic, Superfoods, Ayurvedic, Macrobiotic)"
    ])
    
    # Build symptoms and allergies instructions
    symptom_instruction = _get_symptom_instructions(symptoms)
    allergy_instruction = _get_allergy_instructions(allergies)
    
    # Build comprehensive prompt with STRONG variety requirements
    prompt = f"""You are an expert oncology nutritionist with access to the latest global cancer nutrition guidelines (AICR, ACS, NCI).
    
    YOUR TASK: Generate EXACTLY 15 scientifically-backed food recommendations for this specific patient.
    
    [SOURCE REQUIREMENT]
    - You MUST act as a search engine aggregator.
    - Base your recommendations on reputable sources like American Cancer Society, Cancer Research UK, and National Cancer Institute.
    - Do NOT use a fixed list. Search your internal knowledge base for the BEST foods for this specific condition.
    - Ensure foods are culturally appropriate but scientifically optimal.

[ALERT] [ALERT] [ALERT] CRITICAL DIETARY COMPLIANCE - READ THIS FIRST [ALERT] [ALERT] [ALERT]

PATIENT'S DIETARY PREFERENCE: **{dietary_pref}**

CRITICAL PRE-CHECKS BEFORE SUGGESTING ANY FOOD:
{'IF Pure Veg/Vegetarian -> Does this food have chicken/turkey/fish/meat/eggs? -> If YES, REJECT IT!' if dietary_pref_normalized in ['pure_veg', 'vegetarian', 'veg'] else ''}
{'IF Vegan -> Does this food have ANY animal product (meat/fish/eggs/dairy/honey)? -> If YES, REJECT IT!' if dietary_pref_normalized == 'vegan' else ''}
{'IF Jain -> Does this food have root vegetables (onion/garlic/potato/ginger/carrot)? -> If YES, REJECT IT!' if dietary_pref_normalized == 'jain' else ''}
{'IF Veg+Egg -> Does this food have chicken/turkey/fish/meat/seafood? -> If YES, REJECT IT!' if dietary_pref_normalized in ['veg_egg', 'veg+egg', 'eggetarian', 'vegetarian_egg'] else ''}
{'IF Pescatarian -> Does this food have chicken/turkey/meat/poultry? -> If YES, REJECT IT!' if dietary_pref_normalized in ['pescatarian', 'pesc', 'pescetarian'] else ''}

IF DIETARY PREFERENCE IS "Non-Veg" OR "Non-Vegetarian":
[REQUIRED] YOU MUST PROVIDE A BALANCED MIX:
- 50% Vegetarian dishes (Lentils, Vegetables, Paneer)
- 50% Non-Vegetarian dishes (Chicken, Fish, Eggs)
- DO NOT provide ONLY meat dishes. A healthy non-veg diet includes vegetables!
- Breakfast MUST include eggs or chicken sausages.

IF DIETARY PREFERENCE IS "Veg + Egg" OR "Eggetarian":
[REQUIRED] YOU MUST PROVIDE A BALANCED MIX:
- 60% Pure Vegetarian dishes
- 40% Egg-based dishes
- DO NOT provide ONLY egg dishes.

IF DIETARY PREFERENCE IS "Pure Veg" OR "Vegetarian":
[FORBIDDEN] YOU ARE FORBIDDEN FROM SUGGESTING:
- Chicken (in ANY form - curry, soup, broth, grilled, fried)
- Turkey (in ANY form)
- Fish (in ANY form - grilled, fried, curry, stock)
- Seafood (shrimp, prawn, crab, lobster)
- Meat (beef, pork, lamb, mutton)
- Eggs (omelette, scrambled, boiled, fried)
- Any chicken/beef/fish broth or stock
- Any animal flesh whatsoever

[ALLOWED] YOU MAY ONLY SUGGEST:
- Pure vegetarian foods: Vegetables, Fruits, Grains, Lentils/Dal, Dairy (paneer, milk, yogurt), Nuts, Seeds
- Example: Palak Paneer, Dal Makhani, Vegetable Curry, Fruit Smoothie, Paneer Tikka

BEFORE SUGGESTING ANY FOOD, ASK YOURSELF:
1. Does this food contain chicken/turkey/fish/meat/eggs/seafood? -> If YES, DO NOT SUGGEST IT
2. Does this food use chicken/meat/fish broth? -> If YES, DO NOT SUGGEST IT
3. Is this 100% plant-based + dairy? -> If NO, DO NOT SUGGEST IT

[ALERT] [ALERT] [ALERT] ABSOLUTE CRITICAL REQUIREMENTS - ZERO TOLERANCE [ALERT] [ALERT] [ALERT]
1. DIETARY RESTRICTION = {dietary_pref} - ANY VIOLATION IS COMPLETELY UNACCEPTABLE
2. If Pure Veg/Vegetarian: [REJECTED] ABSOLUTELY NO chicken, turkey, fish, meat, eggs [REJECTED]
3. If Veg+Egg: [REJECTED] ABSOLUTELY NO chicken, turkey, fish, meat [REJECTED] (eggs OK)
4. If Pescatarian: [REJECTED] ABSOLUTELY NO chicken, turkey, meat, poultry [REJECTED] (fish/eggs OK)
5. If Vegan: [REJECTED] ABSOLUTELY NO animal products - no dairy, eggs, meat, fish [REJECTED]
6. If Jain: [REJECTED] ABSOLUTELY NO root vegetables (onion, garlic, potato, ginger, carrot) [REJECTED]
7. ALLERGIES: [REJECTED] {', '.join(allergies) if allergies and allergies != ['None'] else 'None'} [REJECTED] - LIFE-THREATENING

**PATIENT:**
- Cancer: {cancer_type}, Treatment: {treatment_stage}
- Dietary: {dietary_pref} - STRICTLY FOLLOW THIS
- Eating: {eating_ability} - STRICTLY FOLLOW THIS
- Symptoms: {', '.join(symptoms) if symptoms else 'None'}
- Allergies: {', '.join(allergies) if allergies else 'None'}

{dietary_instruction}

{eating_instruction}

{symptom_instruction}

{allergy_instruction}

**REQUIREMENTS:**
1. [WARNING] FIRST CHECK: Does this food violate dietary restriction? If YES -> REJECT immediately
2. [WARNING] SECOND CHECK: Does this food contain allergens? If YES -> REJECT immediately
3. [WARNING] THIRD CHECK: Does texture match eating ability? If NO -> REJECT immediately
4. [CRITICAL] Ensure foods are SCIENTIFICALLY RECOMMENDED for {cancer_type} patients.
5. Consider symptoms when selecting foods (avoid triggers)
6. Mix Indian (50%) + International (50%) cuisines
7. [TARGET] CRITICAL MEAL DISTRIBUTION - COUNT CAREFULLY - DO NOT VIOLATE:
   
   [LIST] YOU MUST GENERATE EXACTLY THIS:
   
   BREAKFAST (Category: "Breakfast") - EXACTLY 3 ITEMS:
   - Item 1: Breakfast food
   - Item 2: Breakfast food  
   - Item 3: Breakfast food
   
   LUNCH (Category: "Lunch") - EXACTLY 4 ITEMS:
   - Item 4: Lunch food
   - Item 5: Lunch food
   - Item 6: Lunch food
   - Item 7: Lunch food
   
   DINNER (Category: "Dinner") - EXACTLY 4 ITEMS:
   - Item 8: Dinner food
   - Item 9: Dinner food
   - Item 10: Dinner food
   - Item 11: Dinner food
   
   SNACKS/BEVERAGES (Category: "Snack" or "Beverage") - EXACTLY 4 ITEMS:
   - Item 12: Snack/Beverage
   - Item 13: Snack/Beverage
   - Item 14: Snack/Beverage
   - Item 15: Snack/Beverage
   
   TOTAL = 3 + 4 + 4 + 4 = 15 FOODS

7. Set "category" field correctly: "Breakfast", "Lunch", "Dinner", "Snack", or "Beverage"
8. NO repetition - each food must be unique

**JSON OUTPUT (no markdown, no explanations):**
[
  {{
    "name": "Food Name",
    "category": "Breakfast|Lunch|Dinner|Snack|Beverage",
    "cuisine": "Indian|Chinese|Italian|etc",
    "texture": "Liquid|Soft|Regular",
    "protein_per_100g": 10.5,
    "calories_per_100g": 150,
    "key_nutrients": "Vitamin C, Iron",
    "benefits": "Good for {cancer_type}",
    "preparation": "Cooking method",
    "food_type": "{dietary_pref}"
  }}
]

Generate 15 foods NOW with EXACTLY 3 Breakfast + 4 Lunch + 4 Dinner + 4 Snacks:"""

    # Retry logic for robustness with model fallback
    models_to_try = [
        "gemini-1.5-flash",
        "gemini-pro",
        "gemini-1.0-pro"
    ]
    
    if not GOOGLE_API_KEY:
        print("[CRITICAL ERROR] GOOGLE_API_KEY is missing! AI generation will fail.")
        return None

    for model_name in models_to_try:
        current_api_url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={GOOGLE_API_KEY}"
        
        try:
            print(f"[AI REQUEST] Trying model: {model_name}...")
            headers = {"Content-Type": "application/json"}
            
            data = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }],
                "generationConfig": {
                    "temperature": 0.85,
                    "topP": 0.95,
                    "topK": 40,
                    "maxOutputTokens": 4000
                }
            }
            
            # Timeout 30s per attempt
            response = requests.post(current_api_url, headers=headers, json=data, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and result['candidates']:
                    text = result['candidates'][0]['content']['parts'][0]['text']
                    
                    # Extract JSON
                    json_start = text.find('[')
                    json_end = text.rfind(']') + 1
                    if json_start != -1 and json_end > json_start:
                        json_text = text[json_start:json_end]
                        try:
                            foods = json.loads(json_text)
                            
                            # [ALERT] CRITICAL: POST-FILTER to remove any foods that violate dietary restrictions
                            print(f"[AI RESPONSE] Generated {len(foods)} foods. Now filtering for dietary compliance...")
                            foods = _strict_dietary_filter(foods, dietary_pref, allergies)
                            print(f"[FILTERED] {len(foods)} foods remain after dietary filtering")
                            
                            # [ALERT] CRITICAL: If too few foods remain after filtering, try again with stricter prompt
                            if len(foods) < 10:
                                print(f"[WARNING] Only {len(foods)} foods passed filtering. AI is not following instructions properly!")
                                print(f"[ACTION] Returning filtered foods anyway, but recommendations will be limited.")
                            
                            # Fetch images for each food
                            print(f"[SUCCESS] Fetching images for {len(foods)} foods...")
                            foods_with_images = _add_food_images(foods)
                            
                            return foods_with_images
                        except json.JSONDecodeError:
                            print(f"[ERROR] Invalid JSON received from {model_name}")
                            continue # Try next model
                    else:
                        print(f"[ERROR] No JSON found in response from {model_name}")
                        continue # Try next model
                else:
                    print(f"[ERROR] No candidates in response from {model_name}")
                    continue
            else:
                print(f"[ERROR] Model {model_name} failed with status: {response.status_code}")
                print(f"[ERROR] Response: {response.text[:200]}")
                continue # Try next model
                
        except Exception as e:
            print(f"[ERROR] Exception with model {model_name}: {e}")
            continue
            
    return None


def _strict_dietary_filter(foods: List[Dict], dietary_pref: str, allergies: List[str]) -> List[Dict]:
    """
    CRITICAL POST-FILTERING: Remove any foods that violate dietary restrictions
    This is a safety net in case the AI ignores our instructions
    
    Args:
        foods: List of AI-generated foods
        dietary_pref: Dietary preference (pure_veg, veg_egg, pescatarian, etc.)
        allergies: List of allergens to avoid
        
    Returns:
        Filtered list of foods that comply with dietary restrictions
    """
    # Normalize dietary preference
    dietary_normalized = dietary_pref.lower().replace(' ', '_').replace('-', '_')
    
    # Define forbidden keywords for each dietary type (COMPREHENSIVE LIST)
    non_veg_keywords = [
        # Poultry
        'chicken', 'turkey', 'duck', 'goose', 'quail', 'hen', 'cock', 'fowl',
        # Meat
        'meat', 'beef', 'pork', 'lamb', 'mutton', 'veal', 'venison', 'goat',
        # Fish & Seafood
        'fish', 'salmon', 'tuna', 'cod', 'trout', 'mackerel', 'sardine', 'anchovy',
        'shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'mussel', 'clam', 'squid', 'octopus',
        'seafood', 'shellfish',
        # Eggs
        'egg', 'omelette', 'omelet', 'scrambled', 'boiled egg', 'poached', 'fried egg',
        # Broths and stocks (often contain non-veg)
        'chicken broth', 'beef broth', 'bone broth', 'meat broth', 'fish stock', 
        'chicken stock', 'bone stock',
        # Processed/prepared non-veg
        'bacon', 'ham', 'sausage', 'salami', 'pepperoni', 'meatball', 'burger',
        'patty', 'nugget', 'tender', 'wing', 'drumstick', 'breast', 'thigh',
        # Other animal products
        'gelatin', 'lard', 'tallow', 'animal fat'
    ]
    
    pure_veg_forbidden = non_veg_keywords  # Pure veg forbids all non-veg including eggs
    
    # VEG+EGG: No meat/fish but eggs are OK
    veg_egg_forbidden = [
        'chicken', 'turkey', 'duck', 'goose', 'quail', 'hen', 'fowl',
        'meat', 'beef', 'pork', 'lamb', 'mutton', 'veal', 'venison', 'goat',
        'fish', 'salmon', 'tuna', 'cod', 'trout', 'mackerel', 'sardine',
        'shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'mussel', 'squid', 'seafood',
        'chicken broth', 'beef broth', 'bone broth', 'meat broth', 'fish stock',
        'bacon', 'ham', 'sausage', 'salami', 'pepperoni'
    ]
    
    # PESCATARIAN: No meat/poultry but fish/eggs are OK
    pescatarian_forbidden = [
        'chicken', 'turkey', 'duck', 'goose', 'quail', 'hen', 'fowl', 'poultry',
        'meat', 'beef', 'pork', 'lamb', 'mutton', 'veal', 'venison', 'goat',
        'chicken broth', 'beef broth', 'bone broth', 'meat broth',
        'bacon', 'ham', 'sausage', 'salami', 'pepperoni'
    ]
    
    # VEGAN: No animal products AT ALL
    vegan_forbidden = non_veg_keywords + [
        # ALL dairy products
        'milk', 'dairy', 'cheese', 'paneer', 'cottage cheese', 'yogurt', 'yoghurt', 
        'curd', 'dahi', 'lassi', 'buttermilk', 'whey', 'casein',
        'butter', 'ghee', 'cream', 'ice cream', 'condensed milk',
        'mozzarella', 'cheddar', 'parmesan', 'feta', 'ricotta',
        # Animal-derived ingredients
        'honey', 'gelatin', 'lard', 'tallow', 'whey protein'
    ]
    
    # JAIN: No meat + no root vegetables
    jain_forbidden = non_veg_keywords + [
        'onion', 'garlic', 'potato', 'potatoes', 'ginger', 'carrot', 'radish',
        'beetroot', 'beet', 'turnip', 'sweet potato', 'yam', 'tapioca'
    ]
    
    # Select forbidden list based on dietary preference
    if dietary_normalized in ['pure_veg', 'vegetarian', 'veg']:
        forbidden_keywords = pure_veg_forbidden
    elif dietary_normalized in ['veg_egg', 'veg+egg', 'eggetarian', 'vegetarian_egg']:
        forbidden_keywords = veg_egg_forbidden
    elif dietary_normalized in ['pescatarian', 'pesc', 'pescetarian']:
        forbidden_keywords = pescatarian_forbidden
    elif dietary_normalized == 'vegan':
        forbidden_keywords = vegan_forbidden
    elif dietary_normalized == 'jain':
        forbidden_keywords = jain_forbidden
    else:  # Non-veg - no filtering needed
        forbidden_keywords = []
    
    # Filter out foods with forbidden keywords
    filtered_foods = []
    for food in foods:
        food_name = food.get('name', '').lower()
        food_prep = food.get('preparation', '').lower()
        food_benefits = food.get('benefits', '').lower()
        food_cuisine = food.get('cuisine', '').lower()
        food_full_text = f"{food_name} {food_prep} {food_benefits} {food_cuisine}"
        
        # Check EACH WORD in food name individually
        food_name_words = food_name.split()
        
        # Check if food contains any forbidden keywords
        is_forbidden = False
        matched_keyword = None
        
        for keyword in forbidden_keywords:
            # Check full text
            if keyword in food_full_text:
                matched_keyword = keyword
                is_forbidden = True
                break
            # Also check individual words in name
            for word in food_name_words:
                if keyword in word or word in keyword:
                    matched_keyword = keyword
                    is_forbidden = True
                    break
            if is_forbidden:
                break
        
        if is_forbidden:
            print(f"  [REJECTED]: '{food.get('name')}' contains forbidden keyword '{matched_keyword}' for {dietary_pref}")
            continue
        
        # Check for allergens with expanded keywords
        if allergies and allergies != ['None']:
            # Allergen expansion map
            allergen_expansions = {
                'dairy': ['milk', 'dairy', 'cream', 'butter', 'ghee', 'cheese', 'paneer', 'curd', 'yogurt', 'dahi', 'khoya', 'mozzarella', 'cheddar', 'ricotta', 'lassi', 'raita'],
                'milk': ['milk', 'dairy', 'cream', 'butter', 'ghee'],
                'cheese': ['cheese', 'paneer', 'cheddar', 'mozzarella', 'ricotta'],
                'yogurt': ['yogurt', 'curd', 'dahi', 'lassi', 'raita'],
                'eggs': ['egg', 'omelette', 'scrambled', 'boiled egg', 'fried egg'],
                'egg': ['egg', 'omelette', 'scrambled', 'boiled egg', 'fried egg'],
                'nuts': ['nut', 'almond', 'walnut', 'cashew', 'peanut', 'hazelnut', 'pistachio', 'pecan'],
                'soy': ['soy', 'tofu', 'tempeh', 'edamame', 'soybean'],
                'gluten': ['wheat', 'bread', 'pasta', 'noodle', 'roti', 'chapati', 'barley', 'rye', 'semolina', 'maida'],
                'wheat': ['wheat', 'bread', 'pasta', 'noodle', 'roti', 'chapati'],
                'shellfish': ['shellfish', 'shrimp', 'prawn', 'crab', 'lobster', 'clam', 'mussel', 'oyster'],
                'seafood': ['fish', 'salmon', 'tuna', 'mackerel', 'shrimp', 'prawn', 'crab', 'lobster', 'shellfish'],
                'fish': ['fish', 'salmon', 'tuna', 'mackerel', 'cod', 'tilapia'],
                'red meat': ['beef', 'pork', 'lamb', 'mutton', 'goat'],
                'poultry': ['chicken', 'turkey', 'duck']
            }
            
            for allergen in allergies:
                allergen_lower = allergen.lower().strip()
                
                # Get expanded allergen terms
                allergen_terms = allergen_expansions.get(allergen_lower, [allergen_lower])
                
                # Check if any allergen term is in the food text
                for term in allergen_terms:
                    if term in food_full_text:
                        print(f"  [REJECTED]: '{food.get('name')}' contains allergen '{allergen}' (matched: '{term}')")
                        is_forbidden = True
                        break
                
                if is_forbidden:
                    break
        
        if not is_forbidden:
            filtered_foods.append(food)
            print(f"  [APPROVED]: '{food.get('name')}'")
    
    return filtered_foods


def _add_food_images(foods: List[Dict]) -> List[Dict]:
    """
    Fetch real food images from Google Custom Search API
    
    Args:
        foods: List of food dictionaries
        
    Returns:
        List of foods with 'image_url' field added
    """
    # Check if Search Engine ID is configured
    if not GOOGLE_SEARCH_ENGINE_ID or GOOGLE_SEARCH_ENGINE_ID == 'YOUR_SEARCH_ENGINE_ID':
        print("[INFO] Google Search Engine ID not configured. Using Unsplash for food images.")
        # Use Unsplash images for all foods
        for food in foods:
            food_name = food.get('name', 'food').replace(' ', '+').replace('(', '').replace(')', '')
            # Unsplash with specific food keywords
            food['image_url'] = f"https://source.unsplash.com/400x300/?{food_name},food,dish,meal"
            print(f"  Added image for: {food.get('name')} -> {food['image_url']}")
        return foods
    
    print(f"[INFO] Fetching images for {len(foods)} foods using Google Custom Search...")
    
    for food in foods:
        try:
            food_name = food.get('name', '')
            cuisine = food.get('cuisine', '')
            
            # Search query: "food_name cuisine food dish"
            search_query = f"{food_name} {cuisine} food dish"
            
            params = {
                'key': GOOGLE_SEARCH_API_KEY,
                'cx': GOOGLE_SEARCH_ENGINE_ID,
                'q': search_query,
                'searchType': 'image',
                'num': 1,
                'imgSize': 'medium',
                'safe': 'active'
            }
            
            response = requests.get(GOOGLE_IMAGE_SEARCH_URL, params=params, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                if 'items' in data and len(data['items']) > 0:
                    food['image_url'] = data['items'][0]['link']
                else:
                    # Fallback to Unsplash
                    food['image_url'] = f"https://source.unsplash.com/400x300/?{food_name.replace(' ', '+')},food"
            else:
                # Fallback to Unsplash
                food['image_url'] = f"https://source.unsplash.com/400x300/?{food_name.replace(' ', '+')},food"
                
        except Exception as e:
            print(f"[WARNING] Failed to fetch image for {food.get('name', 'unknown')}: {e}")
            # Fallback to Unsplash
            food_name = food.get('name', 'food').replace(' ', '+')
            food['image_url'] = f"https://source.unsplash.com/400x300/?{food_name},food"
    
    return foods


def _get_dietary_instructions(dietary_pref):
    """Get detailed dietary restriction instructions"""
    
    # Normalize the dietary preference (handle both snake_case and Title Case)
    dietary_pref_normalized = dietary_pref.lower().replace(' ', '_').replace('-', '_')
    
    if dietary_pref_normalized in ['pure_veg', 'vegetarian', 'veg']:
        return """
**[ALERT] CRITICAL: 100% PURE VEGETARIAN ONLY - ABSOLUTE ZERO TOLERANCE [ALERT]**

YOU MUST ONLY SUGGEST FOODS FROM THIS LIST:
[ALLOWED] ALLOWED ONLY:
- Vegetables: All leafy greens, tomatoes, cucumbers, bell peppers, broccoli, cauliflower, etc.
- Fruits: All fruits - apples, bananas, oranges, berries, mangoes, etc.
- Grains: Rice, wheat, oats, quinoa, millet, barley, bread, pasta
- Pulses & Legumes: Dal (lentils), chickpeas, kidney beans, black beans, tofu
- Dairy: Milk, yogurt, paneer, cheese, butter, ghee, cream
- Nuts & Seeds: Almonds, cashews, walnuts, peanuts, sunflower seeds, chia seeds
- Spices & Herbs: All spices and herbs

[REJECTED] [REJECTED] [REJECTED] ABSOLUTELY FORBIDDEN - DO NOT EVEN CONSIDER: [REJECTED] [REJECTED] [REJECTED]
- NO CHICKEN (chicken curry, grilled chicken, chicken soup, chicken broth, chicken stock)
- NO TURKEY (turkey breast, roasted turkey, ground turkey)
- NO FISH (salmon, tuna, fish fillet, fish curry, fish stock)
- NO SEAFOOD (shrimp, prawn, crab, lobster, shellfish)
- NO MEAT (beef, pork, lamb, mutton, goat, veal)
- NO EGGS (omelette, scrambled, boiled, fried)
- NO BONE BROTH or MEAT STOCK
- NO animal flesh of ANY KIND

IF A FOOD CONTAINS ANY OF THE FORBIDDEN ITEMS ABOVE, YOU MUST NOT SUGGEST IT!

EXAMPLES OF PURE VEG FOODS:
[ALLOWED] Palak Paneer (spinach with cottage cheese)
[ALLOWED] Dal Tadka (lentil curry)
[ALLOWED] Vegetable Biryani
[ALLOWED] Paneer Tikka
[ALLOWED] Mixed Vegetable Curry
[ALLOWED] Fruit Smoothie
[ALLOWED] Vegetable Soup (NO chicken/meat broth!)
[ALLOWED] Rice and Dal
[ALLOWED] Oatmeal with fruits
"""
    elif dietary_pref_normalized == 'vegan':
        return """
**[ALERT] CRITICAL: 100% VEGAN ONLY - ABSOLUTELY NO ANIMAL PRODUCTS [ALERT]**

YOU MUST ONLY SUGGEST FOODS FROM THIS LIST:
[ALLOWED] ALLOWED ONLY:
- Vegetables: All vegetables (tomatoes, spinach, broccoli, etc.)
- Fruits: All fruits
- Grains: Rice, wheat, oats, quinoa, bread, pasta
- Pulses & Legumes: Dal, lentils, chickpeas, beans, tofu, tempeh
- Nuts & Seeds: Almonds, cashews, walnuts, chia seeds, flax seeds
- Plant Milks: Soy milk, almond milk, oat milk, coconut milk
- Plant-based oils: Olive oil, coconut oil, sesame oil

[REJECTED] [REJECTED] [REJECTED] ABSOLUTELY FORBIDDEN - DO NOT EVEN CONSIDER: [REJECTED] [REJECTED] [REJECTED]
- NO DAIRY: milk, yogurt, paneer, cheese, butter, ghee, cream, curd, lassi, ice cream
- NO EGGS: omelette, scrambled eggs, boiled eggs, egg curry
- NO MEAT: chicken, turkey, beef, pork, lamb, mutton
- NO FISH/SEAFOOD: fish, salmon, shrimp, prawn
- NO HONEY or any animal-derived ingredient

EXAMPLES OF VEGAN FOODS:
[ALLOWED] Dal Tadka (lentils with spices)
[ALLOWED] Vegetable Curry (NO paneer, NO ghee, use oil)
[ALLOWED] Tofu Scramble (NOT egg scramble!)
[ALLOWED] Fruit Smoothie with Almond Milk (NOT dairy milk!)
[ALLOWED] Quinoa Bowl with vegetables
[ALLOWED] Hummus with vegetables
[ALLOWED] Vegetable Biryani (NO ghee, use oil)

IF A FOOD CONTAINS DAIRY, EGGS, MEAT, OR ANY ANIMAL PRODUCT -> DO NOT SUGGEST IT!
"""
    elif dietary_pref_normalized == 'jain':
        return """
**[ALERT] CRITICAL: JAIN DIET ONLY - NO ROOT VEGETABLES & NO NON-VEG [ALERT]**

YOU MUST ONLY SUGGEST FOODS FROM THIS LIST:
[ALLOWED] ALLOWED:
- Above-ground Vegetables: Tomatoes, cucumbers, bell peppers, spinach, cabbage, broccoli, cauliflower, peas
- Fruits: All fruits
- Grains: Rice, wheat, oats, quinoa
- Pulses: Dal, lentils, chickpeas (above-ground varieties)
- Dairy: Milk, yogurt, paneer, cheese (vegetarian)

[REJECTED] [REJECTED] [REJECTED] ABSOLUTELY FORBIDDEN: [REJECTED] [REJECTED] [REJECTED]
- NO ROOT VEGETABLES: onion, garlic, potato, ginger, carrot, radish, beetroot, turnip, sweet potato
- NO EGGS: any egg-based dishes
- NO MEAT/FISH: chicken, turkey, fish, seafood, meat

EXAMPLES OF JAIN FOODS:
[ALLOWED] Tomato Rice (NO onion, NO garlic!)
[ALLOWED] Paneer Tikka (NO onion, NO garlic in marinade!)
[ALLOWED] Dal without onion/garlic tempering
[ALLOWED] Fruit smoothie
[ALLOWED] Vegetable curry with above-ground vegetables only

IF A FOOD CONTAINS ONION, GARLIC, POTATO, GINGER, CARROT, OR ANY ROOT VEGETABLE -> DO NOT SUGGEST IT!
"""
    elif dietary_pref_normalized in ['pescatarian', 'pesc', 'pescetarian']:
        return """
**PESCATARIAN DIET - STRICTLY ENFORCE**

[ALLOWED] ALLOWED:
- All vegetables, fruits, grains, pulses
- Dairy: milk, yogurt, paneer, cheese
- Eggs: omelette, scrambled eggs, boiled eggs
- Fish & Seafood: salmon, tuna, shrimp, prawn, fish curry

[REJECTED] ABSOLUTELY FORBIDDEN:
- NO CHICKEN (chicken curry, grilled chicken, chicken soup, chicken breast)
- NO TURKEY (turkey breast, ground turkey)
- NO MEAT (beef, pork, lamb, mutton, goat)
- NO POULTRY of any kind

EXAMPLES OF PESCATARIAN FOODS:
[ALLOWED] Grilled Salmon
[ALLOWED] Fish Curry
[ALLOWED] Shrimp Stir-fry
[ALLOWED] Vegetable Omelette
[ALLOWED] Paneer Tikka
[ALLOWED] Dal with Rice

IF A FOOD CONTAINS CHICKEN, TURKEY, BEEF, PORK, LAMB, OR ANY MEAT/POULTRY -> DO NOT SUGGEST IT!
"""
    elif dietary_pref_normalized in ['veg_egg', 'veg+egg', 'eggetarian', 'vegetarian_egg']:
        return """
**VEGETARIAN + EGGS DIET - STRICTLY ENFORCE**

[ALLOWED] ALLOWED:
- All vegetables, fruits, grains, pulses
- Dairy: milk, yogurt, paneer, cheese, butter, ghee
- Eggs: omelette, scrambled eggs, boiled eggs, egg curry, fried eggs
- Nuts & seeds

[REJECTED] ABSOLUTELY FORBIDDEN:
- NO CHICKEN (chicken curry, grilled chicken, chicken soup, chicken broth)
- NO TURKEY (turkey breast, ground turkey)
- NO FISH (salmon, tuna, fish curry, fish stock)
- NO SEAFOOD (shrimp, prawn, crab, lobster)
- NO MEAT (beef, pork, lamb, mutton)

EXAMPLES OF VEG+EGG FOODS:
[ALLOWED] Vegetable Omelette
[ALLOWED] Scrambled Eggs with Toast
[ALLOWED] Paneer Tikka
[ALLOWED] Dal with Rice
[ALLOWED] Egg Curry
[ALLOWED] Fruit Smoothie

IF A FOOD CONTAINS CHICKEN, TURKEY, FISH, SEAFOOD, OR ANY MEAT -> DO NOT SUGGEST IT!
"""
    else:  # Non-veg (includes 'non_veg', 'nonveg', 'any', etc.)
        return """
**Non-Vegetarian Diet**
ALL foods allowed: Vegetables, fruits, grains, dairy, eggs, fish, chicken, turkey, meat, seafood
"""


def _get_eating_ability_instructions(eating_ability):
    """Get detailed eating ability instructions with maximum variety"""
    
    if eating_ability == 'liquids_only':
        return """
**CRITICAL: LIQUIDS ONLY - Patient CANNOT CHEW - STRICTLY ENFORCE**

**ONLY SUGGEST DRINKABLE/POURABLE LIQUIDS:**

**INDIAN LIQUIDS:**
- Thin Soups: Tomato soup, Dal water (very thin), Rasam, Vegetable broth
- Beverages: Buttermilk, Lassi, Fruit juice, Coconut water, Herbal tea
- Liquid Porridges: Very thin khichdi (liquid consistency), Rice water, Thin dalia water

**INTERNATIONAL LIQUIDS:**
- Smoothies: Fruit smoothies, Protein shakes, Green smoothies (fully blended)
- Soups: Creamy soups (fully pureed), Vegetable broths, Chicken/bone broth
- Drinks: Milk, Almond milk, Soy milk, Fresh juices, Nutritional drinks

**TEXTURE REQUIREMENT: Must be COMPLETELY LIQUID - drinkable through a straw, NO CHUNKS, NO SOLIDS**
**ABSOLUTELY FORBIDDEN: Any food requiring chewing - NO idli, dosa, khichdi (thick), rice, bread, fruits (unless juiced), vegetables (unless liquid soup)**
"""
    
    elif eating_ability == 'soft_only':
        return """
**CRITICAL: SOFT FOODS ONLY - Minimal chewing required - STRICTLY ENFORCE**

**ONLY SUGGEST VERY SOFT, MELT-IN-MOUTH FOODS:**

**INDIAN SOFT FOODS:**
- Steamed: Soft idli, Dhokla (very soft), Soft dosa (with dal)
- Porridges: Thick khichdi, Curd rice, Dalia, Upma (soft)
- Dal: Dal tadka, Dal makhani (well-cooked)
- Soft curries: Palak paneer (soft), Paneer bhurji

**INTERNATIONAL SOFT FOODS:**
- Porridges: Oatmeal, Cream of wheat, Mashed potatoes
- Egg dishes: Scrambled eggs, Soft omelette, Egg custard
- Others: Yogurt, Pudding, Soft pasta, Mashed vegetables

**TEXTURE: Very soft, easily mashed with fork, no hard/crunchy items**
**FORBIDDEN: Hard, crunchy, chewy foods - NO raw vegetables, nuts, hard breads, fried items**
"""
    
    elif eating_ability == 'reduced':
        return """
**REDUCED EATING ABILITY - Easy to digest, smaller portions**

Include easy-to-digest foods that are gentle on the stomach.
Focus on nutrient-dense options in smaller servings.
"""
    
    else:  # normal or cannot_eat
        return """
**NORMAL EATING ABILITY - All food textures allowed**

Include variety across all textures: soft, regular, crunchy.
Focus on nutritious, cancer-fighting foods.
"""


def _get_symptom_instructions(symptoms):
    """Get instructions based on patient symptoms"""
    if not symptoms:
        return ""
    
    instructions = ["**SYMPTOM-BASED RESTRICTIONS:**"]
    
    for symptom in symptoms:
        symptom_lower = symptom.lower()
        if 'nausea' in symptom_lower or 'vomiting' in symptom_lower:
            instructions.append("- AVOID: Greasy, fried, spicy, or strong-smelling foods")
            instructions.append("- PREFER: Bland, cool, easy-to-digest foods")
        elif 'diarrhea' in symptom_lower:
            instructions.append("- AVOID: High-fiber, fatty, spicy, or dairy-heavy foods")
            instructions.append("- PREFER: Low-fiber, binding foods (banana, rice, toast)")
        elif 'constipation' in symptom_lower:
            instructions.append("- PREFER: High-fiber foods, warm liquids, prunes")
        elif 'sore' in symptom_lower and 'mouth' in symptom_lower:
            instructions.append("- AVOID: Spicy, acidic, rough-textured, or very hot foods")
            instructions.append("- PREFER: Soft, cool, smooth foods")
        elif 'fatigue' in symptom_lower or 'weakness' in symptom_lower:
            instructions.append("- PREFER: Energy-dense, protein-rich, easy-to-eat foods")
    
    return "\n".join(instructions) if len(instructions) > 1 else ""


def _get_allergy_instructions(allergies):
    """Get instructions based on patient allergies"""
    if not allergies:
        return ""
    
    # Expand allergen descriptions
    allergen_details = {
        'dairy': 'milk, cheese, yogurt, cream, butter, ghee, paneer, curd, dahi, lassi, raita, khoya',
        'milk': 'milk, cream, dairy products',
        'cheese': 'cheese, paneer, cheddar, mozzarella, ricotta',
        'yogurt': 'yogurt, curd, dahi, lassi, raita',
        'eggs': 'eggs, omelette, scrambled eggs, boiled eggs',
        'egg': 'eggs, omelette, scrambled eggs, boiled eggs',
        'nuts': 'nuts, almonds, walnuts, cashews, peanuts, pistachios',
        'soy': 'soy, tofu, tempeh, edamame, soybeans',
        'gluten': 'wheat, bread, pasta, noodles, roti, chapati, barley, rye',
        'wheat': 'wheat, bread, pasta, noodles, roti, chapati',
        'shellfish': 'shellfish, shrimp, prawns, crab, lobster',
        'seafood': 'fish, seafood, shrimp, prawns, shellfish',
        'fish': 'fish, salmon, tuna, mackerel',
        'red meat': 'beef, pork, lamb, mutton, goat',
        'poultry': 'chicken, turkey, duck'
    }
    
    # Build detailed allergen list
    detailed_allergens = []
    for allergen in allergies:
        allergen_lower = allergen.lower().strip()
        if allergen_lower in allergen_details:
            detailed_allergens.append(f"{allergen} ({allergen_details[allergen_lower]})")
        else:
            detailed_allergens.append(allergen)
    
    allergen_list = ", ".join(detailed_allergens)
    
    return f"""
**[ALERT] CRITICAL ALLERGY ALERT - PATIENT SAFETY FIRST [ALERT]**
ABSOLUTELY FORBIDDEN ALLERGENS: {allergen_list}
DO NOT suggest ANY food containing these allergens or their derivatives
IF food contains ANY of these - SKIP IT IMMEDIATELY
Patient has SEVERE allergies - this is life-threatening!
"""


def get_quick_nutrition_tips(patient_profile):
    """Get 3-5 quick AI-generated nutrition tips"""
    
    try:
        prompt = f"""Give 3 brief, actionable nutrition tips for a {patient_profile.get('cancer_type', 'cancer')} patient during {patient_profile.get('treatment_stage', 'treatment')}.
        
Each tip should be:
- Maximum 15 words
- Practical and actionable
- Evidence-based
- Specific to their condition

Return ONLY JSON: [{{"tip": "..."}}]"""

        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.7, "maxOutputTokens": 300}
        }
        
        response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'},
                                json=data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            text = result['candidates'][0]['content']['parts'][0]['text']
            
            json_start = text.find('[')
            json_end = text.rfind(']') + 1
            if json_start != -1:
                json_text = text[json_start:json_end]
                tips = json.loads(json_text)
                return [t['tip'] for t in tips if isinstance(t, dict) and 'tip' in t]
    except:
        pass
    
    return [
        "Eat small, frequent meals (5-6 times daily)",
        "Stay well hydrated - aim for 8-10 glasses of water",
        "Choose high-protein foods at every meal"
    ]
