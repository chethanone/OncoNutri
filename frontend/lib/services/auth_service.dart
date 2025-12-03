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
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        // Backend returns user.id, not user_id
        await prefs.setInt(_userIdKey, data['user']?['id'] ?? 0);
        // Save user name and email
        await prefs.setString('user_name', data['user']?['name'] ?? '');
        await prefs.setString('user_email', data['user']?['email'] ?? '');
        
        // For now, assume intake not completed for new logins
        await prefs.setBool(_hasCompletedIntakeKey, false);
        
        return {'success': true, 'data': data, 'hasCompletedIntake': false};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] ?? '');
        // Backend returns user.id, not user_id
        await prefs.setInt(_userIdKey, data['user']?['id'] ?? 0);
        // Save user name and email
        await prefs.setString('user_name', data['user']?['name'] ?? '');
        await prefs.setString('user_email', data['user']?['email'] ?? '');
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
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

