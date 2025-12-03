"""
Generate comprehensive cancer-optimized food database
Focuses on nutrient-dense, anti-cancer foods
Avoids: fried foods, high-sugar items, processed foods
Emphasizes: whole grains, lean proteins, vegetables, fruits, anti-inflammatory foods
"""

import os
import json
import time
import requests
from dotenv import load_dotenv
from typing import List, Dict

# Load environment variables
script_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(script_dir, '..', '..', 'datasets', 'cancer_data', '.env')
load_dotenv(dotenv_path=env_path)
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    print("Error: GOOGLE_API_KEY not found.")
    exit(1)

GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GOOGLE_API_KEY}"

# Categories and configuration
CATEGORIES = ['pure_veg', 'vegan', 'jain', 'veg_egg', 'pescatarian', 'non_veg']
MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack']
ITEMS_PER_BATCH = 8  # Generate 8 items at a time for speed
BATCHES_PER_MEAL = 3  # 8 items × 3 batches = 24 items per meal type

def generate_cancer_optimized_foods(category: str, meal_type: str, batch_num: int) -> List[Dict]:
    """Generate cancer-optimized foods in small batches"""
    
    print(f"    Batch {batch_num + 1}/{BATCHES_PER_MEAL}... ", end="", flush=True)
    
    dietary_guidelines = {
        'pure_veg': "Pure Vegetarian (NO meat, fish, eggs). Include dairy (milk, paneer, yogurt, cheese).",
        'vegan': "Vegan (NO animal products - no meat, fish, eggs, dairy, honey).",
        'jain': "Jain (NO meat, fish, eggs, NO root vegetables like onion, garlic, potato, carrot, ginger). Dairy OK.",
        'veg_egg': "Vegetarian + Eggs (Eggs allowed, NO meat, fish, chicken, seafood).",
        'pescatarian': "Pescatarian (Fish + Seafood + Eggs + Dairy + Vegetables OK. NO chicken, turkey, meat, poultry).",
        'non_veg': "Non-Vegetarian (All foods allowed - vegetables, eggs, fish, chicken, lean meats). Focus on lean proteins."
    }
    
    cuisine_mix = "60% Indian (North, South, East, West regional varieties), 40% International (Mediterranean, Asian, Continental)"
    
    prompt = f"""Generate {ITEMS_PER_BATCH} CANCER-OPTIMIZED {meal_type} foods for {category} diet.

DIETARY REQUIREMENT: {dietary_guidelines[category]}

CUISINE MIX: {cuisine_mix}

CRITICAL - FOODS TO AVOID (DO NOT INCLUDE):
❌ Deep-fried foods (samosa, pakora, french fries, fried chicken, chips)
❌ High-sugar desserts (gulab jamun, rasgulla, jalebi, candy, ice cream)
❌ Processed meats (sausages, bacon, hot dogs, salami)
❌ Refined flour items (maida-based foods, white bread, naan)
❌ High-fat gravies with excessive cream/butter
❌ Carbonated drinks, sugary beverages
❌ Artificial sweeteners and preservatives

CANCER-FIGHTING FOODS TO PRIORITIZE:
✓ Cruciferous vegetables (broccoli, cauliflower, cabbage, kale)
✓ Colorful vegetables (tomatoes, carrots, bell peppers, spinach)
✓ Whole grains (brown rice, quinoa, oats, whole wheat)
✓ Legumes and lentils (dal, beans, chickpeas)
✓ Lean proteins (fish, chicken breast, tofu, paneer, eggs)
✓ Anti-inflammatory spices (turmeric, ginger, garlic if allowed)
✓ Antioxidant-rich fruits (berries, citrus, pomegranate)
✓ Healthy fats (olive oil, nuts, seeds, avocado)
✓ Probiotic foods (yogurt, curd, fermented foods)

NUTRITION TARGETS FOR CANCER PATIENTS:
- High protein (10-20g per serving)
- Moderate calories (150-400 kcal)
- High fiber (5-10g)
- Anti-inflammatory ingredients
- Easy to digest
- Minimal processing

Return ONLY valid JSON array (no markdown, no explanations):
[
  {{"name":"Food name (authentic, specific)","cuisine":"Indian Regional/Mediterranean/Asian/etc","calories":250,"protein":15,"carbs":30,"fiber":7,"preparation":"Cooking method (steamed/grilled/baked/light sauté)","cancer_benefits":"Specific anti-cancer properties and nutrients"}}
]

Generate {ITEMS_PER_BATCH} diverse, cancer-optimized foods:"""

    data = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.8,
            "maxOutputTokens": 2048
        }
    }

    for attempt in range(3):
        try:
            response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, 
                                   json=data, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and len(result['candidates']) > 0:
                    candidate = result['candidates'][0]
                    if 'content' in candidate and 'parts' in candidate['content']:
                        text = candidate['content']['parts'][0]['text'].strip()
                        
                        # Clean response
                        if '```json' in text:
                            text = text.split('```json')[1].split('```')[0]
                        elif '```' in text:
                            text = text.split('```')[1].split('```')[0]
                        
                        # Extract JSON array
                        start = text.find('[')
                        end = text.rfind(']')
                        if start != -1 and end != -1:
                            text = text[start:end+1]
                        
                        foods = json.loads(text)
                        
                        if isinstance(foods, list) and len(foods) > 0:
                            # Add metadata
                            for f in foods:
                                f['meal_type'] = meal_type
                                f['food_type'] = category
                                # Ensure all fields
                                if 'cancer_benefits' not in f:
                                    f['cancer_benefits'] = "Nutrient-dense food for cancer recovery"
                            
                            print(f"✓ {len(foods)}")
                            return foods
                            
            elif response.status_code == 429:
                print("Rate limit, waiting...")
                time.sleep(10)
            else:
                if attempt < 2:
                    time.sleep(2)
                    
        except json.JSONDecodeError:
            if attempt < 2:
                time.sleep(1)
        except Exception as e:
            if attempt < 2:
                time.sleep(1)
    
    print("✗")
    return []

def generate_all_foods_for_meal(category: str, meal_type: str) -> List[Dict]:
    """Generate all foods for one meal type"""
    all_foods = []
    
    for batch in range(BATCHES_PER_MEAL):
        foods = generate_cancer_optimized_foods(category, meal_type, batch)
        if foods:
            all_foods.extend(foods)
        time.sleep(1.5)  # Rate limiting
    
    return all_foods

def main():
    print("=" * 80)
    print("CANCER-OPTIMIZED FOOD DATABASE GENERATOR")
    print("=" * 80)
    print("Generating healthy, anti-cancer foods")
    print("Avoiding: fried foods, high-sugar items, processed foods")
    print("Target: 24 items per meal × 4 meals = 96 items per category")
    print("Total: 96 × 6 categories = 576 cancer-optimized foods")
    print("Estimated time: 10-15 minutes")
    print("=" * 80)
    
    database = {}
    data_dir = os.path.join(script_dir, '..', 'data')
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
    
    output_path = os.path.join(data_dir, 'curated_food_database.json')
    
    total_generated = 0
    
    for cat_idx, category in enumerate(CATEGORIES):
        print(f"\n{'='*80}")
        print(f"[{cat_idx + 1}/{len(CATEGORIES)}] Category: {category.upper()}")
        print(f"{'='*80}")
        
        category_foods = []
        
        for meal_idx, meal in enumerate(MEAL_TYPES):
            print(f"  [{meal_idx + 1}/{len(MEAL_TYPES)}] {meal.capitalize()}:")
            
            foods = generate_all_foods_for_meal(category, meal)
            category_foods.extend(foods)
            
            print(f"      Total {meal}: {len(foods)}/24")
        
        database[category] = category_foods
        total_generated += len(category_foods)
        
        print(f"\n  {category.upper()} Complete: {len(category_foods)} foods")
    
    # Backup existing database
    if os.path.exists(output_path):
        backup_path = output_path + '.old'
        if os.path.exists(backup_path):
            os.remove(backup_path)
        os.rename(output_path, backup_path)
        print(f"\n✓ Backed up old database to: {backup_path}")
    
    # Save new database
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(database, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*80}")
    print(f"DATABASE GENERATION COMPLETE")
    print(f"{'='*80}")
    print(f"Total foods generated: {total_generated}")
    print(f"Saved to: {output_path}")
    print(f"\nBreakdown by category:")
    for cat, foods in database.items():
        meal_counts = {}
        for food in foods:
            meal_type = food.get('meal_type', 'unknown')
            meal_counts[meal_type] = meal_counts.get(meal_type, 0) + 1
        
        print(f"  {cat}: {len(foods)} total ({', '.join(f'{k}={v}' for k, v in meal_counts.items())})")
    print(f"{'='*80}\n")

if __name__ == "__main__":
    main()
