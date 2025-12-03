import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_profile.dart';
import '../models/diet_recommendation.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _authTokenKey = 'auth_token';
  static const String _patientProfileKey = 'patient_profile';
  static const String _dietRecommendationKey = 'diet_recommendation';

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  Future<void> savePatientProfile(PatientProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString(_patientProfileKey, jsonString);
  }

  Future<PatientProfile?> getPatientProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_patientProfileKey);
    
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      return PatientProfile.fromJson(json);
    }
    return null;
  }

  // Get patient ID for ML service
  Future<String> getPatientId() async {
    final profile = await getPatientProfile();
    return profile?.id.toString() ?? 'unknown';
  }

  Future<void> saveDietRecommendation(DietRecommendation recommendation) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(recommendation.toJson());
    await prefs.setString(_dietRecommendationKey, jsonString);
  }

  Future<DietRecommendation?> getDietRecommendation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_dietRecommendationKey);
    
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      return DietRecommendation.fromJson(json);
    }
    return null;
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

