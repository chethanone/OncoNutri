import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_data.dart';
import 'auth_service.dart';

class DashboardService {
  static const String baseUrl = 'http://localhost:5000';

  // Get Dashboard Overview
  static Future<DashboardData> getDashboardData() async {
    try {
      print('DashboardService: Getting auth token...');
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('DashboardService: No token found');
        throw Exception('No authentication token found');
      }
      
      print('DashboardService: Token found, making request to $baseUrl/api/dashboard/overview');

      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/overview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DashboardService: Response status: ${response.statusCode}');
      print('DashboardService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardData.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Patient profile not found. Please complete your profile first.');
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Exception caught: $e');
      throw Exception('Dashboard error: $e');
    }
  }
}

