from typing import Dict

def preprocess_patient_data(data: Dict) -> Dict:
    """
    Preprocess patient data for ML model input.
    Handles data cleaning, normalization, and feature engineering.
    """
    processed = data.copy()
    
    # Normalize cancer type
    processed["cancer_type"] = processed["cancer_type"].lower().strip()
    
    # Normalize stage
    processed["stage"] = processed["stage"].lower().strip()
    
    # Clean allergies
    if processed.get("allergies"):
        processed["allergies"] = processed["allergies"].lower().strip()
    else:
        processed["allergies"] = ""
    
    # Clean other conditions
    if processed.get("other_conditions"):
        processed["other_conditions"] = processed["other_conditions"].lower().strip()
    else:
        processed["other_conditions"] = ""
    
    # Calculate BMI
    height_m = 1.65  # Default height in meters (165 cm)
    # In production, height should be part of patient data
    processed["bmi"] = processed["weight"] / (height_m ** 2)
    
    # Categorize BMI
    bmi = processed["bmi"]
    if bmi < 18.5:
        processed["weight_category"] = "underweight"
    elif 18.5 <= bmi < 25:
        processed["weight_category"] = "normal"
    elif 25 <= bmi < 30:
        processed["weight_category"] = "overweight"
    else:
        processed["weight_category"] = "obese"
    
    # Extract stage number
    stage_mapping = {
        "stage i": 1,
        "stage 1": 1,
        "stage ii": 2,
        "stage 2": 2,
        "stage iii": 3,
        "stage 3": 3,
        "stage iv": 4,
        "stage 4": 4,
    }
    processed["stage_number"] = stage_mapping.get(processed["stage"], 0)
    
    return processed

def extract_features(processed_data: Dict) -> Dict:
    """
    Extract features for ML model prediction.
    In production, this would create feature vectors for the model.
    """
    features = {
        "age": processed_data["age"],
        "weight": processed_data["weight"],
        "bmi": processed_data["bmi"],
        "stage_number": processed_data["stage_number"],
        "cancer_type_encoded": _encode_cancer_type(processed_data["cancer_type"]),
        "has_allergies": 1 if processed_data["allergies"] else 0,
        "has_conditions": 1 if processed_data["other_conditions"] else 0,
    }
    
    return features

def _encode_cancer_type(cancer_type: str) -> int:
    """Encode cancer type to numerical value"""
    cancer_type_map = {
        "breast cancer": 1,
        "lung cancer": 2,
        "colorectal cancer": 3,
        "prostate cancer": 4,
        "stomach cancer": 5,
        "liver cancer": 6,
        "other": 7,
    }
    return cancer_type_map.get(cancer_type, 7)
