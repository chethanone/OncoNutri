"""
Hybrid Food Recommendation Model for Cancer Patients
Combines:
1. Content-based filtering (clinical guidelines)
2. Collaborative filtering (NMF)
3. Deep learning (neural network)
"""
import numpy as np
import pandas as pd
import logging
from typing import Dict, List
from pathlib import Path
import os
import json

from sklearn.decomposition import NMF
from sklearn.preprocessing import StandardScaler
from scipy.sparse import csr_matrix

# Try to import tensorflow, but don't fail if not available
try:
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    logger = logging.getLogger(__name__)
    logger.warning("TensorFlow not available, deep learning features disabled")

logger = logging.getLogger(__name__)


class NutrientScorer:
    """Content-based scoring using cancer nutrition guidelines"""
    
    def __init__(self):
        # Load comprehensive cancer nutrition guidelines
        guidelines_path = Path(__file__).parent.parent / "data" / "cancer_nutrition_guidelines_comprehensive.json"
        
        if not guidelines_path.exists():
            # Fallback to simple guidelines
            guidelines_path = Path(__file__).parent.parent / "data" / "cancer_nutrition_guidelines.json"
        
        with open(guidelines_path, 'r') as f:
            self.guidelines = json.load(f)
        
        self.cancer_types = self.guidelines.get('cancer_types', {})
    
    def score_food(self, food_nutrients: Dict, patient_profile: Dict) -> float:
        """
        Score a food based on cancer type guidelines
        Returns score between 0-1
        """
        cancer_type = patient_profile.get('cancer_type', 'general')
        treatment_stage = patient_profile.get('treatment_stage', 'general')
        
        # Get guidelines for this cancer type
        if cancer_type in self.cancer_types:
            cancer_guidelines = self.cancer_types[cancer_type]
        else:
            cancer_guidelines = self.cancer_types.get('general', {})
        
        # Get nutrients to prioritize and avoid
        beneficial = cancer_guidelines.get('recommended_nutrients', [])
        avoid = cancer_guidelines.get('nutrients_to_limit', [])
        
        score = 0.5  # Start neutral
        
        # Boost score for beneficial nutrients
        for nutrient in beneficial:
            if nutrient in food_nutrients and food_nutrients[nutrient] > 0:
                score += 0.1
        
        # Reduce score for nutrients to avoid
        for nutrient in avoid:
            if nutrient in food_nutrients and food_nutrients[nutrient] > 0:
                score -= 0.15
        
        # Ensure score is between 0 and 1
        return np.clip(score, 0, 1)


class HybridRecommender:
    """
    Hybrid recommendation system combining:
    - Content-based (NutrientScorer)
    - Collaborative filtering (NMF)
    - Deep learning (Neural Network)
    """
    
    def __init__(self, n_latent_factors=50):
        self.n_latent_factors = n_latent_factors
        self.nutrient_scorer = NutrientScorer()
        
        # Models (will be trained)
        self.nmf_model = None
        self.nmf_W = None  # Patient latent factors
        self.nmf_H = None  # Food latent factors
        self.deep_model = None
        self.scaler = None
        
        # Data
        self.food_df = None
        self.nutrient_matrix = None
        self.patient_encodings = {}
        
        logger.info("Hybrid recommender initialized")
    
    def prepare_data(self, food_df: pd.DataFrame, nutrient_matrix: pd.DataFrame, 
                    patients, preferences):
        """Prepare data for training (accepts both DataFrame and list of dicts)"""
        logger.info("Preparing data for training...")
        
        self.food_df = food_df
        self.nutrient_matrix = nutrient_matrix
        
        # Convert DataFrames to lists of dicts if needed
        if isinstance(patients, pd.DataFrame):
            patients = patients.to_dict('records')
        if isinstance(preferences, pd.DataFrame):
            preferences = preferences.to_dict('records')
        
        # Build patient index
        self.patient_index = {p['patient_id']: i for i, p in enumerate(patients)}
        self.food_index = {fid: i for i, fid in enumerate(food_df['fdc_id'])}
        
        # Store for later use
        self.patients = patients
        self.preferences = preferences
        
        logger.info(f"Data prepared: {len(food_df)} foods, {len(patients)} patients")
    
    def train_nmf(self):
        """Train Non-negative Matrix Factorization model"""
        logger.info("Training NMF model...")
        
        # Build sparse preference matrix
        n_patients = len(self.patient_index)
        n_foods = len(self.food_index)
        
        rows = []
        cols = []
        data = []
        
        for pref in self.preferences:
            if pref['patient_id'] in self.patient_index and pref['fdc_id'] in self.food_index:
                rows.append(self.patient_index[pref['patient_id']])
                cols.append(self.food_index[pref['fdc_id']])
                # Handle both 'rating' and 'preference_score' column names
                score = pref.get('rating') or pref.get('preference_score', 0.5)
                data.append(score)
        
        preference_matrix = csr_matrix((data, (rows, cols)), shape=(n_patients, n_foods))
        
        logger.info(f"Training on sparse matrix: {preference_matrix.shape} with {len(data):,} non-zero values")
        
        # Train NMF
        self.nmf_model = NMF(
            n_components=self.n_latent_factors,
            init='random',
            random_state=42,
            max_iter=200,
            alpha_W=0.1,
            alpha_H=0.1,
            l1_ratio=0.5
        )
        
        self.nmf_W = self.nmf_model.fit_transform(preference_matrix)
        self.nmf_H = self.nmf_model.components_
        
        # Calculate reconstruction error
        reconstructed = self.nmf_W @ self.nmf_H
        sample_error = np.mean((preference_matrix.toarray()[0] - reconstructed[0]) ** 2)
        logger.info(f"NMF reconstruction error (sample): {sample_error:.4f}")
    
    def _encode_patient(self, patient: Dict) -> np.ndarray:
        """Encode patient profile into feature vector"""
        features = []
        
        # Categorical features (one-hot or label encoded)
        cancer_types = ['breast', 'lung', 'colorectal', 'prostate', 'stomach', 'liver', 'oral', 'other']
        cancer_encoding = [1 if patient.get('cancer_type', '').lower() == ct else 0 for ct in cancer_types]
        features.extend(cancer_encoding)
        
        treatment_stages = ['pre_treatment', 'during_treatment', 'post_treatment', 'maintenance']
        treatment_encoding = [1 if patient.get('treatment_stage', '').lower() == ts else 0 for ts in treatment_stages]
        features.extend(treatment_encoding)
        
        # Numerical features
        features.append(patient.get('age', 50) / 100.0)  # Normalize
        features.append(patient.get('weight', 70) / 150.0)
        features.append(patient.get('bmi', 22) / 40.0)
        features.append(patient.get('albumin', 4.0) / 6.0)
        features.append(patient.get('weight_loss_pct', 0) / 20.0)
        features.append(patient.get('nausea_severity', 0) / 10.0)
        features.append(patient.get('taste_changes', 0))
        features.append(patient.get('appetite_score', 5) / 10.0)
        features.append(patient.get('protein_need_g', 60) / 150.0)
        features.append(patient.get('calorie_need_kcal', 2000) / 3000.0)
        features.append(patient.get('months_since_diagnosis', 0) / 60.0)
        
        return np.array(features, dtype=np.float32)
    
    def _prepare_deep_training_data(self):
        """Prepare training data for deep learning model (VECTORIZED)"""
        logger.info("Encoding patient features (vectorized)...")
        
        # Encode all patients at once
        patient_features = np.array([self._encode_patient(p) for p in self.patients])
        
        logger.info(f"Filtering {len(self.preferences):,} preferences...")
        
        # Filter valid preferences
        valid_prefs = [
            p for p in self.preferences
            if p['patient_id'] in self.patient_index and p['fdc_id'] in self.food_index
        ]
        
        logger.info(f"Building training samples from {len(valid_prefs):,} valid preferences (vectorized)...")
        
        # Vectorized data preparation
        patient_indices = np.array([self.patient_index[p['patient_id']] for p in valid_prefs])
        food_indices = np.array([self.food_index[p['fdc_id']] for p in valid_prefs])
        # Handle both 'rating' and 'preference_score' column names
        scores = np.array([p.get('rating') or p.get('preference_score', 0.5) for p in valid_prefs], dtype=np.float32)
        
        # Get features using vectorized indexing
        X_patient = patient_features[patient_indices]
        X_food = self.nutrient_matrix.values[food_indices]
        y = scores
        
        logger.info(f"Prepared {len(X_patient):,} training samples")
        
        return X_patient, X_food, y
    
    def train_deep_model(self, epochs=10, batch_size=256):
        """Train deep neural network"""
        if not TF_AVAILABLE:
            logger.warning("TensorFlow not available, skipping deep model training")
            return None
            
        logger.info("Training deep neural network...")
        
        # Prepare data
        X_patient, X_food, y = self._prepare_deep_training_data()
        
        # Build model
        n_patient_features = X_patient.shape[1]
        n_food_features = X_food.shape[1]
        
        # Patient branch
        patient_input = layers.Input(shape=(n_patient_features,), name='patient_input')
        patient_dense = layers.Dense(64, activation='relu')(patient_input)
        patient_dense = layers.Dropout(0.3)(patient_dense)
        patient_dense = layers.Dense(32, activation='relu')(patient_dense)
        
        # Food branch
        food_input = layers.Input(shape=(n_food_features,), name='food_input')
        food_dense = layers.Dense(128, activation='relu')(food_input)
        food_dense = layers.Dropout(0.3)(food_dense)
        food_dense = layers.Dense(64, activation='relu')(food_dense)
        food_dense = layers.Dense(32, activation='relu')(food_dense)
        
        # Combine
        combined = layers.concatenate([patient_dense, food_dense])
        combined = layers.Dense(64, activation='relu')(combined)
        combined = layers.Dropout(0.2)(combined)
        combined = layers.Dense(32, activation='relu')(combined)
        output = layers.Dense(1, activation='sigmoid', name='output')(combined)
        
        self.deep_model = keras.Model(inputs=[patient_input, food_input], outputs=output)
        
        self.deep_model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae']
        )
        
        # Train
        history = self.deep_model.fit(
            [X_patient, X_food],
            y,
            epochs=epochs,
            batch_size=batch_size,
            validation_split=0.2,
            verbose=1
        )
        
        logger.info("Deep model training complete")
        
        return history
    
    def get_recommendations(self, patient: Dict, n_recommendations=20) -> List[Dict]:
        """
        Get top N food recommendations for a patient (FAST VERSION - <1 second)
        """
        # Encode patient once
        patient_features = self._encode_patient(patient).reshape(1, -1)
        
        n_foods = len(self.food_df)
        n_candidates = min(500, n_foods)  # Don't exceed available foods
        
        # OPTIMIZATION 1: Pre-filter to top candidates using NMF only (fast)
        if self.nmf_W is not None and self.nmf_H.shape[1] == n_foods:
            avg_patient_factors = np.mean(self.nmf_W, axis=0)
            collab_scores_all = avg_patient_factors @ self.nmf_H
            # Ensure indices are within bounds
            top_indices = np.argsort(collab_scores_all)[-n_candidates:]
            top_indices = top_indices[top_indices < len(self.nutrient_matrix)]  # Safety check
        else:
            # If no NMF or size mismatch, take top N foods by index
            top_indices = np.arange(min(n_candidates, len(self.nutrient_matrix)))
            collab_scores_all = np.ones(n_foods) * 0.5
        
        # OPTIMIZATION 2: Batch predict deep scores (much faster than loop)
        if self.deep_model is not None and len(top_indices) > 0:
            # Prepare batch safely
            food_features_batch = self.nutrient_matrix.iloc[top_indices.tolist()].values
            patient_features_batch = np.repeat(patient_features, len(top_indices), axis=0)
            
            # Single batch prediction (FAST!)
            deep_scores = self.deep_model.predict(
                [patient_features_batch, food_features_batch], 
                verbose=0,
                batch_size=512
            ).flatten()
        else:
            deep_scores = np.ones(len(top_indices)) * 0.5
        
        # OPTIMIZATION 3: Vectorized content scoring
        content_scores = np.array([
            self.nutrient_scorer.score_food(
                self.nutrient_matrix.iloc[idx].to_dict(), 
                patient
            ) for idx in top_indices
        ])
        
        # Get collab scores for top candidates
        if self.nmf_W is not None and self.nmf_H.shape[1] == n_foods:
            collab_scores = collab_scores_all[top_indices]
        else:
            collab_scores = np.ones(len(top_indices)) * 0.5
        
        # Normalize scores to 0-1
        content_scores = (content_scores - content_scores.min()) / (content_scores.max() - content_scores.min() + 1e-8)
        collab_scores = (collab_scores - collab_scores.min()) / (collab_scores.max() - collab_scores.min() + 1e-8)
        deep_scores = (deep_scores - deep_scores.min()) / (deep_scores.max() - deep_scores.min() + 1e-8)
        
        # Weighted combination
        final_scores = (
            0.30 * content_scores +  # Clinical guidelines
            0.30 * collab_scores +   # Similar patient preferences
            0.40 * deep_scores       # Deep learning patterns
        )
        
        # Get top N from the candidates
        top_n_indices = np.argsort(final_scores)[-min(n_recommendations, len(final_scores)):][::-1]
        
        recommendations = []
        for i in top_n_indices:
            actual_idx = int(top_indices[i])
            recommendations.append({
                'fdc_id': int(self.food_df.iloc[actual_idx]['fdc_id']),
                'score': float(final_scores[i]),
                'content_score': float(content_scores[i]),
                'collab_score': float(collab_scores[i]),
                'deep_score': float(deep_scores[i])
            })
        
        return recommendations
    
    def save_models(self, model_dir: str = "models"):
        """Save all trained models"""
        model_path = Path(model_dir)
        model_path.mkdir(exist_ok=True)
        
        # Save NMF
        if self.nmf_model is not None:
            import joblib
            joblib.dump(self.nmf_model, model_path / "nmf_model.pkl")
            np.save(model_path / "nmf_W.npy", self.nmf_W)
            np.save(model_path / "nmf_H.npy", self.nmf_H)
        
        # Save deep model
        if self.deep_model is not None:
            self.deep_model.save(model_path / "deep_model.h5")
            self.deep_model.save(model_path / "deep_model.keras")
        
        # Save mappings
        import joblib
        joblib.dump({
            'patient_index': self.patient_index,
            'food_index': self.food_index
        }, model_path / "mappings.pkl")
        
        logger.info("Models saved")
    
    def load_models(self, model_dir: str = "models"):
        """Load previously trained models"""
        model_path = Path(model_dir)
        
        # Load NMF
        import joblib
        self.nmf_model = joblib.load(model_path / "nmf_model.pkl")
        self.nmf_W = np.load(model_path / "nmf_W.npy")
        self.nmf_H = np.load(model_path / "nmf_H.npy")
        
        # Load deep model only if TensorFlow is available
        if TF_AVAILABLE:
            self.deep_model = keras.models.load_model(model_path / "deep_model.keras")
        else:
            logger.warning("TensorFlow not available, skipping deep model loading")
            self.deep_model = None
        
        # Load mappings
        mappings = joblib.load(model_path / "mappings.pkl")
        self.patient_index = mappings['patient_index']
        self.food_index = mappings['food_index']
        
        logger.info("Models loaded")
