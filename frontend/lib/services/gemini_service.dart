import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: SECURITY - Move API key to environment variables or secure storage
  // For now using placeholder - replace with actual key in local development only
  // API key should be loaded from backend or environment
  // For production, fetch this from your backend API
  static const String _apiKey = String.fromEnvironment('GOOGLE_API_KEY', defaultValue: 'AIzaSyBpbF-Z3KdsNUkZ6Eg1O2gvZn171lE3xs'); // Truncated for security
  static String get apiKey => _apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  /// Understand and standardize cancer type input from user
  static Future<String> understandCancerType(String userInput) async {
    try {
      final prompt = '''
You are a medical assistant helping to standardize cancer type names. 
User input: "$userInput"

Please identify and return ONLY the standardized cancer type name from the following options:
- Breast Cancer
- Lung Cancer
- Colorectal Cancer
- Prostate Cancer
- Stomach Cancer
- Liver Cancer
- Pancreatic Cancer
- Kidney Cancer
- Bladder Cancer
- Thyroid Cancer
- Skin Cancer
- Blood Cancer
- Brain Cancer
- Bone Cancer
- Ovarian Cancer
- Cervical Cancer
- Esophageal Cancer
- Head & Neck Cancer

If the input matches multiple types, choose the most likely one.
If unclear, return the input as "{Input} Cancer".
Return ONLY the cancer type name, nothing else.
''';
      
      final response = await _makeRequest(prompt);
      return response.trim();
    } catch (e) {
      // Fallback: capitalize the input
      return '${userInput[0].toUpperCase()}${userInput.substring(1)} Cancer';
    }
  }
  
  /// Understand and process food allergies/restrictions from user input
  static Future<List<String>> understandAllergies(String userInput) async {
    try {
      final prompt = '''
You are a medical nutritionist helping to identify food allergies and dietary restrictions.
User input: "$userInput"

Identify ALL relevant allergies/restrictions from the following categories:
- Dairy (lactose intolerance, milk allergy)
- Gluten (celiac disease, gluten sensitivity)
- Nuts (peanuts, tree nuts)
- Eggs
- Soy
- Seafood (fish, shellfish)
- Red Meat
- Poultry

Return a JSON array of matching categories. For example:
["Dairy", "Gluten", "Nuts"]

If the input mentions specific items, map them to categories.
Examples:
- "I can't eat milk" → ["Dairy"]
- "allergic to peanuts and shrimp" → ["Nuts", "Seafood"]
- "lactose intolerant" → ["Dairy"]

Return ONLY the JSON array, no explanation.
''';
      
      final response = await _makeRequest(prompt);
      
      // Parse the JSON response
      try {
        final List<dynamic> parsed = json.decode(response);
        return parsed.cast<String>();
      } catch (e) {
        // If JSON parsing fails, return the input as-is
        return [userInput];
      }
    } catch (e) {
      return [userInput];
    }
  }
  
  /// Process user dietary preferences and restrictions to provide context-aware recommendations
  static Future<String> enhanceDietaryContext({
    required String cancerType,
    required String treatmentStage,
    required List<String> allergies,
    required String appetite,
    required String eatingAbility,
  }) async {
    try {
      final prompt = '''
You are a cancer nutrition specialist. Provide a brief, focused dietary guidance summary (max 100 words).

Patient Context:
- Cancer Type: $cancerType
- Treatment Stage: $treatmentStage
- Allergies/Restrictions: ${allergies.join(', ')}
- Appetite Level: $appetite
- Eating Ability: $eatingAbility

Provide:
1. Top 3 nutrient priorities
2. Foods to emphasize
3. Foods to avoid
4. One key tip for managing symptoms

Keep response concise and actionable.
''';
      
      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return 'Focus on easily digestible, nutrient-dense foods. Stay hydrated. Eat small, frequent meals.';
    }
  }
  
  /// Make HTTP request to Gemini API
  static Future<String> _makeRequest(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    
    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 200,
      }
    });
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text.toString();
    } else {
      throw Exception('API request failed: ${response.statusCode}');
    }
  }
  
  /// Validate if the API key is configured
  static bool isConfigured() {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE';
  }
}

