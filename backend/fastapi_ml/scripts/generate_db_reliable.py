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

CATEGORIES = ['pure_veg', 'vegan', 'jain', 'veg_egg', 'pescatarian', 'non_veg']
MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack']
ITEMS_PER_BATCH = 5  # Small batches for reliability
BATCHES_PER_MEAL = 6  # 5 items × 6 batches = 30 items per meal

def generate_food_batch(category: str, meal_type: str, batch_num: int) -> List[Dict]:
    """Generate a small batch of 5 foods"""
    print(f"  Batch {batch_num + 1}/{BATCHES_PER_MEAL}...", end=" ")
    
    dietary_info = {
        'pure_veg': "Pure Vegetarian - NO meat, fish, eggs. Dairy OK (milk, paneer, yogurt).",
        'vegan': "Vegan - NO animal products (no dairy, eggs, meat, fish, honey).",
        'jain': "Jain - NO meat, fish, eggs, NO root vegetables (onion, garlic, potato, carrot, ginger). Dairy OK.",
        'veg_egg': "Vegetarian + Eggs - Eggs allowed. NO meat, fish, chicken.",
        'pescatarian': "Pescatarian - Fish + Seafood + Eggs + Dairy OK. NO chicken, turkey, meat, poultry.",
        'non_veg': "Non-Vegetarian - All foods allowed. Provide a balanced mix of veg and non-veg."
    }
    
    prompt = f"""Generate {ITEMS_PER_BATCH} {meal_type} foods for {category} diet suitable for cancer patients.

DIETARY RULE: {dietary_info[category]}

FOCUS: High protein, anti-inflammatory, antioxidant-rich, easy to digest.

Return ONLY valid JSON array:
[
  {{"name":"Food name","cuisine":"Indian/Chinese/etc","calories":200,"protein":12,"carbs":25,"fiber":5,"preparation":"Cooking method","cancer_benefits":"Why good for cancer patients - mention specific nutrients/compounds"}}
]"""

    data = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.6,
            "maxOutputTokens": 1024
        }
    }

    for attempt in range(3):
        try:
            response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, json=data, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and len(result['candidates']) > 0:
                    text = result['candidates'][0]['content']['parts'][0]['text']
                    
                    # Clean response
                    text = text.strip()
                    # Remove markdown formatting
                    if '```' in text:
                        parts = text.split('```')
                        for part in parts:
                            part = part.strip()
                            if part.startswith('json'):
                                part = part[4:].strip()
                            if part.startswith('[') and ']' in part:
                                text = part
                                break
                    
                    # Find JSON array
                    start = text.find('[')
                    end = text.rfind(']')
                    if start != -1 and end != -1:
                        text = text[start:end+1]
                    
                    # Parse JSON
                    foods = json.loads(text)
                    
                    if isinstance(foods, list) and len(foods) > 0:
                        # Add metadata
                        for f in foods:
                            f['meal_type'] = meal_type
                            f['food_type'] = category
                            # Ensure all fields exist
                            if 'cancer_benefits' not in f:
                                f['cancer_benefits'] = "Nutrient-rich food suitable for cancer patients"
                        
                        print(f"✓ {len(foods)} items")
                        return foods
                    
            elif response.status_code == 429:
                print(f"Rate limit, waiting...")
                time.sleep(10)
            else:
                if attempt == 0:
                    print(f"API error {response.status_code}, retry...")
                    time.sleep(2)
                    
        except json.JSONDecodeError as e:
            if attempt < 2:
                print(f"Parse error, retry...")
                time.sleep(1)
        except Exception as e:
            if attempt < 2:
                print(f"Error ({str(e)[:30]}), retry...")
                time.sleep(1)
    
    print("✗ Failed")
    return []

def generate_foods_for_meal(category: str, meal_type: str) -> List[Dict]:
    """Generate all foods for a meal type in small batches"""
    print(f"\n  {meal_type.capitalize()}: ", end="")
    all_foods = []
    
    for batch in range(BATCHES_PER_MEAL):
        foods = generate_food_batch(category, meal_type, batch)
        if foods:
            all_foods.extend(foods)
        time.sleep(1)  # Small delay between batches
    
    print(f"\n    Total: {len(all_foods)}/{ITEMS_PER_BATCH * BATCHES_PER_MEAL}")
    return all_foods

def main():
    print("=" * 70)
    print("CANCER NUTRITION DATABASE GENERATOR (RELIABLE MODE)")
    print("=" * 70)
    print(f"Generating {ITEMS_PER_BATCH * BATCHES_PER_MEAL} items per meal × {len(MEAL_TYPES)} meals")
    print(f"= {ITEMS_PER_BATCH * BATCHES_PER_MEAL * len(MEAL_TYPES)} items per category")
    print(f"× {len(CATEGORIES)} categories = {ITEMS_PER_BATCH * BATCHES_PER_MEAL * len(MEAL_TYPES) * len(CATEGORIES)} total foods")
    print("=" * 70)
    
    database = {}
    
    data_dir = os.path.join(script_dir, '..', 'data')
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        
    output_path = os.path.join(data_dir, 'curated_food_database.json')
    
    total_foods = 0
    
    for category in CATEGORIES:
        print(f"\n{'='*70}")
        print(f"Category: {category.upper()}")
        print(f"{'='*70}")
        
        category_foods = []
        
        for meal in MEAL_TYPES:
            foods = generate_foods_for_meal(category, meal)
            category_foods.extend(foods)
        
        database[category] = category_foods
        total_foods += len(category_foods)
        print(f"\n{category.upper()} Summary: {len(category_foods)} foods")
    
    # Backup existing
    if os.path.exists(output_path):
        backup_path = output_path + '.backup'
        if os.path.exists(backup_path):
            os.remove(backup_path)
        os.rename(output_path, backup_path)
        print(f"\nBacked up existing database")
    
    # Save
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(database, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*70}")
    print(f"COMPLETE: {total_foods} foods generated")
    print(f"Saved to: {output_path}")
    print(f"{'='*70}\n")
    
    for cat, foods in database.items():
        print(f"  {cat}: {len(foods)} foods")

if __name__ == "__main__":
    main()
