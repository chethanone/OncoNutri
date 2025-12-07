import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/intake_data.dart';
import '../models/food_recommendation.dart';
import '../models/patient_profile.dart';
import '../models/diet_recommendation.dart';
import '../models/progress_entry.dart';
import '../screens/user_history_screen.dart';

class ApiService {
  // Node.js backend server (auth, diet plan, patient profiles)
  // Cloud deployment on Render
  static const String baseUrl = 'https://onconutri-node-api.onrender.com'; 
  static const String physicalDeviceUrl = 'https://onconutri-node-api.onrender.com';
  
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
  static Future<List<FoodRecommendation>> getRecommendations(IntakeData intakeData, {String? token, int retryCount = 0}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      print('🔄 Getting recommendations... (Attempt ${retryCount + 1}/3)');
      print('🔑 Token: ${token != null ? "Present" : "Missing"}');
      print('🌐 Connecting to: $apiUrl/api/recommendations');
      
      final response = await http.post(
        Uri.parse('$apiUrl/api/recommendations'),
        headers: headers,
        body: json.encode(intakeData.toJson()),
      ).timeout(
        Duration(seconds: retryCount == 0 ? 120 : 60), // First attempt gets more time for server wake-up
        onTimeout: () {
          throw Exception('Request timeout - the server is taking longer than usual. This may happen when servers are waking up from sleep.');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      
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
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token may be expired');
        throw Exception('Authentication failed. Please log in again.');
      } else {
        print('❌ Failed to get recommendations: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      if (retryCount < 2) {
        print('🔄 Retrying in 3 seconds...');
        await Future.delayed(Duration(seconds: 3));
        return getRecommendations(intakeData, token: token, retryCount: retryCount + 1);
      }
      throw Exception('Unable to connect to server. Please check your internet connection and try again.');
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      if (retryCount < 2) {
        print('🔄 Server may be waking up, retrying in 5 seconds...');
        await Future.delayed(Duration(seconds: 5));
        return getRecommendations(intakeData, token: token, retryCount: retryCount + 1);
      }
      throw Exception('Server is taking too long to respond. Please try again in a moment.');
    } catch (e) {
      print('❌ Error getting recommendations: $e');
      if (retryCount < 2 && !e.toString().contains('Authentication')) {
        print('🔄 Retrying in 3 seconds...');
        await Future.delayed(Duration(seconds: 3));
        return getRecommendations(intakeData, token: token, retryCount: retryCount + 1);
      }
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
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Log history
        await HistoryLogger.logEvent(
          type: 'food_saved',
          title: 'Food Saved',
          description: 'Added "${food.name}" to diet plan',
        );
        return true;
      }
      return false;
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
      
      print('🔍 Fetching saved diet plan from: $apiUrl/api/diet/plan');
      print('🔑 Token available: ${token != null}');
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/diet/plan'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - check your internet connection');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data'] as List;
        
        print('✅ Successfully fetched ${items.length} diet items');
        
        return items.map((item) {
          try {
            // Parse key_nutrients carefully
            Map<String, double> nutrients = {};
            if (item['key_nutrients'] != null) {
              final rawNutrients = item['key_nutrients'];
              if (rawNutrients is String) {
                // If it's a JSON string, parse it first
                try {
                  final parsed = json.decode(rawNutrients) as Map;
                  parsed.forEach((k, v) {
                    if (v != null) {
                      if (v is num) {
                        nutrients[k.toString()] = v.toDouble();
                      } else if (v is String) {
                        nutrients[k.toString()] = double.tryParse(v) ?? 0.0;
                      }
                    }
                  });
                } catch (e) {
                  print('Error parsing nutrients from string: $e');
                }
              } else if (rawNutrients is Map) {
                rawNutrients.forEach((k, v) {
                  if (v != null) {
                    if (v is num) {
                      nutrients[k.toString()] = v.toDouble();
                    } else if (v is String) {
                      nutrients[k.toString()] = double.tryParse(v) ?? 0.0;
                    }
                  }
                });
              }
            }
            
            // Convert saved diet item to FoodRecommendation format
            // Handle score - it might be a string or number
            double score = 0.0;
            if (item['score'] != null) {
              if (item['score'] is String) {
                score = double.tryParse(item['score']) ?? 0.0;
              } else if (item['score'] is num) {
                score = (item['score'] as num).toDouble();
              }
            }
            
            return FoodRecommendation(
              id: item['id'],
              fdcId: item['fdc_id'] ?? 0,
              name: item['food_name'] ?? 'Unknown Food',
              score: score,
              dataType: item['data_type'] ?? 'saved',
              keyNutrients: nutrients,
              cuisine: item['cuisine'],
              texture: item['texture'],
              preparation: item['preparation'],
              benefits: item['benefits'],
              foodType: item['food_type'],
              imageUrl: item['image_url'],
              category: item['category'],
            );
          } catch (e) {
            print('⚠️ Error parsing diet item: $e');
            print('Item data: $item');
            // Return a default item on parse error
            return FoodRecommendation(
              fdcId: 0,
              name: 'Error loading item',
              score: 0.0,
              dataType: 'error',
              keyNutrients: {},
            );
          }
        }).where((item) => item.fdcId != 0).toList(); // Filter out error items
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token may be expired');
        throw Exception('Authentication failed. Please log in again.');
      } else {
        print('❌ Failed to get saved diet plan: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to get saved diet plan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting saved diet plan: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        print('⚠️ Network error - cannot reach server');
      }
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

