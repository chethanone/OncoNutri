import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // UPDATED: Using localhost with ADB port forwarding
  // Node.js auth server runs on port 5000
  static const String _baseUrl = 'http://localhost:5000/api';
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _hasCompletedIntakeKey = 'has_completed_intake';
  static const String _isFirstTimeKey = 'is_first_time';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Check if this is first time opening app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  // Mark that user has seen onboarding
  static Future<void> setNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }

  // Check if user has completed intake
  static Future<bool> hasCompletedIntake() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedIntakeKey) ?? false;
  }

  // Mark intake as completed
  static Future<void> setIntakeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedIntakeKey, true);
  }

  // Guest login
  static Future<Map<String, dynamic>> guestLogin() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/guest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        await prefs.setInt(_userIdKey, data['user_id'] ?? 0);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Email/Password login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Attempting login to: $_baseUrl/auth/login');
      print('📧 Email: $email');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection and ensure the backend server is running.');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        // Backend returns user.id, not user_id
        await prefs.setInt(_userIdKey, data['user']?['id'] ?? 0);
        // Save user name and email
        await prefs.setString('user_name', data['user']?['name'] ?? '');
        await prefs.setString('user_email', data['user']?['email'] ?? '');
        
        // Get intake completion status from backend response
        final hasCompletedIntake = data['hasCompletedIntake'] ?? false;
        // Save it locally for quick access
        await prefs.setBool(_hasCompletedIntakeKey, hasCompletedIntake);
        
        print('✅ Login successful!');
        print('📋 Intake completed: $hasCompletedIntake');
        return {'success': true, 'data': data, 'hasCompletedIntake': hasCompletedIntake};
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorBody['error'] ?? 'Invalid email or password';
        print('❌ Login failed: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('❌ Login error: $e');
      String errorMessage = 'Login failed: ${e.toString()}';
      
      // Provide user-friendly error messages
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      print('📝 Attempting registration to: $_baseUrl/auth/register');
      print('📧 Email: $email');
      print('👤 Name: $name');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password, 'name': name}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      print('📡 Registration response status: ${response.statusCode}');
      print('📦 Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        // Backend returns user.id, not user_id
        await prefs.setInt(_userIdKey, data['user']?['id'] ?? 0);
        // Save user name and email
        await prefs.setString('user_name', data['user']?['name'] ?? '');
        await prefs.setString('user_email', data['user']?['email'] ?? '');
        // New users haven't completed intake
        await prefs.setBool(_hasCompletedIntakeKey, false);
        
        print('✅ Registration successful!');
        return {'success': true, 'data': data};
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorBody['error'] ?? 'Registration failed';
        print('❌ Registration failed: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('❌ Registration error: $e');
      String errorMessage = 'Registration failed: ${e.toString()}';
      
      // Provide user-friendly error messages
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      }
      
      return {'success': false, 'error': errorMessage};
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_hasCompletedIntakeKey);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  // Get auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
}

