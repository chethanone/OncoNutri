class IntakeData {
  String? ageRange;
  String? dietaryPreference;  // NEW: Pure Veg, Veg+Egg, Non-Veg, etc.
  String? cancerType;
  String? treatmentStage;
  String? diagnosisDate;
  List<String>? symptoms;
  List<String>? sideEffects;
  List<String>? dietaryRestrictions;
  List<String>? allergies;
  String? activityLevel;
  String? waterIntake;  // NEW: water intake level
  String? appetiteLevel;  // NEW: appetite level
  String? eatingAbility;  // NEW: what can they eat
  double? height;
  double? weight;
  String? gender;
  List<String>? comorbidities;
  Map<String, int>? mealPreferences;
  
  IntakeData({
    this.ageRange,
    this.dietaryPreference,
    this.cancerType,
    this.treatmentStage,
    this.diagnosisDate,
    this.symptoms,
    this.sideEffects,
    this.dietaryRestrictions,
    this.allergies,
    this.activityLevel,
    this.waterIntake,
    this.appetiteLevel,
    this.eatingAbility,
    this.height,
    this.weight,
    this.gender,
    this.comorbidities,
    this.mealPreferences,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'age_range': ageRange,
      'dietary_preference': dietaryPreference,
      'cancer_type': cancerType,
      'treatment_stage': treatmentStage,
      'diagnosis_date': diagnosisDate,
      'symptoms': symptoms,
      'side_effects': sideEffects,
      'dietary_restrictions': dietaryRestrictions,
      'allergies': allergies,
      'activity_level': activityLevel,
      'water_intake': waterIntake,
      'appetite_level': appetiteLevel,
      'eating_ability': eatingAbility,
      'height': height,
      'weight': weight,
      'gender': gender,
      'comorbidities': comorbidities,
      'meal_preferences': mealPreferences,
    };
  }
  
  factory IntakeData.fromJson(Map<String, dynamic> json) {
    return IntakeData(
      ageRange: json['age_range'],
      dietaryPreference: json['dietary_preference'],
      cancerType: json['cancer_type'],
      treatmentStage: json['treatment_stage'],
      diagnosisDate: json['diagnosis_date'],
      symptoms: json['symptoms'] != null ? List<String>.from(json['symptoms']) : null,
      sideEffects: json['side_effects'] != null ? List<String>.from(json['side_effects']) : null,
      dietaryRestrictions: json['dietary_restrictions'] != null ? List<String>.from(json['dietary_restrictions']) : null,
      allergies: json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      activityLevel: json['activity_level'],
      waterIntake: json['water_intake'],
      appetiteLevel: json['appetite_level'],
      eatingAbility: json['eating_ability'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      gender: json['gender'],
      comorbidities: json['comorbidities'] != null ? List<String>.from(json['comorbidities']) : null,
      mealPreferences: json['meal_preferences'] != null ? Map<String, int>.from(json['meal_preferences']) : null,
    );
  }
}

