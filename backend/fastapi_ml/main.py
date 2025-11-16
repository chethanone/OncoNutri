from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from typing import Optional, List
import logging

from models.recommender import DietRecommender
from utils.preprocessor import preprocess_patient_data
from utils.logger import setup_logger

# Setup logger
logger = setup_logger()

# Initialize FastAPI app
app = FastAPI(
    title="OncoNutri+ ML Service",
    description="ML-powered diet recommendation service for cancer patients",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize ML model
recommender = DietRecommender()

# Request/Response models
class PatientData(BaseModel):
    age: int
    weight: float
    cancer_type: str
    stage: str
    allergies: Optional[str] = ""
    other_conditions: Optional[str] = ""

class DietRecommendation(BaseModel):
    breakfast: List[str]
    lunch: List[str]
    dinner: List[str]
    snacks: List[str]
    notes: Optional[str] = None

@app.get("/")
async def root():
    return {
        "message": "OncoNutri+ ML Service",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/recommend", response_model=DietRecommendation)
async def get_recommendation(patient_data: PatientData):
    """
    Generate personalized diet recommendation based on patient data
    """
    try:
        logger.info(f"Generating recommendation for cancer type: {patient_data.cancer_type}")
        
        # Preprocess patient data
        processed_data = preprocess_patient_data(patient_data.dict())
        
        # Generate recommendation using ML model
        recommendation = recommender.generate_recommendation(processed_data)
        
        logger.info("Recommendation generated successfully")
        return recommendation
        
    except Exception as e:
        logger.error(f"Error generating recommendation: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/feedback")
async def submit_feedback(patient_id: int, recommendation_id: int, rating: int, comments: str = ""):
    """
    Submit feedback for model improvement
    """
    try:
        logger.info(f"Feedback received for recommendation {recommendation_id}")
        # Store feedback for future model retraining
        return {"message": "Feedback recorded successfully"}
    except Exception as e:
        logger.error(f"Error recording feedback: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
