class AppConstants {
  // App Info
  static const String appName = 'OncoNutri+';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Using localhost with ADB port forwarding
  static const String apiBaseUrl = 'https://onconutri-ml-api.onrender.com/api';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  
  // Notification IDs
  static const int breakfastNotificationId = 1;
  static const int lunchNotificationId = 2;
  static const int dinnerNotificationId = 3;
  
  // Cancer Types
  static const List<String> cancerTypes = [
    'Breast Cancer',
    'Lung Cancer',
    'Colorectal Cancer',
    'Prostate Cancer',
    'Stomach Cancer',
    'Liver Cancer',
    'Other',
  ];
  
  // Cancer Stages
  static const List<String> cancerStages = [
    'Stage I',
    'Stage II',
    'Stage III',
    'Stage IV',
  ];
  
  // Supported Languages
  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Spanish',
  ];
}

