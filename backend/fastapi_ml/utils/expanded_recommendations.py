"""
Expanded recommendation system combining curated database + FoodData Central
Provides thousands of cancer-appropriate food options
"""

import pandas as pd
import numpy as np
import os
import json
from typing import List, Dict, Optional
import random

# Paths
FOODDATA_PATH = os.path.join(os.path.dirname(__file__), '../../datasets/nutrition_data/FoodData_Central_csv_2025-04-24')
CURATED_DB_PATH = os.path.join(os.path.dirname(__file__), '../data/curated_food_database.json')

# Cache for loaded data
_fooddata_cache = None
_nutrient_cache = None
_curated_cache = None


def load_curated_foods():
    """Load curated cancer-optimized foods"""
    global _curated_cache
    if _curated_cache is None:
        with open(CURATED_DB_PATH, 'r', encoding='utf-8') as f:
            _curated_cache = json.load(f)
    return _curated_cache


def load_fooddata_central():
    """Load and filter FoodData Central database for healthy foods"""
    global _fooddata_cache, _nutrient_cache
    
    if _fooddata_cache is not None:
        return _fooddata_cache, _nutrient_cache
    
    print("Loading FoodData Central database...")
    
    # Load food descriptions
    food_df = pd.read_csv(os.path.join(FOODDATA_PATH, 'food.csv'), 
                          usecols=['fdc_id', 'description', 'data_type', 'food_category_id'])
    
    # Load food nutrients
    food_nutrient_df = pd.read_csv(os.path.join(FOODDATA_PATH, 'food_nutrient.csv'),
                                   usecols=['fdc_id', 'nutrient_id', 'amount'])
    
    # STRICT filtering: Only whole, nutritious foods for cancer patients
    healthy_keywords = [
        'vegetable', 'fruit', 'grain', 'legume', 'bean', 'lentil', 'pea', 'chickpea',
        'yogurt', 'milk', 'cheese', 'paneer', 'nut', 'seed', 'oat', 'almond', 'walnut',
        'rice', 'wheat', 'quinoa', 'millet', 'barley', 'spinach', 'broccoli', 'kale',
        'tomato', 'carrot', 'beet', 'cabbage', 'cauliflower', 'mushroom', 'squash',
        'soup', 'salad', 'berry', 'citrus', 'apple', 'banana', 'orange', 'grape',
        'lentil', 'tofu', 'tempeh', 'whole grain', 'brown rice'
    ]
    
    # COMPREHENSIVE unhealthy/junk food exclusions
    unhealthy_keywords = [
        'candy', 'candies', 'chocolate bar', 'donut', 'doughnut', 'cookie', 'cake', 'pie', 
        'ice cream', 'soda', 'energy drink', 'chips', 'fries', 'fried', 'fast food',
        'pizza', 'hotdog', 'hot dog', 'bacon', 'sausage', 'salami', 'pepperoni',
        'alcohol', 'beer', 'wine', 'liquor', 'snickers', 'mars', 'kitkat', 'twix',
        'milky way', 'butterfinger', 'reese', 'hershey', 'cadbury', 'nestle',
        'formulated bar', 'protein bar', 'granola bar', 'cereal bar', 'snack bar',
        'processed cheese', 'cheese spread', 'crackers', 'pretzels', 'popcorn',
        'pudding', 'jello', 'jam', 'jelly', 'syrup', 'sauce', 'dressing',
        'canned soup', 'instant', 'frozen meal', 'tv dinner', 'microwave',
        'sweetened', 'sugar-coated', 'frosted', 'glazed'
    ]
    
    # Filter foods
    food_df['description_lower'] = food_df['description'].str.lower()
    
    # Include foods with healthy keywords
    healthy_mask = food_df['description_lower'].str.contains('|'.join(healthy_keywords), na=False)
    
    # Exclude foods with unhealthy keywords
    unhealthy_mask = food_df['description_lower'].str.contains('|'.join(unhealthy_keywords), na=False)
    
    # Keep only healthy foods (branded foods for package items, sr_legacy for whole foods)
    food_df = food_df[healthy_mask & ~unhealthy_mask].copy()
    food_df = food_df[food_df['data_type'].isin(['sr_legacy_food', 'survey_fndds_food', 'foundation_food'])]
    
    print(f"Filtered to {len(food_df)} healthy foods from FoodData Central")
    
    # Merge nutrients (protein, calories, fiber)
    nutrients = food_nutrient_df[food_nutrient_df['nutrient_id'].isin([1003, 1008, 1079])]  # Protein, Energy, Fiber
    
    # Remove duplicates by keeping first occurrence
    nutrients = nutrients.drop_duplicates(subset=['fdc_id', 'nutrient_id'], keep='first')
    
    nutrients_pivot = nutrients.pivot(index='fdc_id', columns='nutrient_id', values='amount').reset_index()
    nutrients_pivot.columns = ['fdc_id', 'protein_g', 'calories_kcal', 'fiber_g']
    
    # Merge with food data
    food_df = food_df.merge(nutrients_pivot, on='fdc_id', how='left')
    
    # Fill missing values
    food_df['protein_g'] = food_df['protein_g'].fillna(0)
    food_df['calories_kcal'] = food_df['calories_kcal'].fillna(0)
    food_df['fiber_g'] = food_df['fiber_g'].fillna(0)
    
    # Filter out zero-nutrient items
    food_df = food_df[(food_df['calories_kcal'] > 0) | (food_df['protein_g'] > 0)]
    
    _fooddata_cache = food_df
    _nutrient_cache = nutrients_pivot
    
    print(f"Loaded {len(food_df)} healthy, nutrient-rich foods")
    return food_df, nutrients_pivot


def categorize_dietary_type(description: str) -> str:
    """Categorize food into dietary types"""
    desc_lower = description.lower()
    
    if any(word in desc_lower for word in ['chicken', 'turkey', 'beef', 'pork', 'lamb', 'meat']):
        return 'Non-Veg'
    elif any(word in desc_lower for word in ['fish', 'salmon', 'tuna', 'shrimp', 'prawn', 'seafood']):
        return 'Pescatarian'
    elif 'egg' in desc_lower:
        return 'Veg+Egg'
    elif any(word in desc_lower for word in ['milk', 'cheese', 'paneer', 'yogurt', 'butter', 'cream']):
        return 'Pure Veg'
    else:
        return 'Vegan'


def get_expanded_recommendations(patient_profile: Dict, num_recommendations: int = 15) -> List[Dict]:
    """
    Get recommendations combining curated foods + FoodData Central
    
    Args:
        patient_profile: Patient information including cancer_type, dietary_preference
        num_recommendations: Number of foods to return (default 15)
    
    Returns:
        List of food recommendations with nutritional info
    """
    dietary_pref_raw = patient_profile.get('dietary_preference', 'Non-Veg')
    
    # Normalize dietary preference (handle both 'pure_veg' and 'Pure Veg' formats)
    pref_normalize = {
        'pure_veg': 'Pure Veg',
        'vegan': 'Vegan',
        'jain': 'Jain',
        'veg_egg': 'Veg+Egg',
        'pescatarian': 'Pescatarian',
        'non_veg': 'Non-Veg',
        'Pure Veg': 'Pure Veg',
        'Vegan': 'Vegan',
        'Jain': 'Jain',
        'Veg+Egg': 'Veg+Egg',
        'Pescatarian': 'Pescatarian',
        'Non-Veg': 'Non-Veg'
    }
    
    dietary_pref = pref_normalize.get(dietary_pref_raw, 'Pure Veg')
    
    # Get patient's allergies and eating ability
    allergies = patient_profile.get('allergies', [])
    eating_ability = patient_profile.get('eating_ability', 'normal')
    
    # Load curated foods
    curated_db = load_curated_foods()
    
    # Map dietary preferences to database keys
    diet_map = {
        'Pure Veg': 'pure_veg',
        'Vegan': 'vegan',
        'Jain': 'jain',
        'Veg+Egg': 'veg_egg',
        'Pescatarian': 'pescatarian',
        'Non-Veg': 'non_veg'
    }
    
    diet_key = diet_map.get(dietary_pref, 'pure_veg')
    curated_foods = curated_db.get(diet_key, [])
    
    # FILTER 1: Remove foods with allergens
    if allergies:
        # Expand allergen keywords to include related terms
        allergen_map = {
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
        
        expanded_allergens = []
        for allergen in allergies:
            allergen_lower = allergen.lower()
            if allergen_lower in allergen_map:
                expanded_allergens.extend(allergen_map[allergen_lower])
            else:
                expanded_allergens.append(allergen_lower)
        
        curated_foods = [
            f for f in curated_foods 
            if not any(allergen in f.get('name', '').lower() or 
                      allergen in f.get('preparation', '').lower()
                      for allergen in expanded_allergens)
        ]
        print(f"After allergen filter ({allergies} -> {expanded_allergens}): {len(curated_foods)} foods remain")
    
    # FILTER 2: Texture filtering based on eating ability
    if eating_ability in ['difficulty_swallowing', 'very_difficult', 'difficulty swallowing', 'hard to swallow']:
        # Only soft/liquid foods for swallowing difficulties
        # Prefer foods that are naturally soft or can be made soft
        preferred_soft = ['soup', 'smoothie', 'juice', 'milk', 'yogurt', 'pudding', 'porridge', 
                         'puree', 'mashed', 'dal', 'khichdi', 'curry', 'stew', 'broth', 'oatmeal',
                         'cream', 'shake', 'lassi', 'congee', 'risotto', 'noodle', 'pasta']
        
        # Definitely exclude hard/crunchy foods
        exclude_hard = ['salad', 'raw', 'roasted', 'fried', 'grilled', 'crispy', 'crunchy', 
                       'whole grain', 'nuts', 'seeds', 'chips', 'crackers', 'toast', 'bread',
                       'roll', 'biscuit', 'cookie', 'granola', 'skewer', 'kebab', 'cutlet',
                       'pakora', 'samosa', 'spring roll', 'fritter', 'pumpkin seeds', 'mixed seeds',
                       'almond', 'walnut', 'cashew', 'peanut', 'pistachio', 'hazelnut']
        
        # First, try to get foods with preferred soft keywords
        soft_foods = [
            f for f in curated_foods
            if any(keyword in f.get('name', '').lower() or 
                  keyword in f.get('preparation', '').lower() 
                  for keyword in preferred_soft)
        ]
        
        # Remove any that have hard texture indicators
        soft_foods = [
            f for f in soft_foods
            if not any(keyword in f.get('name', '').lower() or 
                      keyword in f.get('preparation', '').lower() 
                      for keyword in exclude_hard)
        ]
        
        # If we have enough soft foods, use only those
        if len(soft_foods) >= 10:
            curated_foods = soft_foods
        else:
            # Otherwise, just exclude definitely hard foods
            curated_foods = [
                f for f in curated_foods
                if not any(keyword in f.get('name', '').lower() or 
                          keyword in f.get('preparation', '').lower() 
                          for keyword in exclude_hard)
            ]
        
        print(f"After texture filter (soft/liquid for swallowing difficulty): {len(curated_foods)} foods remain")
    
    # IMPORTANT: For vegetarian diets, use ONLY curated foods to avoid contamination
    # FoodData Central has too many edge cases (fish labeled as healthy, processed foods, etc.)
    use_only_curated = dietary_pref in ['Pure Veg', 'Vegan', 'Jain', 'Veg+Egg']
    
    if use_only_curated:
        # Use 100% curated foods for strict vegetarian diets
        num_curated = min(num_recommendations, len(curated_foods))
        num_fooddata = 0
    else:
        # For Non-Veg/Pescatarian, use 60% curated + 40% FoodData Central
        num_curated = min(int(num_recommendations * 0.6), len(curated_foods))
        num_fooddata = num_recommendations - num_curated
    
    recommendations = []
    
    # Add curated foods (ensure variety across meal types)
    if curated_foods:
        # Group by meal type for better distribution
        breakfast_foods = [f for f in curated_foods if f.get('meal_type') == 'breakfast']
        lunch_foods = [f for f in curated_foods if f.get('meal_type') == 'lunch']
        dinner_foods = [f for f in curated_foods if f.get('meal_type') == 'dinner']
        snack_foods = [f for f in curated_foods if f.get('meal_type') == 'snack']
        
        # Calculate foods per category (ensure at least 2 breakfast items)
        num_breakfast = max(2, int(num_curated * 0.25))  # 25% breakfast (min 2)
        num_lunch = int(num_curated * 0.3)  # 30% lunch
        num_dinner = int(num_curated * 0.3)  # 30% dinner
        num_snack = num_curated - num_breakfast - num_lunch - num_dinner  # Remaining for snacks
        
        selected_curated = []
        
        # Sample from each category
        if breakfast_foods:
            selected_curated.extend(random.sample(breakfast_foods, min(num_breakfast, len(breakfast_foods))))
        if lunch_foods:
            selected_curated.extend(random.sample(lunch_foods, min(num_lunch, len(lunch_foods))))
        if dinner_foods:
            selected_curated.extend(random.sample(dinner_foods, min(num_dinner, len(dinner_foods))))
        if snack_foods and num_snack > 0:
            selected_curated.extend(random.sample(snack_foods, min(num_snack, len(snack_foods))))
        
        # If we don't have enough, sample randomly from all
        if len(selected_curated) < num_curated:
            remaining = num_curated - len(selected_curated)
            available = [f for f in curated_foods if f not in selected_curated]
            if available:
                selected_curated.extend(random.sample(available, min(remaining, len(available))))
        
        for food in selected_curated:
            recommendations.append({
                'name': food.get('name'),
                'protein': food.get('protein', 0),
                'calories': food.get('calories', 0),
                'carbs': food.get('carbs', 0),
                'fiber': food.get('fiber', 0),
                'cuisine': food.get('cuisine', 'Indian'),
                'preparation': food.get('preparation', ''),
                'benefits': food.get('cancer_benefits', ''),
                'food_type': dietary_pref,
                'category': food.get('meal_type', 'Other').title(),  # Show meal type
                'source': 'curated'
            })
    
    # Add FoodData Central foods for variety
    if num_fooddata > 0:
        food_df, _ = load_fooddata_central()
        
        # FILTER 1: Apply allergen filtering to FoodData Central
        if allergies:
            # Same allergen expansion map as used for curated foods
            allergen_map = {
                'dairy': ['milk', 'dairy', 'cream', 'butter', 'ghee', 'cheese', 'paneer', 'curd', 'yogurt', 'dahi', 'khoya', 'mozzarella', 'cheddar', 'ricotta', 'lassi', 'raita'],
                'milk': ['milk', 'dairy', 'cream', 'butter', 'ghee'],
                'cheese': ['cheese', 'paneer', 'cheddar', 'mozzarella', 'ricotta'],
                'yogurt': ['yogurt', 'curd', 'dahi', 'lassi', 'raita'],
                'eggs': ['egg', 'omelette', 'scrambled', 'boiled egg', 'fried egg', 'omelet'],
                'egg': ['egg', 'omelette', 'scrambled', 'boiled egg', 'fried egg', 'omelet'],
                'nuts': ['nut', 'almond', 'walnut', 'cashew', 'peanut', 'hazelnut', 'pistachio', 'pecan'],
                'soy': ['soy', 'tofu', 'tempeh', 'edamame', 'soybean'],
                'gluten': ['wheat', 'bread', 'pasta', 'noodle', 'roti', 'chapati', 'barley', 'rye', 'semolina', 'maida', 'oat'],
                'wheat': ['wheat', 'bread', 'pasta', 'noodle', 'roti', 'chapati'],
                'shellfish': ['shellfish', 'shrimp', 'prawn', 'crab', 'lobster', 'clam', 'mussel', 'oyster'],
                'seafood': ['fish', 'salmon', 'tuna', 'mackerel', 'shrimp', 'prawn', 'crab', 'lobster', 'shellfish'],
                'fish': ['fish', 'salmon', 'tuna', 'mackerel', 'cod', 'tilapia'],
                'red meat': ['beef', 'pork', 'lamb', 'mutton', 'goat'],
                'poultry': ['chicken', 'turkey', 'duck']
            }
            
            expanded_allergens = []
            for allergen in allergies:
                allergen_lower = allergen.lower()
                if allergen_lower in allergen_map:
                    expanded_allergens.extend(allergen_map[allergen_lower])
                else:
                    expanded_allergens.append(allergen_lower)
            
            # Create regex pattern for allergen exclusion
            allergen_pattern = '|'.join([f'\\b{allergen}\\b' for allergen in expanded_allergens])
            food_df = food_df[~food_df['description_lower'].str.contains(allergen_pattern, na=False, regex=True)]
            print(f"After FoodData allergen filter ({allergies} -> {expanded_allergens}): {len(food_df)} foods remain")
        
        # FILTER 2: STRICT dietary filtering based on preference
        if dietary_pref == 'Jain':
            # Jain: No meat, fish, eggs, root vegetables (onion, garlic, potato, etc.)
            exclude_pattern = 'meat|chicken|beef|pork|lamb|turkey|fish|salmon|tuna|seafood|shrimp|prawn|crab|lobster|egg|bacon|sausage|ham|bologna|salami|pepperoni|onion|garlic|potato|carrot|beet|radish|ginger|turnip|sloppy joe|meatball|ground|burger|hot dog|hotdog|steak|ribs|chop'
            food_df_filtered = food_df[~food_df['description_lower'].str.contains(exclude_pattern, na=False)]
        elif dietary_pref == 'Vegan':
            # Vegan: No animal products at all
            exclude_pattern = 'meat|chicken|beef|pork|lamb|turkey|fish|salmon|tuna|seafood|shrimp|prawn|crab|lobster|egg|bacon|sausage|ham|bologna|salami|pepperoni|milk|cheese|yogurt|butter|cream|dairy|whey|casein|gelatin|honey|sloppy joe|meatball|ground|burger|hot dog|hotdog|steak|ribs|chop'
            food_df_filtered = food_df[~food_df['description_lower'].str.contains(exclude_pattern, na=False)]
        elif dietary_pref == 'Pure Veg':
            # Pure Veg: No meat, fish, eggs (dairy allowed)
            exclude_pattern = 'meat|chicken|beef|pork|lamb|turkey|fish|salmon|tuna|seafood|shrimp|prawn|crab|lobster|egg|bacon|sausage|ham|bologna|salami|pepperoni|sloppy joe|meatball|ground|burger|hot dog|hotdog|steak|ribs|chop'
            food_df_filtered = food_df[~food_df['description_lower'].str.contains(exclude_pattern, na=False)]
        elif dietary_pref == 'Veg+Egg':
            # Veg+Egg: No meat or fish (eggs and dairy allowed)
            exclude_pattern = 'meat|chicken|beef|pork|lamb|turkey|fish|salmon|tuna|seafood|shrimp|prawn|crab|lobster|bacon|sausage|ham|bologna|salami|pepperoni|sloppy joe|meatball|ground|burger|hot dog|hotdog|steak|ribs|chop'
            food_df_filtered = food_df[~food_df['description_lower'].str.contains(exclude_pattern, na=False)]
        elif dietary_pref == 'Pescatarian':
            # Pescatarian: No meat (fish, eggs, dairy allowed)
            exclude_pattern = 'chicken|beef|pork|lamb|turkey|bacon|sausage|ham|bologna|salami|pepperoni|\bmeat\b|sloppy joe|meatball|ground|burger|hot dog|hotdog|steak|ribs|chop'
            food_df_filtered = food_df[~food_df['description_lower'].str.contains(exclude_pattern, na=False)]
        else:
            # Non-Veg: All foods allowed
            food_df_filtered = food_df
        
        # Apply texture filtering for swallowing difficulties
        if eating_ability in ['difficulty_swallowing', 'very_difficult', 'difficulty swallowing', 'hard to swallow']:
            # Exclude hard/crunchy foods from FoodData Central
            exclude_hard = ['salad', 'raw', 'roasted', 'fried', 'grilled', 'crispy', 'crunchy', 
                           'whole grain', 'nuts', 'seeds', 'chips', 'crackers', 'toast', 'bread',
                           'roll', 'biscuit', 'cookie', 'granola', 'skewer', 'kebab', 'cutlet',
                           'pakora', 'samosa', 'spring roll', 'fritter', 'pumpkin seeds', 'mixed seeds',
                           'almond', 'walnut', 'cashew', 'peanut', 'pistachio', 'hazelnut', 'muffin',
                           'hazelnut', 'pecan', 'macadamia']
            
            # Create regex pattern for exclusion
            exclude_pattern = '|'.join(exclude_hard)
            food_df_filtered = food_df_filtered[~food_df_filtered['description_lower'].str.contains(exclude_pattern, na=False)]
            print(f"After FoodData texture filter: {len(food_df_filtered)} foods remain")
        
        # Sample random foods with good nutrition
        if len(food_df_filtered) > 0:
            # Prefer high protein and fiber foods
            food_df_filtered = food_df_filtered.sample(min(num_fooddata * 5, len(food_df_filtered)))
            food_df_filtered = food_df_filtered.nlargest(num_fooddata, ['protein_g', 'fiber_g'])
            
            for _, row in food_df_filtered.iterrows():
                # Double-check dietary compliance before adding
                desc_lower = row['description'].lower()
                is_compliant = True
                
                # Strict validation - check for ANY non-compliant words
                if dietary_pref == 'Jain':
                    non_compliant = ['meat', 'chicken', 'turkey', 'beef', 'pork', 'lamb', 'fish', 'salmon', 'tuna', 
                                   'egg', 'bacon', 'sausage', 'ham', 'bologna', 'salami', 'onion', 'garlic', 'potato',
                                   'sloppy joe', 'meatball', 'ground', 'burger', 'hot dog', 'hotdog', 'steak', 'ribs', 'chop']
                    if any(word in desc_lower for word in non_compliant):
                        is_compliant = False
                elif dietary_pref == 'Vegan':
                    non_compliant = ['meat', 'chicken', 'turkey', 'beef', 'pork', 'lamb', 'fish', 'salmon', 'tuna',
                                   'egg', 'bacon', 'sausage', 'ham', 'bologna', 'salami', 'milk', 'cheese', 'dairy', 'butter', 'cream', 'yogurt',
                                   'sloppy joe', 'meatball', 'ground', 'burger', 'hot dog', 'hotdog', 'steak', 'ribs', 'chop']
                    if any(word in desc_lower for word in non_compliant):
                        is_compliant = False
                elif dietary_pref == 'Pure Veg':
                    non_compliant = ['meat', 'chicken', 'turkey', 'beef', 'pork', 'lamb', 'fish', 'salmon', 'tuna',
                                   'egg', 'bacon', 'sausage', 'ham', 'bologna', 'salami', 'pepperoni',
                                   'sloppy joe', 'meatball', 'ground', 'burger', 'hot dog', 'hotdog', 'steak', 'ribs', 'chop']
                    if any(word in desc_lower for word in non_compliant):
                        is_compliant = False
                elif dietary_pref == 'Veg+Egg':
                    non_compliant = ['meat', 'chicken', 'turkey', 'beef', 'pork', 'lamb', 'fish', 'salmon', 'tuna',
                                   'bacon', 'sausage', 'ham', 'bologna', 'salami', 'pepperoni',
                                   'sloppy joe', 'meatball', 'ground', 'burger', 'hot dog', 'hotdog', 'steak', 'ribs', 'chop']
                    if any(word in desc_lower for word in non_compliant):
                        is_compliant = False
                elif dietary_pref == 'Pescatarian':
                    non_compliant = ['chicken', 'turkey', 'beef', 'pork', 'lamb', 'bacon', 'sausage', 'ham', 'bologna', 'salami',
                                   'sloppy joe', 'meatball', 'ground', 'burger', 'hot dog', 'hotdog', 'steak', 'ribs', 'chop']
                    if any(word in desc_lower for word in non_compliant):
                        is_compliant = False
                
                if is_compliant:
                    recommendations.append({
                        'name': row['description'].title(),
                        'protein': float(row.get('protein_g', 0)),
                        'calories': float(row.get('calories_kcal', 0)),
                        'carbs': 0,  # Not in basic data
                        'fiber': float(row.get('fiber_g', 0)),
                        'cuisine': 'Various',
                        'preparation': 'See nutrition label',
                        'benefits': 'Nutrient-rich food suitable for cancer patients',
                        'food_type': dietary_pref,  # Use actual preference, not auto-categorize
                        'category': 'Whole Food',
                        'source': 'fooddata_central'
                    })
    
    # Shuffle for variety
    random.shuffle(recommendations)
    
    return recommendations[:num_recommendations]
