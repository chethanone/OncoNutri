# OncoNutri+ FastAPI ML Service

FastAPI-based machine learning service for generating personalized diet recommendations.

## Features

- ML-powered diet recommendations
- Cancer-type specific meal planning
- Allergen filtering
- BMI-based nutritional adjustments
- RESTful API endpoints
- Feedback collection for model improvement

## Getting Started

### Prerequisites

- Python 3.8 or higher
- pip or conda

### Installation

1. Create a virtual environment:
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Create logs directory:
```bash
mkdir logs
```

5. Run the service:
```bash
# Development mode with auto-reload
python main.py

# Or using uvicorn directly
uvicorn main:app --reload --port 8000
```

## API Endpoints

### Health Check
```
GET /health
```

### Generate Recommendation
```
POST /recommend
Content-Type: application/json

{
  "age": 45,
  "weight": 70.5,
  "cancer_type": "Breast Cancer",
  "stage": "Stage II",
  "allergies": "peanuts, shellfish",
  "other_conditions": "diabetes"
}
```

Response:
```json
{
  "breakfast": ["Greek yogurt with berries", "..."],
  "lunch": ["Grilled chicken with quinoa", "..."],
  "dinner": ["Baked salmon with vegetables", "..."],
  "snacks": ["Fresh fruit salad", "..."],
  "notes": "Stay hydrated. Include antioxidant-rich foods..."
}
```

### Submit Feedback
```
POST /feedback
Content-Type: application/json

{
  "patient_id": 123,
  "recommendation_id": 456,
  "rating": 5,
  "comments": "Very helpful recommendations"
}
```

## Project Structure

```
fastapi_ml/
├── main.py                   # FastAPI application entry point
├── models/                   # ML models and recommender logic
│   └── recommender.py
├── utils/                    # Utility functions
│   ├── preprocessor.py
│   └── logger.py
├── logs/                     # Log files
├── requirements.txt          # Python dependencies
└── README.md
```

## ML Model

The current implementation uses a rule-based system as a placeholder. In production:

1. **Data Collection**: Gather patient data, dietary preferences, and outcomes
2. **Model Training**: Train ML models (Random Forest, Neural Networks, etc.)
3. **Model Deployment**: Replace rule-based logic with trained model
4. **Continuous Learning**: Retrain models with feedback data

## Development

### Running Tests
```bash
pytest
```

### API Documentation
Once the service is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Deployment

### Docker
```bash
docker build -t onconutri-ml .
docker run -p 8000:8000 onconutri-ml
```

### Production Considerations
- Use a production ASGI server (Gunicorn with Uvicorn workers)
- Implement authentication and rate limiting
- Set up monitoring and logging
- Use a model serving framework (TensorFlow Serving, TorchServe)

## License

This project is part of the OncoNutri+ healthcare application.
