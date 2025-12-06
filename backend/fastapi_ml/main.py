from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from typing import Optional, List, Dict
import logging
import pandas as pd
import numpy as np
from pathlib import Path
import json
import os
from dotenv import load_dotenv

# Load environment variables from root .env file
env_path = Path(__file__).resolve().parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

from models.recommendation_model import HybridRecommender, NutrientScorer
from utils.logger import setup_logger
from utils.ai_recommendations_v2 import get_diverse_food_recommendations, get_quick_nutrition_tips
from utils.curated_recommendations import get_curated_food_recommendations
from utils.ai_enhancement import enhance_recommendations_with_ai
from utils.expanded_recommendations import get_expanded_recommendations

# Setup logger
logger = setup_logger()

# Initialize FastAPI app
app = FastAPI(
    title="OncoNutri+ ML Service",
    description="ML-powered food recommendation service for cancer patients using FoodData Central",
    version="2.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for models and data
recommender = None
food_metadata = None
nutrient_matrix = None
nutrient_scorer = None

def load_models():
    """Load trained models and data on startup"""
    global recommender, food_metadata, nutrient_matrix, nutrient_scorer
    
    try:
        # Load comprehensive food database
        food_db_path = Path("../datasets/cancer_data/comprehensive_food_database.csv")
        
        if food_db_path.exists():
            logger.info("Loading comprehensive food database...")
            food_metadata = pd.read_csv(food_db_path)
            logger.info(f"Loaded {len(food_metadata)} foods (Indian + World cuisine)")
        else:
            logger.warning(f"Food database not found at {food_db_path}")
            food_metadata = None
        
        # Try to load models if they exist
        models_dir = Path("models")
        
        if models_dir.exists():
            logger.info("Loading trained recommendation models...")
            
            # Load recommender
            recommender = HybridRecommender()
            recommender.load_models(model_dir="models")
            
            # Load nutrient matrix if available
            nutrient_matrix_path = models_dir / "nutrient_matrix.parquet"
            if nutrient_matrix_path.exists():
                nutrient_matrix = pd.read_parquet(nutrient_matrix_path)
            
            logger.info(f"Models loaded successfully")
        else:
            logger.warning("Models directory not found. Using rule-based recommendations.")
        
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        logger.warning("Service will run with available data")

@app.on_event("startup")
async def startup_event():
    """Initialize models on startup"""
    load_models()

# Request/Response models
class IntakeData(BaseModel):
    """Frontend intake form data"""
    age_range: Optional[str] = None
    dietary_preference: Optional[str] = None
    cancer_type: str
    treatment_stage: str
    diagnosis_date: Optional[str] = None
    symptoms: Optional[List[str]] = []
    side_effects: Optional[List[str]] = []
    dietary_restrictions: Optional[List[str]] = []
    allergies: Optional[List[str]] = []
    activity_level: Optional[str] = None
    water_intake: Optional[str] = None
    appetite_level: Optional[str] = None
    eating_ability: Optional[str] = None
    height: Optional[float] = 170
    weight: Optional[float] = 70
    gender: Optional[str] = None
    comorbidities: Optional[List[str]] = []
    meal_preferences: Optional[Dict[str, int]] = None

class PatientProfile(BaseModel):
    cancer_type: str
    treatment_stage: str
    age: int
    weight: float
    height: Optional[float] = 170
    bmi: Optional[float] = None
    albumin: Optional[float] = 3.8
    weight_loss_pct: Optional[float] = 0
    nausea_severity: Optional[int] = 0
    taste_changes: Optional[int] = 0
    appetite_score: Optional[int] = 7
    months_since_diagnosis: Optional[float] = 6
    allergies: Optional[List[str]] = []
    symptoms: Optional[List[str]] = []
    dietary_preference: Optional[str] = None
    dietary_restrictions: Optional[List[str]] = []
    water_intake: Optional[str] = None
    appetite_level: Optional[str] = None
    eating_ability: Optional[str] = None

class FoodRecommendation(BaseModel):
    fdc_id: int
    name: str
    score: float
    content_score: float
    collab_score: float
    deep_score: float
    data_type: str
    category: Optional[str] = None
    key_nutrients: Dict[str, float]
    image_url: Optional[str] = None  # Food image URL from Google or Unsplash
    cuisine: Optional[str] = None  # Cuisine type (Indian, Chinese, etc.)
    texture: Optional[str] = None  # Food texture (Soft, Liquid, etc.)
    preparation: Optional[str] = None  # Cooking method
    benefits: Optional[str] = None  # Health benefits for cancer patients
    food_type: Optional[str] = None  # Pure Veg, Non-Veg, Vegan, etc.

class RecommendationResponse(BaseModel):
    recommendations: List[FoodRecommendation]
    patient_profile: Dict
    nutritional_guidance: Dict

class FoodSearchResult(BaseModel):
    fdc_id: int
    description: str
    data_type: str
    category: Optional[str] = None

class FoodNutritionInfo(BaseModel):
    fdc_id: int
    name: str
    data_type: str
    nutrients: Dict[str, float]
    serving_size: Optional[str] = "100g"

@app.get("/")
async def root():
    return {
        "message": "OncoNutri+ ML Service - Food Recommendation System",
        "version": "2.0.0",
        "status": "running",
        "code_version": "2025-11-26-AI-FIRST",
        "features": [
            "Personalized food recommendations",
            "FoodData Central database search",
            "Nutritional information lookup",
            "Cancer-specific dietary guidance"
        ],
        "data_status": {
            "foods_loaded": len(food_metadata) if food_metadata is not None else 0,
            "model_ready": recommender is not None
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model_loaded": recommender is not None,
        "database_loaded": food_metadata is not None
    }

@app.post("/api/recommend", response_model=RecommendationResponse)
async def get_food_recommendations(patient: PatientProfile):
    """
    Generate personalized food recommendations based on patient profile
    
    Uses AI (Google Gemini) as primary source, falling back to curated database.
    """
    try:
        logger.info(f"Generating recommendations for {patient.cancer_type} patient")
        
        # Use dietary_preference directly from patient profile
        dietary_pref = patient.dietary_preference or "Non-Veg"
        logger.info(f"Using dietary preference: {dietary_pref}")
        
        # Prepare patient profile for AI/Curated system
        patient_dict = {
            'cancer_type': patient.cancer_type,
            'treatment_stage': patient.treatment_stage,
            'dietary_preference': dietary_pref,
            'eating_ability': patient.eating_ability or 'normal',
            'appetite_level': patient.appetite_level or 'normal',
            'water_intake': patient.water_intake or 'normal',
            'nausea_severity': patient.nausea_severity or 0,
            'appetite_score': patient.appetite_score or 7,
            'allergies': patient.allergies or [],
            'symptoms': patient.symptoms or [],
            'age': patient.age,
            'weight': patient.weight
        }
        
        # [MODIFIED] EXPANDED SYSTEM: Curated (60%) + FoodData Central (40%)
        # Provides thousands of food options while maintaining quality
        logger.info(f"Generating recommendations using Expanded Database System...")
        
        # Get expanded recommendations (curated + FoodData Central)
        expanded_foods = get_expanded_recommendations(patient_dict, num_recommendations=15)
        
        recommendations = []
        
        if expanded_foods and len(expanded_foods) > 0:
            logger.info(f"[SUCCESS] Generated {len(expanded_foods)} food recommendations")
            
            # ENHANCE ALL foods with AI-powered cancer-specific benefits
            try:
                enhanced_foods = enhance_recommendations_with_ai(
                    expanded_foods, 
                    patient.cancer_type,
                    patient.treatment_stage
                )
                # Update ALL foods with AI-generated benefits
                for orig, enhanced in zip(expanded_foods, enhanced_foods):
                    orig['benefits'] = enhanced.get('cancer_specific_benefit', orig.get('benefits'))
                logger.info(f"[AI] Enhanced {len(enhanced_foods)} foods with treatment stage-specific benefits")
            except Exception as e:
                logger.warning(f"[AI] Enhancement failed: {e}. Using foods without AI enhancement.")
            
            for idx, food in enumerate(expanded_foods):
                key_nutrients = {
                    'protein': float(food.get('protein', 0) or food.get('protein_per_100g', 0)),
                    'energy': float(food.get('calories', 0) or food.get('calories_per_100g', 0)),
                    'carbs': float(food.get('carbs', 0)),
                    'fiber': float(food.get('fiber', 0))
                }
                
                # Calculate dynamic scores based on nutritional content
                protein_score = min(key_nutrients['protein'] / 20.0, 1.0)  # Normalize to 20g
                fiber_score = min(key_nutrients['fiber'] / 10.0, 1.0)  # Normalize to 10g
                calorie_score = min(key_nutrients['energy'] / 350.0, 1.0)  # Normalize to 350 kcal
                
                # Content score: weighted nutritional quality
                content_score = (protein_score * 0.4 + fiber_score * 0.3 + calorie_score * 0.3)
                
                # Collab score: based on food type match and AI enhancement
                has_ai_benefit = 'cancer_specific_benefit' in food
                collab_score = 0.85 + (0.1 if has_ai_benefit else 0.0) + (0.05 if food.get('food_type') == dietary_pref else 0.0)
                
                # Deep score: cancer-specific suitability
                is_wholesome = any(keyword in food.get('name', '').lower() for keyword in ['whole', 'brown', 'grain', 'vegetable', 'fruit', 'dal', 'lentil'])
                deep_score = 0.80 + (0.15 if is_wholesome else 0.0) + (0.05 if key_nutrients['fiber'] >= 5 else 0.0)
                
                # Overall score: average of all scores
                overall_score = (content_score + collab_score + deep_score) / 3.0
                
                # Generate Unsplash image URL if missing
                image_url = food.get('image_url')
                if not image_url:
                    food_name = food['name'].replace(' ', '+').replace('(', '').replace(')', '').replace('/', '')
                    image_url = f"https://source.unsplash.com/400x300/?{food_name},food,dish,meal"
                
                # Use AI-enhanced benefit if available, otherwise use generic
                benefits = food.get('cancer_specific_benefit', food.get('benefits', 'Nutrient-rich food for cancer patients'))
                
                recommendations.append(FoodRecommendation(
                    fdc_id=2000000 + idx,
                    name=food.get('name', 'Unknown'),
                    score=round(overall_score, 2),
                    content_score=round(content_score, 2),
                    collab_score=round(collab_score, 2),
                    deep_score=round(deep_score, 2),
                    data_type='curated_database_ai_enhanced',
                    category=food.get('category', 'Other'),
                    key_nutrients=key_nutrients,
                    image_url=image_url,
                    cuisine=food.get('cuisine'),
                    texture='Various',
                    preparation=food.get('preparation'),
                    benefits=benefits,
                    food_type=food.get('food_type') or dietary_pref
                ))
        else:
            logger.error("[CRITICAL] Curated system failed to return recommendations.")
            raise HTTPException(status_code=503, detail="Unable to generate recommendations from database.")

        # Return the response
        if len(recommendations) > 0:
            # Calculate nutritional needs
            protein_need = calculate_protein_need(patient)
            calorie_need = calculate_calorie_need(patient)
            
            # Generate guidance
            guidance_tips = [
                f"Target: {protein_need:.0f}g protein and {calorie_need:.0f} calories daily",
            ]
            
            if patient.eating_ability:
                ability_tips = {
                    'liquids_only': 'All foods are liquid/drinkable - no chewing required',
                    'soft_only': 'All foods are very soft - minimal chewing needed',
                    'reduced': 'Eat small, frequent meals throughout the day',
                    'normal': 'Enjoy a variety of nutritious foods'
                }
                guidance_tips.append(ability_tips.get(patient.eating_ability, 'Eat balanced meals'))
            
            try:
                ai_tips = get_quick_nutrition_tips(patient_dict)
                if ai_tips:
                    guidance_tips.extend(ai_tips[:3])
            except:
                pass
            
            guidance_tips.append("Stay well hydrated - aim for 8-10 glasses of water")
            
            return RecommendationResponse(
                recommendations=recommendations,
                patient_profile={
                    "cancer_type": patient.cancer_type,
                    "treatment_stage": patient.treatment_stage,
                    "age": patient.age,
                    "dietary_preference": dietary_pref,
                    "eating_ability": patient.eating_ability or 'normal'
                },
                nutritional_guidance={
                    "protein_need_g": protein_need,
                    "calorie_need_kcal": calorie_need,
                    "recommendations": guidance_tips
                }
            )
        else:
             raise HTTPException(status_code=503, detail="No recommendations generated")

    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        import traceback
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/food/search")
async def search_foods(
    query: str = Query(..., min_length=2, description="Search query"),
    limit: int = Query(20, ge=1, le=100, description="Maximum results")
):
    """
    Search for foods in FoodData Central database
    """
    try:
        if food_metadata is None:
            raise HTTPException(status_code=503, detail="Food database not loaded")
        
        # Case-insensitive search
        mask = food_metadata['description'].str.contains(query, case=False, na=False)
        results = food_metadata[mask].head(limit)
        
        search_results = [
            FoodSearchResult(
                fdc_id=int(row['fdc_id']),
                description=row['description'],
                data_type=row['data_type'],
                category=None
            )
            for _, row in results.iterrows()
        ]
        
        return {
            "query": query,
            "count": len(search_results),
            "results": search_results
        }
        
    except Exception as e:
        logger.error(f"Error searching foods: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/food/{fdc_id}", response_model=FoodNutritionInfo)
async def get_food_nutrition(fdc_id: int):
    """
    Get detailed nutritional information for a specific food
    """
    try:
        if food_metadata is None or nutrient_matrix is None:
            raise HTTPException(status_code=503, detail="Database not loaded")
        
        # Get food info
        food_info = food_metadata[food_metadata['fdc_id'] == fdc_id]
        
        if food_info.empty:
            raise HTTPException(status_code=404, detail="Food not found")
        
        food_info = food_info.iloc[0]
        
        # Get nutrients
        if fdc_id in nutrient_matrix.index:
            nutrients = nutrient_matrix.loc[fdc_id].to_dict()
            # Convert to standard types and filter non-zero
            nutrients = {k: float(v) for k, v in nutrients.items() if v > 0}
        else:
            nutrients = {}
        
        return FoodNutritionInfo(
            fdc_id=fdc_id,
            name=food_info['description'],
            data_type=food_info['data_type'],
            nutrients=nutrients,
            serving_size="100g"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting food nutrition: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/guidelines/{cancer_type}")
async def get_cancer_guidelines(cancer_type: str):
    """
    Get nutritional guidelines for specific cancer type
    """
    try:
        with open("data/cancer_nutrition_guidelines.json", 'r') as f:
            guidelines = json.load(f)
        
        if cancer_type not in guidelines['cancer_types']:
            raise HTTPException(status_code=404, detail="Cancer type not found")
        
        return guidelines['cancer_types'][cancer_type]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting guidelines: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/feedback")
async def submit_feedback(
    patient_id: str,
    fdc_id: int,
    rating: int = Query(..., ge=1, le=5),
    comments: str = ""
):
    """
    Submit feedback on food recommendations for model improvement
    """
    try:
        logger.info(f"Feedback: patient={patient_id}, food={fdc_id}, rating={rating}")
        
        # In production, save to database for model retraining
        feedback_data = {
            "patient_id": patient_id,
            "fdc_id": fdc_id,
            "rating": rating,
            "comments": comments,
            "timestamp": pd.Timestamp.now().isoformat()
        }
        
        # TODO: Save to database
        
        return {
            "message": "Feedback recorded successfully",
            "data": feedback_data
        }
        
    except Exception as e:
        logger.error(f"Error recording feedback: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Helper functions
def calculate_protein_need(patient: PatientProfile) -> float:
    """Calculate protein needs in grams per day"""
    base_protein = 1.2 * patient.weight
    
    if patient.treatment_stage == 'chemotherapy':
        base_protein *= 1.15
    elif patient.treatment_stage == 'post_surgery':
        base_protein *= 1.25
    
    return base_protein

def calculate_calorie_need(patient: PatientProfile) -> float:
    """Calculate calorie needs in kcal per day"""
    bmi = patient.bmi or 25
    
    if bmi < 18.5:
        kcal_per_kg = 35
    elif bmi > 25:
        kcal_per_kg = 25
    else:
        kcal_per_kg = 30
    
    if patient.treatment_stage == 'chemotherapy':
        kcal_per_kg *= 1.1
    elif patient.treatment_stage == 'post_surgery':
        kcal_per_kg *= 1.15
    
    return kcal_per_kg * patient.weight

def get_nutritional_guidance(cancer_type: str, treatment_stage: str) -> Dict:
    """Get nutritional guidance for patient"""
    try:
        with open("data/cancer_nutrition_guidelines.json", 'r') as f:
            guidelines = json.load(f)
        
        cancer_guidelines = guidelines['cancer_types'].get(cancer_type, {})
        treatment_guidelines = guidelines['treatment_stage_adjustments'].get(treatment_stage, {})
        
        return {
            "cancer_specific": {
                "recommended_nutrients": cancer_guidelines.get('recommended_nutrients', {}),
                "recommended_foods": cancer_guidelines.get('recommended_foods', []),
                "avoid_foods": cancer_guidelines.get('avoid_foods', [])
            },
            "treatment_specific": {
                "increased_needs": treatment_guidelines.get('increased_needs', []),
                "dietary_modifications": treatment_guidelines.get('dietary_modifications', [])
            },
            "general_tips": [
                "Eat small, frequent meals throughout the day",
                "Stay well hydrated",
                "Choose nutrient-dense foods",
                "Listen to your body and adjust as needed"
            ]
        }
    except:
        return {}

@app.get("/api/dashboard/overview")
async def get_dashboard_overview():
    """Dashboard overview endpoint for frontend"""
    return {
        "overview": {
            "dietPlanStatus": "Active",
            "progressPercentage": 75,
            "hasDietPlan": True,
            "totalProgressEntries": 12,
            "lastEntryDate": "2025-12-01"
        },
        "tips": [
            {
                "icon": "🥦",
                "title": "Stay Hydrated",
                "description": "Drink at least 8 glasses of water daily to help your body process nutrients"
            },
            {
                "icon": "apple",
                "title": "Eat Small Meals",
                "description": "Try eating 5-6 small meals instead of 3 large ones for better nutrient absorption"
            },
            {
                "icon": "muscle",
                "title": "Light Exercise",
                "description": "Gentle walks or stretching can help improve appetite and energy levels"
            }
        ],
        "profile": {
            "cancerType": "Breast Cancer",
            "stage": "Stage II",
            "age": 45
        }
    }

@app.post("/api/recommendations", response_model=RecommendationResponse)
async def get_recommendations_alias(intake: IntakeData):
    """
    Frontend-compatible endpoint that accepts IntakeData format
    Converts to PatientProfile and calls main recommendation engine
    """
    # Parse age from age_range
    age = 40  # default
    if intake.age_range:
        try:
            age = int(intake.age_range.split('-')[0])
        except:
            age = 40
    
    # Convert IntakeData to PatientProfile
    patient = PatientProfile(
        cancer_type=intake.cancer_type,
        treatment_stage=intake.treatment_stage,
        age=age,
        weight=intake.weight or 70,
        height=intake.height or 170,
        allergies=intake.allergies or [],
        symptoms=intake.symptoms or [],
        dietary_preference=intake.dietary_preference,
        dietary_restrictions=intake.dietary_restrictions or [],
        water_intake=intake.water_intake,
        appetite_level=intake.appetite_level,
        eating_ability=intake.eating_ability
    )
    
    return await get_food_recommendations(patient)

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
