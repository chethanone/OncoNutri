import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intake_data.dart';
import '../models/food_recommendation.dart';
import '../models/patient_profile.dart';
import '../models/diet_recommendation.dart';
import '../models/progress_entry.dart';

class ApiService {
  // Node.js backend server (auth, diet plan, patient profiles)
  static const String baseUrl = 'http://localhost:5000'; 
  static const String physicalDeviceUrl = 'http://localhost:5000';
  
  static String get apiUrl => baseUrl;
  
  // Guest Login
  static Future<Map<String, dynamic>> guestLogin() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/guest'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get Patient Profile
  static Future<PatientProfile> getPatientProfile(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/patients/$patientId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return PatientProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Save Patient Profile
  Future<bool> savePatientProfile(PatientProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/patients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.toJson()),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Submit Intake Data and Get Recommendations
  static Future<List<FoodRecommendation>> getRecommendations(IntakeData intakeData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(intakeData.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response received: ${data.keys}');
        final recommendations = data['recommendations'] as List;
        print('Got ${recommendations.length} recommendations');
        if (recommendations.isNotEmpty) {
          print('First recommendation: ${recommendations[0].keys}');
          print('First image_url: ${recommendations[0]['image_url']}');
        }
        return recommendations.map((r) => FoodRecommendation.fromJson(r)).toList();
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get Diet Recommendation
  Future<DietRecommendation> getDietRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/diet-recommendations'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return DietRecommendation.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get diet recommendation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get Progress History
  Future<List<ProgressEntry>> getProgressHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/progress'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => ProgressEntry.fromJson(e)).toList();
      } else {
        throw Exception('Failed to get progress history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Add Progress Entry
  Future<bool> addProgressEntry(ProgressEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(entry.toJson()),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Health Check
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Save food to diet plan
  static Future<bool> saveFoodToDietPlan(
    FoodRecommendation food, {
    String mealType = 'snack',
    String? token,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final body = {
        'food_name': food.name,
        'fdc_id': food.fdcId,
        'score': food.score,
        'key_nutrients': food.keyNutrients,
        'cuisine': food.cuisine,
        'texture': food.texture,
        'preparation': food.preparation,
        'benefits': food.benefits,
        'food_type': food.foodType,
        'image_url': food.imageUrl,
        'category': food.category,
        'meal_type': mealType,
      };
      
      print('Saving food to diet plan: ${food.name}');
      print('API URL: $apiUrl/api/diet/plan/save');
      
      final response = await http.post(
        Uri.parse('$apiUrl/api/diet/plan/save'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('Save response status: ${response.statusCode}');
      print('Save response body: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving food to diet plan: $e');
      return false;
    }
  }
  
  // Get saved diet plan items
  static Future<List<FoodRecommendation>> getSavedDietPlan({String? token}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/diet/plan'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data'] as List;
        return items.map((item) {
          // Convert saved diet item to FoodRecommendation format
          return FoodRecommendation(
            fdcId: item['fdc_id'],
            name: item['food_name'],
            score: (item['score'] as num?)?.toDouble() ?? 0.0,
            dataType: item['data_type'] ?? 'saved',
            keyNutrients: Map<String, double>.from(
              (item['key_nutrients'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble())
              ) ?? {}
            ),
            cuisine: item['cuisine'],
            texture: item['texture'],
            preparation: item['preparation'],
            benefits: item['benefits'],
            foodType: item['food_type'],
            imageUrl: item['image_url'],
            category: item['category'],
          );
        }).toList();
      } else {
        throw Exception('Failed to get saved diet plan: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting saved diet plan: $e');
      return [];
    }
  }
  
  // Toggle food completion status
  static Future<bool> toggleFoodCompletion(int itemId, {String? token}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.patch(
        Uri.parse('$apiUrl/api/diet/plan/$itemId/toggle'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling food completion: $e');
      return false;
    }
  }
  
  // Remove food from diet plan
  static Future<bool> removeFoodFromDietPlan(int itemId, {String? token}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.delete(
        Uri.parse('$apiUrl/api/diet/plan/$itemId'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing food from diet plan: $e');
      return false;
    }
  }
  
  // Get diet plan progress statistics
  static Future<Map<String, dynamic>?> getDietPlanProgress({String? token}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/diet/plan/progress'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting diet plan progress: $e');
      return null;
    }
  }
}

