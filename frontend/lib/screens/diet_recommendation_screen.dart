import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/food_recommendation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'user_history_screen.dart';
import '../screens/intake/age_picker_screen.dart';

class DietRecommendationScreen extends StatefulWidget {
  const DietRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<DietRecommendationScreen> createState() => _DietRecommendationScreenState();
}

class _DietRecommendationScreenState extends State<DietRecommendationScreen> with AutomaticKeepAliveClientMixin {
  List<FoodRecommendation> _selectedFoods = [];
  Map<int, bool> _completedFoods = {};
  bool _isLoading = true;
  int _completedToday = 0;
  int _streakDays = 0;
  double _weeklyProgress = 0.0;
  bool _hasLoadedOnce = false;
  
  // User preferences
  String? _ageRange;
  String? _cancerType;
  String? _treatmentStage;
  String? _dietaryPreference;
  List<String> _allergies = [];
  List<String> _symptoms = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadSelectedFoods();
    _loadProgressData();
    
    // Listen for when app resumes to refresh profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will be called after the widget is built
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload when tab becomes visible to get latest profile updates
    if (_hasLoadedOnce) {
      print('🔄 Tab became visible, force reloading profile and diet plan...');
      _loadUserPreferences().then((_) {
        if (mounted) {
          setState(() {
            print('🎨 UI refreshed with new profile data');
          });
        }
      });
      _loadSelectedFoods();
    }
    _hasLoadedOnce = true;
  }
  
  Future<void> _loadUserPreferences() async {
    try {
      final token = await AuthService.getToken();
      
      // Try to load from backend API first
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('${ApiService.apiUrl}/api/patient/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final profile = data['profile'] ?? data;
            
            print('🔍 Profile from API: $profile');
            
            setState(() {
              // Get age_range from API, or convert age to range
              final ageRangeValue = profile['age_range'];
              final ageValue = profile['age'];
              
              if (ageRangeValue != null && ageRangeValue.toString().trim().isNotEmpty && 
                  ageRangeValue != 'null' && ageRangeValue != 'Not specified') {
                _ageRange = ageRangeValue.toString();
              } else if (ageValue != null && ageValue.toString() != 'null') {
                final age = int.tryParse(ageValue.toString());
                if (age != null) {
                  if (age < 18) _ageRange = 'Under 18';
                  else if (age <= 29) _ageRange = '18-29';
                  else if (age <= 39) _ageRange = '30-39';
                  else if (age <= 49) _ageRange = '40-49';
                  else if (age <= 59) _ageRange = '50-59';
                  else if (age <= 69) _ageRange = '60-69';
                  else _ageRange = '70+';
                }
              }
              
              // Get cancer type (filter out "Not specified")
              final cancerType = profile['cancer_type']?.toString();
              _cancerType = (cancerType != null && cancerType.trim().isNotEmpty && 
                            cancerType != 'null' && cancerType != 'Not specified') 
                  ? cancerType : null;
              
              // Get treatment stage (filter out "Not specified")
              final stage = profile['stage']?.toString();
              _treatmentStage = (stage != null && stage.trim().isNotEmpty && 
                                stage != 'null' && stage != 'Not specified') 
                  ? stage : null;
              
              // Get dietary preference
              final diet = profile['dietary_preference']?.toString();
              _dietaryPreference = (diet != null && diet.trim().isNotEmpty && 
                                   diet != 'null' && diet != 'Not specified') 
                  ? diet : null;
              
              // Handle allergies
              if (profile['allergies'] != null) {
                final allergiesData = profile['allergies'];
                if (allergiesData is List) {
                  _allergies = List<String>.from(allergiesData);
                } else if (allergiesData is String && allergiesData.trim().isNotEmpty) {
                  _allergies = allergiesData.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                }
              }
              
              // Handle symptoms
              if (profile['symptoms'] != null) {
                final symptomsData = profile['symptoms'];
                if (symptomsData is List) {
                  _symptoms = List<String>.from(symptomsData);
                } else if (symptomsData is String && symptomsData.trim().isNotEmpty) {
                  _symptoms = symptomsData.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                }
              }
            });
            
            print('✅ Profile loaded from API - Age: $_ageRange, Cancer: $_cancerType, Treatment: $_treatmentStage, Diet: $_dietaryPreference');
            return;
          }
        } catch (e) {
          print('⚠️ Could not load from API: $e');
        }
      }
      
      // If API fails, show message that profile needs to be set up
      print('⚠️ No profile data available. Please complete your profile in settings.');
    } catch (e) {
      print('❌ Error loading user preferences: $e');
    }
  }

  Future<void> _loadSelectedFoods() async {
    setState(() => _isLoading = true);
    String? errorMessage;
    bool isOffline = false;
    
    try {
      final token = await AuthService.getToken();
      
      print('📥 Loading saved diet plan...');
      print('🔑 Token: ${token != null ? "Present" : "Missing"}');
      
      // Check if user is logged in
      if (token == null || token.isEmpty) {
        print('⚠️ No authentication token found - user may need to log in');
        errorMessage = 'Please log in to see your saved diet plan';
        isOffline = true;
        // Try to load from local storage as fallback
        await _loadFromLocalStorage();
        return;
      }
      
      final apiFoods = await ApiService.getSavedDietPlan(token: token);
      
      print('📊 API returned ${apiFoods.length} items');
      
      if (apiFoods.isNotEmpty) {
        setState(() {
          _selectedFoods = apiFoods;
        });
        
        // Save to local storage for offline access
        final prefs = await SharedPreferences.getInstance();
        final foodsJson = apiFoods.map((food) => jsonEncode(food.toJson())).toList();
        await prefs.setStringList('selected_diet_foods', foodsJson);
        print('💾 Saved ${apiFoods.length} items to local storage');
      } else {
        print('📭 No items in diet plan from API, checking local storage...');
        await _loadFromLocalStorage();
      }
    } catch (e) {
      print('❌ Error loading selected foods from API: $e');
      
      // Determine if this is a network/connection error
      final errorString = e.toString().toLowerCase();
      final isConnectionError = errorString.contains('connection refused') || 
                                errorString.contains('failed host lookup') ||
                                errorString.contains('socketexception') ||
                                errorString.contains('timeout');
      
      // Set appropriate error message
      if (e.toString().contains('Authentication failed')) {
        errorMessage = 'Session expired. Please log in again.';
      } else if (isConnectionError) {
        errorMessage = 'Server offline. Using local data.';
        isOffline = true;
      } else {
        errorMessage = 'Error loading diet plan. Showing offline data.';
        isOffline = true;
      }
      
      // Try to load from local storage as fallback
      try {
        await _loadFromLocalStorage();
      } catch (e2) {
        print('❌ Error loading from SharedPreferences: $e2');
      }
    } finally {
      print('✅ Loaded ${_selectedFoods.length} foods total');
      setState(() => _isLoading = false);
      
      // Show error message if any (but make offline messages less alarming)
      if (errorMessage != null && mounted && !isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange,
            action: errorMessage.contains('log in')
                ? SnackBarAction(
                    label: 'Login',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  )
                : null,
          ),
        );
      }
    }
  }
  
  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedFoodsJson = prefs.getStringList('selected_diet_foods') ?? [];
    
    print('💾 SharedPreferences has ${selectedFoodsJson.length} items');
    
    if (selectedFoodsJson.isNotEmpty) {
      try {
        setState(() {
          _selectedFoods = selectedFoodsJson
              .map((json) {
                try {
                  return FoodRecommendation.fromJson(jsonDecode(json));
                } catch (e) {
                  print('⚠️ Error parsing food item from local storage: $e');
                  return null;
                }
              })
              .where((food) => food != null)
              .cast<FoodRecommendation>()
              .toList();
        });
        print('✅ Loaded ${_selectedFoods.length} items from local storage');
      } catch (e) {
        print('❌ Error loading from local storage: $e');
      }
    } else {
      print('📭 No items in local storage');
    }
  }

  Future<void> _loadProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedToday = prefs.getInt('completed_today') ?? 0;
      _streakDays = prefs.getInt('streak_days') ?? 0;
      _weeklyProgress = prefs.getDouble('weekly_progress') ?? 0.0;
      
      final completedMap = prefs.getString('completed_foods');
      if (completedMap != null) {
        final decoded = jsonDecode(completedMap) as Map<String, dynamic>;
        _completedFoods = decoded.map((key, value) => MapEntry(int.parse(key), value as bool));
      }
    });
  }

  Future<void> _saveProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('completed_today', _completedToday);
    await prefs.setInt('streak_days', _streakDays);
    await prefs.setDouble('weekly_progress', _weeklyProgress);
    await prefs.setString('completed_foods', jsonEncode(_completedFoods.map((key, value) => MapEntry(key.toString(), value))));
  }

  Future<void> _loadRecommendation() async {
    await _loadSelectedFoods();
    await _loadProgressData();
  }

  void _toggleFoodCompletion(int index) {
    setState(() {
      final isCurrentlyCompleted = _completedFoods[index] ?? false;
      _completedFoods[index] = !isCurrentlyCompleted;
      
      if (!isCurrentlyCompleted) {
        _completedToday++;
      } else {
        _completedToday--;
      }
    });
    _saveProgressData();
  }

  void _removeFood(int index) async {
    final food = _selectedFoods[index];
    
    setState(() {
      _selectedFoods.removeAt(index);
      _completedFoods.remove(index);
    });

    // Delete from backend if the food has a database ID
    try {
      final token = await AuthService.getToken();
      if (token != null && food.id != null) {
        final response = await http.delete(
          Uri.parse('${ApiService.apiUrl}/api/diet/plan/${food.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        if (response.statusCode == 200) {
          print('✅ Food removed from backend: ${food.name}');
        } else {
          print('⚠️ Could not remove from backend: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('⚠️ Error removing from backend: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final foodsJson = _selectedFoods.map((food) => jsonEncode(food.toJson())).toList();
    await prefs.setStringList('selected_diet_foods', foodsJson);
    
    // Log history
    await HistoryLogger.logEvent(
      type: 'food_removed',
      title: 'Food Removed',
      description: 'Removed "${food.name}" from diet plan',
    );
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.foodRemovedFromPlan),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSelectedFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final foodsJson = _selectedFoods.map((food) => jsonEncode(food.toJson())).toList();
    await prefs.setStringList('selected_diet_foods', foodsJson);
  }

  String _getNutrientSummary(FoodRecommendation food) {
    final nutrients = food.keyNutrients;
    // Try both 'energy' and 'Energy' keys (case-insensitive)
    final calories = (nutrients['energy'] ?? nutrients['Energy'] ?? 0).round();
    final protein = (nutrients['protein'] ?? nutrients['Protein'] ?? 0).toStringAsFixed(1);
    return '$calories cal | ${protein}g protein';
  }

  String _formatText(String? text) {
    if (text == null || text.isEmpty) return 'Not specified';
    
    // Convert underscore-separated text to proper case
    // e.g., "pre_treatment" -> "Pre Treatment", "non_veg" -> "Non Veg"
    return text
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Diet Plan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.colorPrimary,
                AppTheme.colorAccent,
              ],
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadRecommendation,
              color: AppTheme.colorAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSummaryCard(localizations),
                    const SizedBox(height: 16),
                    
                    if (_selectedFoods.isNotEmpty) ...[
                      _buildProgressSection(localizations),
                      const SizedBox(height: 16),
                    ],
                    
                    _buildSavedDietPlanSection(localizations),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
      ),
    );
  }

  Widget _buildProfileSummaryCard(AppLocalizations localizations) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Card(
      elevation: 2,
      color: isDark ? AppTheme.colorDarkSurface : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
              ? [
                  AppTheme.colorDarkSurface,
                  AppTheme.colorDarkSurface,
                ]
              : [
                  AppTheme.colorPrimary.withOpacity(0.1),
                  AppTheme.colorAccent.withOpacity(0.05),
                ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person, 
                  color: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary, 
                  size: 24
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileRow(Icons.cake, 'Age', _ageRange ?? 'Not set'),
            _buildProfileRow(Icons.healing, 'Cancer Type', _cancerType ?? 'Not specified'),
            _buildProfileRow(Icons.medical_services, 'Treatment', _formatText(_treatmentStage)),
            if (_dietaryPreference != null)
              _buildProfileRow(Icons.restaurant_menu, 'Diet Preference', _formatText(_dietaryPreference)),
            if (_dietaryPreference == null)
              _buildProfileRow(Icons.restaurant_menu, 'Diet Preference', 'Not specified'),
            if (_allergies.isNotEmpty)
              _buildProfileRow(Icons.warning, 'Allergies', _allergies.join(', ')),
            if (_symptoms.isNotEmpty)
              _buildProfileRow(Icons.sick, 'Symptoms', _symptoms.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600]
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedDietPlanSection(AppLocalizations localizations) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark, 
                  color: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorAccent, 
                  size: 24
                ),
                const SizedBox(width: 8),
                Text(
                  'Saved Foods',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorPrimary,
                  ),
                ),
              ],
            ),
            if (_selectedFoods.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.colorAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedFoods.length} items',
                  style: TextStyle(
                    color: AppTheme.colorAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        _selectedFoods.isEmpty
            ? _buildEmptyDietPlanState(localizations)
            : _buildSelectedFoodsSection(localizations),
      ],
    );
  }

  Widget _buildEmptyDietPlanState(AppLocalizations localizations) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Card(
      elevation: 1,
      color: isDark ? AppTheme.colorDarkSurface : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.colorDarkBorder : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                size: 64,
                color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Foods in Your Diet Plan Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.colorDarkText : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your personalized diet plan by getting food recommendations',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Get Recommendations flow
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgePickerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: Text(AppLocalizations.of(context)!.getRecommendations),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary,
                foregroundColor: isDark ? AppTheme.colorDarkBackground : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(AppLocalizations localizations) {
    final totalFoods = _selectedFoods.length;
    final progressPercent = totalFoods > 0 ? (_completedToday / totalFoods * 100).round() : 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppTheme.colorAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colorPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Completed', '$_completedToday/$totalFoods', Icons.check_circle, Colors.green),
                _buildStatCard('Progress', '$progressPercent%', Icons.pie_chart, AppTheme.colorAccent),
                _buildStatCard('Streak', '$_streakDays days', Icons.local_fire_department, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFoodsSection(AppLocalizations localizations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedFoods.length,
      itemBuilder: (context, index) {
        final food = _selectedFoods[index];
        final isCompleted = _completedFoods[index] ?? false;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isCompleted ? 1 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Checkbox(
              value: isCompleted,
              onChanged: (value) => _toggleFoodCompletion(index),
              activeColor: Colors.green,
            ),
            title: Text(
              food.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  food.category ?? food.dataType,
                  style: TextStyle(
                    color: AppTheme.colorAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getNutrientSummary(food),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeFood(index),
            ),
          ),
        );
      },
    );
  }
}
