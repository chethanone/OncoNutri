import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/patient_profile.dart';
import '../models/diet_recommendation.dart';
import '../models/progress_entry.dart';
import '../utils/constants.dart';
import 'cache_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = AppConstants.apiBaseUrl;
  String? _authToken;

  // Authentication
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        await CacheService().saveAuthToken(_authToken!);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _authToken = null;
    await CacheService().clearAuthToken();
  }

  // Patient Profile
  Future<bool> savePatientProfile(PatientProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await CacheService().savePatientProfile(profile);
        return true;
      }
      return false;
    } catch (e) {
      print('Save profile error: $e');
      return false;
    }
  }

  Future<PatientProfile?> getPatientProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patient/profile'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PatientProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      // Try to get from cache
      return await CacheService().getPatientProfile();
    }
  }

  // Diet Recommendations
  Future<DietRecommendation?> getDietRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/diet/recommendation'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendation = DietRecommendation.fromJson(data);
        await CacheService().saveDietRecommendation(recommendation);
        return recommendation;
      }
      return null;
    } catch (e) {
      print('Get recommendation error: $e');
      // Try to get from cache
      return await CacheService().getDietRecommendation();
    }
  }

  // Progress History
  Future<List<ProgressEntry>> getProgressHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/history'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => ProgressEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get history error: $e');
      return [];
    }
  }

  Future<bool> addProgressEntry(int score, String notes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'date': DateTime.now().toIso8601String().split('T')[0],
          'adherence_score': score,
          'notes': notes,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Add progress error: $e');
      return false;
    }
  }
}
