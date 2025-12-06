import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';
import 'auth_service.dart';
import 'api_service.dart';

class DashboardService {
  static const String _cacheKey = 'cached_dashboard_data';
  static const String _cacheTimestampKey = 'cached_dashboard_timestamp';
  static const int _cacheValidityMinutes = 30;

  // Get Dashboard Overview with caching and retry logic
  static Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    try {
      print('📊 DashboardService: Getting dashboard data (forceRefresh: $forceRefresh)...');
      
      // Try to load from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _loadFromCache();
        if (cachedData != null) {
          print('✅ Using cached dashboard data');
          // Still try to refresh in background
          _refreshInBackground();
          return cachedData;
        }
      }
      
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('⚠️ No token found, returning default dashboard');
        return _getDefaultDashboardData();
      }
      
      print('🔑 Token found, making API request...');
      print('🌐 API URL: ${ApiService.apiUrl}/api/dashboard/overview');

      final response = await http.get(
        Uri.parse('${ApiService.apiUrl}/api/dashboard/overview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Dashboard request timeout');
          throw Exception('Connection timeout. Using cached data if available.');
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dashboardData = DashboardData.fromJson(data);
        
        // Save to cache
        await _saveToCache(dashboardData);
        print('✅ Dashboard data loaded and cached successfully');
        
        return dashboardData;
      } else if (response.statusCode == 404) {
        print('⚠️ Profile not found (404)');
        // Return cached data or default
        final cachedData = await _loadFromCache();
        return cachedData ?? _getDefaultDashboardData();
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed (401)');
        throw Exception('Session expired. Please log in again.');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        // Try to return cached data
        final cachedData = await _loadFromCache();
        if (cachedData != null) {
          return cachedData;
        }
        throw Exception('Unable to connect to server. Please check your internet connection.');
      }
    } catch (e) {
      print('❌ DashboardService error: $e');
      
      // Try to return cached data on any error
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        print('✅ Returning cached data after error');
        return cachedData;
      }
      
      // If it's a network error, return default data instead of failing
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('timeout')) {
        print('🔌 Network error detected, returning default dashboard');
        return _getDefaultDashboardData();
      }
      
      throw Exception('Unable to load dashboard. Please check your connection.');
    }
  }

  // Load dashboard data from cache
  static Future<DashboardData?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cachedJson != null && cachedTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        final cacheAgeMinutes = cacheAge / (1000 * 60);
        
        print('💾 Found cached data (age: ${cacheAgeMinutes.toInt()} minutes)');
        
        // Return cached data even if old (better than nothing)
        final data = json.decode(cachedJson);
        return DashboardData.fromJson(data);
      }
    } catch (e) {
      print('⚠️ Error loading from cache: $e');
    }
    return null;
  }

  // Save dashboard data to cache
  static Future<void> _saveToCache(DashboardData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data.toJson());
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('💾 Dashboard data cached successfully');
    } catch (e) {
      print('⚠️ Error saving to cache: $e');
    }
  }

  // Refresh dashboard data in background
  static void _refreshInBackground() async {
    try {
      await getDashboardData(forceRefresh: true);
    } catch (e) {
      print('⚠️ Background refresh failed: $e');
    }
  }

  // Return default dashboard data when API is unavailable
  static DashboardData _getDefaultDashboardData() {
    return DashboardData(
      overview: DashboardOverview(
        dietPlanStatus: 'No active plan',
        progressPercentage: 0,
        hasDietPlan: false,
        totalProgressEntries: 0,
        lastEntryDate: null,
        totalRecommendedFoods: 0,
        lastRecommendationDate: null,
      ),
      recommendations: [],
      tips: [
        HealthTip(
          icon: 'water_drop',
          title: 'Stay Hydrated',
          description: 'Drink plenty of water throughout the day',
        ),
        HealthTip(
          icon: 'restaurant',
          title: 'Eat Regularly',
          description: 'Try to have small meals every few hours',
        ),
        HealthTip(
          icon: 'bedtime',
          title: 'Rest Well',
          description: 'Get adequate sleep for recovery',
        ),
      ],
      profile: ProfileSummary(
        cancerType: 'Not specified',
        stage: 'Active Treatment',
        age: null,
      ),
    );
  }
}

