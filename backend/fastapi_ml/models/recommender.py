import numpy as np
from typing import Dict, List
import json
import os

class DietRecommender:
    """
    ML-based diet recommendation system for cancer patients.
    This is a placeholder that can be replaced with a trained ML model.
    """
    
    def __init__(self):
        self.food_database = self._load_food_database()
        
    def _load_food_database(self) -> Dict:
        """Load food database with nutritional information"""
        # In production, this would load from a database or file
        return {
            "breakfast": {
                "high_protein": [
                    "Greek yogurt with berries and honey",
                    "Scrambled eggs with whole wheat toast",
                    "Oatmeal with nuts and banana",
                    "Protein smoothie with spinach and fruits",
                    "Quinoa porridge with almond milk"
                ],
                "easy_digest": [
                    "Banana and almond butter",
                    "White rice porridge with ginger",
                    "Steamed idli with coconut chutney",
                    "Plain yogurt with honey"
                ],
                "general": [
                    "Whole grain cereal with milk",
                    "Avocado toast with poached egg",
                    "Smoothie bowl with granola"
                ]
            },
            "lunch": {
                "high_protein": [
                    "Grilled chicken with quinoa and vegetables",
                    "Baked salmon with sweet potato",
                    "Lentil soup with whole grain bread",
                    "Tofu stir-fry with brown rice",
                    "Chickpea curry with roti"
                ],
                "vegetarian": [
                    "Mixed vegetable curry with rice",
                    "Spinach and paneer with roti",
                    "Vegetable biryani with raita",
                    "Dal tadka with steamed rice"
                ],
                "general": [
                    "Grilled fish with roasted vegetables",
                    "Turkey sandwich on whole wheat",
                    "Vegetable pasta with olive oil"
                ]
            },
            "dinner": {
                "light": [
                    "Vegetable soup with whole grain crackers",
                    "Grilled chicken breast with steamed broccoli",
                    "Baked fish with asparagus",
                    "Stir-fried tofu with vegetables"
                ],
                "moderate": [
                    "Chicken curry with brown rice",
                    "Grilled salmon with quinoa",
                    "Lentil dal with roti and salad",
                    "Turkey meatballs with whole wheat pasta"
                ],
                "general": [
                    "Mixed vegetable khichdi",
                    "Grilled chicken wrap",
                    "Fish tacos with whole wheat tortillas"
                ]
            },
            "snacks": {
                "healthy": [
                    "Fresh fruit salad",
                    "Mixed nuts (almonds, walnuts, cashews)",
                    "Hummus with carrot and cucumber sticks",
                    "Greek yogurt with berries",
                    "Apple slices with peanut butter",
                    "Roasted chickpeas",
                    "Trail mix with dried fruits"
                ]
            }
        }
    
    def generate_recommendation(self, patient_data: Dict) -> Dict:
        """
        Generate personalized diet recommendation based on patient data.
        In production, this would use a trained ML model.
        """
        cancer_type = patient_data.get("cancer_type", "").lower()
        stage = patient_data.get("stage", "").lower()
        weight = patient_data.get("weight", 70)
        allergies = patient_data.get("allergies", "").lower()
        
        # Rule-based recommendation (placeholder for ML model)
        recommendation = {
            "breakfast": [],
            "lunch": [],
            "dinner": [],
            "snacks": [],
            "notes": ""
        }
        
        # Select breakfast items
        if "stomach" in cancer_type or "gastric" in cancer_type:
            recommendation["breakfast"] = self._select_items(
                self.food_database["breakfast"]["easy_digest"], 3, allergies
            )
        else:
            recommendation["breakfast"] = self._select_items(
                self.food_database["breakfast"]["high_protein"], 3, allergies
            )
        
        # Select lunch items
        if weight < 50:  # Underweight - need high calorie
            recommendation["lunch"] = self._select_items(
                self.food_database["lunch"]["high_protein"], 3, allergies
            )
        else:
            recommendation["lunch"] = self._select_items(
                self.food_database["lunch"]["general"], 3, allergies
            )
        
        # Select dinner items
        if "stage iv" in stage or "stage 4" in stage:
            recommendation["dinner"] = self._select_items(
                self.food_database["dinner"]["light"], 3, allergies
            )
        else:
            recommendation["dinner"] = self._select_items(
                self.food_database["dinner"]["moderate"], 3, allergies
            )
        
        # Select snacks
        recommendation["snacks"] = self._select_items(
            self.food_database["snacks"]["healthy"], 4, allergies
        )
        
        # Add personalized notes
        recommendation["notes"] = self._generate_notes(patient_data)
        
        return recommendation
    
    def _select_items(self, items: List[str], count: int, allergies: str) -> List[str]:
        """Select items from list, filtering out allergens"""
        filtered_items = []
        allergen_list = [a.strip() for a in allergies.split(",") if a.strip()]
        
        for item in items:
            # Simple allergen check
            has_allergen = any(
                allergen.lower() in item.lower() 
                for allergen in allergen_list
            )
            if not has_allergen:
                filtered_items.append(item)
        
        # If we don't have enough items, use what we have
        if len(filtered_items) < count:
            return filtered_items
        
        # Return requested count
        return filtered_items[:count]
    
    def _generate_notes(self, patient_data: Dict) -> str:
        """Generate personalized dietary notes"""
        notes = []
        
        cancer_type = patient_data.get("cancer_type", "").lower()
        stage = patient_data.get("stage", "").lower()
        weight = patient_data.get("weight", 70)
        
        # General advice
        notes.append("Stay hydrated - drink at least 8 glasses of water daily.")
        
        # Weight-specific advice
        if weight < 50:
            notes.append("Focus on calorie-dense, nutritious foods to maintain healthy weight.")
        elif weight > 90:
            notes.append("Choose lean proteins and increase vegetable intake.")
        
        # Cancer-specific advice
        if "breast" in cancer_type:
            notes.append("Include foods rich in antioxidants like berries and leafy greens.")
        elif "colorectal" in cancer_type or "colon" in cancer_type:
            notes.append("Include high-fiber foods and probiotics for digestive health.")
        elif "lung" in cancer_type:
            notes.append("Foods rich in vitamin C and E may support lung health.")
        
        # Stage-specific advice
        if "stage iv" in stage or "stage 4" in stage:
            notes.append("Eat smaller, frequent meals if you experience appetite loss.")
        
        notes.append("Always consult with your oncologist before making major dietary changes.")
        
        return " ".join(notes)
