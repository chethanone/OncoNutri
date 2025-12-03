import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/patient_profile_screen.dart';
// Temporarily disabled due to compilation errors
// import '../screens/diet_recommendation_screen.dart';
import '../screens/progress_history_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String patientProfile = '/patient-profile';
  static const String dietRecommendation = '/diet-recommendation';
  static const String progressHistory = '/progress-history';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    home: (context) => const HomeScreen(),
    patientProfile: (context) => const PatientProfileScreen(),
    // Temporarily disabled due to compilation errors  
    // dietRecommendation: (context) => const DietRecommendationScreen(),
    progressHistory: (context) => const ProgressHistoryScreen(),
  };
}

