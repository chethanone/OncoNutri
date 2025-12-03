import os
import json
import time
import requests
from dotenv import load_dotenv
from typing import List, Dict

# Load environment variables (fix path)
script_dir = os.path.dirname(os.path.abspath(__file__))
# Script is in backend/fastapi_ml/scripts/
# .env is in backend/datasets/cancer_data/
env_path = os.path.join(script_dir, '..', '..', 'datasets', 'cancer_data', '.env')
load_dotenv(dotenv_path=env_path)
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    print("Error: GOOGLE_API_KEY not found.")
    exit(1)

GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GOOGLE_API_KEY}"

CATEGORIES = ['pure_veg', 'vegan', 'jain', 'veg_egg', 'pescatarian', 'non_veg']
MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack']
ITEMS_PER_MEAL = 10  # Generate 10 items per batch (smaller for reliability)
BATCHES_PER_MEAL = 3  # Run 3 batches to get 30 items total

def generate_foods_for_category(category: str, meal_type: str) -> List[Dict]:
    print(f"\nGenerating {ITEMS_PER_MEAL} {meal_type} items for {category}...")
    
    # Enhanced prompts with cancer-specific guidance
    dietary_rules = {
        'pure_veg': "Pure Vegetarian (NO meat, fish, eggs. Dairy products like milk, yogurt, paneer are OK)",
        'vegan': "Vegan (NO animal products - no dairy, eggs, meat, fish, honey)",
        'jain': "Jain (NO meat, fish, eggs, AND NO root vegetables like onion, garlic, potato, carrot, ginger. Dairy OK)",
        'veg_egg': "Vegetarian + Eggs (Eggs allowed. NO meat, fish, poultry)",
        'pescatarian': "Pescatarian (Fish + Seafood + Eggs + Dairy + Vegetables OK. NO chicken, turkey, meat, poultry)",
        'non_veg': "Non-Vegetarian (All foods allowed: vegetables, eggs, fish, chicken, meat. Provide a balanced mix)"
    }
    
    prompt = f"""Generate {ITEMS_PER_MEAL} vegetarian breakfast foods for cancer patients. Keep descriptions under 80 characters.

Diet: {dietary_rules[category]}

Output JSON array ONLY:
[{{"name":"Food Name","cuisine":"Indian","calories":200,"protein":10,"carbs":25,"fiber":5,"preparation":"Brief method","cancer_benefits_general":"General benefit (short)","cancer_specific_benefits":{{"breast":"Breast benefit","lung":"Lung benefit","colorectal":"Colon benefit","prostate":"Prostate benefit","stomach":"Stomach benefit"}}}}]

Generate {ITEMS_PER_MEAL} foods:"""

    data = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 3000,  # Limit tokens to prevent truncation
            "stopSequences": []
        }
    }

    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = requests.post(GEMINI_API_URL, headers={'Content-Type': 'application/json'}, json=data, timeout=90)
            
            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and len(result['candidates']) > 0:
                    text = result['candidates'][0]['content']['parts'][0]['text']
                    
                    # Aggressive JSON cleanup
                    text = text.strip()
                    # Remove markdown code blocks
                    text = text.replace('```json', '').replace('```', '')
                    # Remove any text before first [ and after last ]
                    start_idx = text.find('[')
                    end_idx = text.rfind(']')
                    if start_idx != -1 and end_idx != -1:
                        text = text[start_idx:end_idx + 1]
                    
                    # Try to fix common JSON errors
                    text = text.replace('\n', ' ').replace('\r', '')
                    # Fix unterminated strings by removing problematic characters
                    text = text.replace('\\"', '"').replace("\\'", "'")
                    
                    # Parse JSON
                    try:
                        foods = json.loads(text)
                        if isinstance(foods, list) and len(foods) > 0:
                            # Ensure all required fields
                            valid_foods = []
                            for f in foods:
                                if isinstance(f, dict) and 'name' in f:
                                    f['meal_type'] = meal_type
                                    f['food_type'] = category
                                    # Ensure all fields exist with defaults
                                    f.setdefault('cuisine', 'Mixed')
                                    f.setdefault('calories', 200)
                                    f.setdefault('protein', 10.0)
                                    f.setdefault('carbs', 20.0)
                                    f.setdefault('fiber', 3.0)
                                    f.setdefault('preparation', 'Standard preparation')
                                    f.setdefault('cancer_benefits_general', 'Supports cancer recovery')
                                    f.setdefault('cancer_specific_benefits', {
                                        'breast': 'Provides nutrients for recovery',
                                        'lung': 'Supports respiratory health',
                                        'colorectal': 'Aids digestive system',
                                        'prostate': 'Supports prostate health',
                                        'stomach': 'Gentle on stomach'
                                    })
                                    valid_foods.append(f)
                            
                            if len(valid_foods) > 0:
                                print(f"  ✓ Successfully generated {len(valid_foods)} foods")
                                return valid_foods
                            else:
                                print(f"  ✗ No valid foods in response (attempt {attempt + 1}/{max_retries})")
                        else:
                            print(f"  ✗ Invalid response structure (attempt {attempt + 1}/{max_retries})")
                    except json.JSONDecodeError as e:
                        # Try to salvage partial JSON
                        print(f"  ✗ JSON parse error (attempt {attempt + 1}/{max_retries}): {str(e)[:100]}")
                        # Save error response for debugging
                        if attempt == max_retries - 1:
                            print(f"  Last response preview: {text[:200]}...")
                else:
                    print(f"  ✗ No candidates in response (attempt {attempt + 1}/{max_retries})")
            else:
                print(f"  ✗ API Error {response.status_code} (attempt {attempt + 1}/{max_retries})")
                if response.status_code == 429:
                    print(f"  Rate limited. Waiting 10 seconds...")
                    time.sleep(10)
                    
        except requests.exceptions.Timeout:
            print(f"  ✗ Request timeout (attempt {attempt + 1}/{max_retries})")
        except Exception as e:
            print(f"  ✗ Error: {str(e)[:100]} (attempt {attempt + 1}/{max_retries})")
        
        if attempt < max_retries - 1:
            time.sleep(5)  # Longer delay between retries
    
    print(f"  ✗ Failed after {max_retries} attempts")
    return []

def main():
    print("=" * 70)
    print("CANCER NUTRITION DATABASE GENERATOR")
    print("=" * 70)
    print(f"Target: {ITEMS_PER_MEAL} items per meal type × {len(MEAL_TYPES)} meals")
    print(f"Total categories: {len(CATEGORIES)}")
    print(f"Estimated total foods: {ITEMS_PER_MEAL * len(MEAL_TYPES) * len(CATEGORIES)}")
    print("=" * 70)
    
    database = {}
    
    # Fix path
    data_dir = os.path.join(script_dir, '..', 'data')
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        print(f"Created data directory: {data_dir}")
        
    output_path = os.path.join(data_dir, 'curated_food_database.json')
    print(f"Output path: {output_path}\n")
    
    total_foods = 0
    failed_generations = []
    
    for category in CATEGORIES:
        category_foods = []
        print(f"\n{'='*70}")
        print(f"Processing Category: {category.upper()}")
        print(f"{'='*70}")
        
        for meal in MEAL_TYPES:
            meal_foods = []
            
            # Generate multiple batches to get more variety
            for batch_num in range(BATCHES_PER_MEAL):
                print(f"  Batch {batch_num + 1}/{BATCHES_PER_MEAL} for {meal}...")
                foods = generate_foods_for_category(category, meal)
                if foods:
                    meal_foods.extend(foods)
                    print(f"    ✓ Got {len(foods)} foods (Total {meal} foods: {len(meal_foods)})")
                    time.sleep(2)  # Rate limiting between batches
                else:
                    print(f"    ✗ Batch failed")
                    failed_generations.append(f"{category} - {meal} - batch {batch_num + 1}")
            
            category_foods.extend(meal_foods)
            print(f"  ✓ Total {meal} items: {len(meal_foods)} (Category total: {len(category_foods)})\n")
        
        database[category] = category_foods
        total_foods += len(category_foods)
        print(f"\n{category.upper()} Summary: {len(category_foods)} foods generated")

    # Backup existing database
    if os.path.exists(output_path):
        backup_path = output_path + '.backup'
        if os.path.exists(backup_path):
            os.remove(backup_path)
        os.rename(output_path, backup_path)
        print(f"\nBacked up existing database to: {backup_path}")
        
    # Save new database
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(database, f, indent=2, ensure_ascii=False)
        
    print(f"\n{'='*70}")
    print(f"DATABASE GENERATION COMPLETE")
    print(f"{'='*70}")
    print(f"Total foods generated: {total_foods}")
    print(f"Saved to: {output_path}")
    
    if failed_generations:
        print(f"\n⚠️  Failed generations ({len(failed_generations)}):")
        for failed in failed_generations:
            print(f"  - {failed}")
    
    print(f"{'='*70}\n")
    
    # Summary by category
    print("Summary by Category:")
    for cat, foods in database.items():
        print(f"  {cat}: {len(foods)} foods")

if __name__ == "__main__":
    main()

