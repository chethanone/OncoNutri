import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../models/food_recommendation.dart';
import '../models/intake_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';

class FoodRecommendationsScreenV2 extends StatefulWidget {
  final IntakeData intakeData;

  const FoodRecommendationsScreenV2({
    Key? key,
    required this.intakeData,
  }) : super(key: key);

  @override
  State<FoodRecommendationsScreenV2> createState() => _FoodRecommendationsScreenV2State();
}

class _FoodRecommendationsScreenV2State extends State<FoodRecommendationsScreenV2> {
  List<FoodRecommendation>? _recommendations;
  bool _isLoading = true;
  String? _error;
  int _currentCarouselIndex = 0;
  Timer? _tipTimer;
  int _currentTipIndex = 0;
  final Random _random = Random();
  Set<int> _savedFoodIds = {}; // Track saved foods

  // Save food to diet plan
  Future<void> _saveFoodToDietPlan(FoodRecommendation food, String mealType) async {
    try {
      // Get auth token
      final token = await AuthService.getValidToken();
      
      print('Attempting to save food: ${food.name}');
      print('Auth token: ${token != null ? "Present" : "Missing"}');
      
      final success = await ApiService.saveFoodToDietPlan(
        food,
        mealType: mealType,
        token: token,
      );
      
      print('Save result: $success');
      
      if (success && mounted) {
        setState(() {
          _savedFoodIds.add(food.fdcId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('${food.name} ${AppLocalizations.of(context)!.foodAddedToDietPlan}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.colorSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddFood),
            backgroundColor: AppTheme.colorDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error saving food: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorMessage}: $e'),
            backgroundColor: AppTheme.colorDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _nutritionTips = [
    {
      'icon': Icons.water_drop,
      'tip': 'Stay hydrated! Drink at least 8 glasses of water daily to help your body process nutrients.',
      'color': Colors.blue,
    },
    {
      'icon': Icons.restaurant_menu,
      'tip': 'Eat small, frequent meals throughout the day to maintain energy levels during treatment.',
      'color': Colors.orange,
    },
    {
      'icon': Icons.local_florist,
      'tip': 'Include colorful fruits and vegetables - they\'re rich in antioxidants that support healing.',
      'color': Colors.green,
    },
    {
      'icon': Icons.fitness_center,
      'tip': 'Protein is crucial for recovery. Include lean meats, fish, eggs, or plant-based proteins daily.',
      'color': Colors.red,
    },
    {
      'icon': Icons.bedtime,
      'tip': 'Rest is as important as nutrition. Ensure 7-8 hours of quality sleep each night.',
      'color': Colors.purple,
    },
    {
      'icon': Icons.emoji_food_beverage,
      'tip': 'Ginger tea can help reduce nausea and improve digestion during treatment.',
      'color': Colors.amber,
    },
    {
      'icon': Icons.spa,
      'tip': 'Practice mindful eating - eat slowly and chew thoroughly for better digestion.',
      'color': Colors.teal,
    },
    {
      'icon': Icons.favorite,
      'tip': 'Foods rich in omega-3 like flaxseeds and walnuts help reduce inflammation.',
      'color': Colors.pink,
    },
    {
      'icon': Icons.sunny,
      'tip': 'Get some morning sunlight for natural Vitamin D, essential for bone health.',
      'color': Colors.yellow,
    },
    {
      'icon': Icons.local_hospital,
      'tip': 'Maintain food hygiene strictly - wash all produce thoroughly before consumption.',
      'color': Colors.indigo,
    },
    {
      'icon': Icons.no_drinks,
      'tip': 'Avoid alcohol and limit caffeine intake to support your treatment and recovery.',
      'color': Colors.brown,
    },
    {
      'icon': Icons.rice_bowl,
      'tip': 'Whole grains provide sustained energy and essential B vitamins for healing.',
      'color': Colors.deepOrange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentTipIndex = _random.nextInt(_nutritionTips.length);
    _startTipRotation();
    _loadRecommendations();
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _currentTipIndex = _random.nextInt(_nutritionTips.length);
        });
      }
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get auth token
      final token = await AuthService.getValidToken();
      print('🔑 Loading recommendations with token: ${token != null ? "Present" : "Missing"}');

      final recommendations = await ApiService.getRecommendations(widget.intakeData, token: token);
      
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading recommendations: $e');
      
      // Create a user-friendly error message
      String userMessage;
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('waking up') || errorString.contains('taking longer')) {
        userMessage = 'Server is waking up from sleep mode. This may take 30-60 seconds. Please wait...';
      } else if (errorString.contains('connection refused') || 
          errorString.contains('failed host lookup') ||
          errorString.contains('unable to connect') ||
          errorString.contains('socketexception')) {
        userMessage = 'Unable to connect to server. Please check your internet connection and try again.';
      } else if (errorString.contains('timeout') || errorString.contains('taking too long')) {
        userMessage = 'Server is taking longer than usual. It may be waking up from sleep mode. Please try again.';
      } else if (errorString.contains('authentication')) {
        userMessage = 'Session expired. Please log in again.';
      } else {
        userMessage = 'Unable to load recommendations. Please try again.';
      }
      
      setState(() {
        _error = userMessage;
        _isLoading = false;
      });
    }
  }

  Map<String, List<FoodRecommendation>> _categorizeFoodsByMeal() {
    if (_recommendations == null) return {};
    
    final breakfast = <FoodRecommendation>[];
    final lunch = <FoodRecommendation>[];
    final dinner = <FoodRecommendation>[];
    final snacks = <FoodRecommendation>[];
    
    for (var food in _recommendations!) {
      final category = (food.category ?? '').toLowerCase();
      final name = food.name.toLowerCase();
      
      if (category.contains('breakfast') || name.contains('breakfast') ||
          name.contains('oatmeal') || name.contains('poha') || 
          name.contains('upma') || name.contains('idli') || name.contains('dosa')) {
        breakfast.add(food);
      } else if (category.contains('snack') || name.contains('snack') ||
                 name.contains('smoothie') || name.contains('juice') ||
                 name.contains('chaat') || name.contains('makhana')) {
        snacks.add(food);
      } else if (category.contains('dinner') || name.contains('dinner') ||
                 name.contains('khichdi') || name.contains('soup')) {
        dinner.add(food);
      } else {
        lunch.add(food);
      }
    }
    
    return {
      'Breakfast': breakfast,
      'Lunch': lunch,
      'Dinner': dinner,
      'Snacks': snacks,
    };
  }

  String _getFoodTexture(String foodName) {
    final name = foodName.toLowerCase();
    
    // Liquids
    if (name.contains('smoothie') || name.contains('juice') || 
        name.contains('soup') || name.contains('shake') ||
        name.contains('milk') || name.contains('water') ||
        name.contains('tea') || name.contains('coffee')) {
      return 'Liquid';
    }
    
    // Soft foods
    if (name.contains('dal') || name.contains('khichdi') ||
        name.contains('mashed') || name.contains('pureed') ||
        name.contains('porridge') || name.contains('oatmeal') ||
        name.contains('yogurt') || name.contains('curd') ||
        name.contains('paneer')) {
      return 'Soft';
    }
    
    // Regular foods
    return 'Regular';
  }

  String _getFoodCategory(String foodName, String? category) {
    if (category != null && category.isNotEmpty) return category;
    
    final name = foodName.toLowerCase();
    
    if (name.contains('breakfast') || name.contains('oatmeal') ||
        name.contains('poha') || name.contains('upma') ||
        name.contains('idli') || name.contains('dosa')) {
      return 'Breakfast';
    }
    if (name.contains('snack') || name.contains('smoothie') ||
        name.contains('juice') || name.contains('chaat') ||
        name.contains('makhana')) {
      return 'Snack';
    }
    if (name.contains('dinner') || name.contains('khichdi') ||
        name.contains('soup')) {
      return 'Dinner';
    }
    return 'Lunch';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    if (_isLoading) {
      final currentTip = _nutritionTips[_currentTipIndex];
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark 
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.colorDarkBackground,
                      AppTheme.colorDarkSurface,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.colorPrimary.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.colorPrimary),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Text(
                                'Creating your personalized nutrition plan...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? AppTheme.colorDarkText : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'This may take up to 90 seconds while we analyze thousands of foods for you...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tips section at bottom
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(_currentTipIndex),
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.colorDarkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: currentTip['color'].withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: currentTip['color'].withOpacity(isDark ? 0.4 : 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: currentTip['color'].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                currentTip['icon'],
                                color: currentTip['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health Tip',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: currentTip['color'],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Did you know?',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentTip['tip'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.colorDarkText : Colors.grey[800],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.recommendations),
          backgroundColor: AppTheme.colorPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connection Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadRecommendations,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.tryAgain),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home),
                      label: Text(AppLocalizations.of(context)!.goHome),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.colorPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Make sure you have an active internet connection',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildRecommendationsView();
  }

  Widget _buildRecommendationsView() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    if (_recommendations == null || _recommendations!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.recommendations),
          backgroundColor: AppTheme.colorPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No recommendations available',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.goBack),
              ),
            ],
          ),
        ),
      );
    }
    
    final mealGroups = _categorizeFoodsByMeal();
    final topFoods = _recommendations!.take(5).toList();
    
    double totalProtein = 0;
    double totalCalories = 0;
    for (var food in _recommendations!) {
      totalProtein += food.keyNutrients['Protein'] ?? food.keyNutrients['protein'] ?? 0;
      totalCalories += food.keyNutrients['Energy'] ?? food.keyNutrients['energy'] ?? 0;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.colorPrimary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Your Nutrition Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: 0.2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.colorPrimary,
                      AppTheme.colorPrimary.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nutrition Summary
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark 
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.colorPrimary.withOpacity(0.1),
                          AppTheme.colorPrimary400.withOpacity(0.1),
                        ],
                      ),
                color: isDark ? AppTheme.colorDarkSurface : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? AppTheme.colorDarkBorder 
                      : AppTheme.colorPrimary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Nutrition Goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionCard(
                        Icons.restaurant_menu,
                        '${_recommendations!.length}',
                        'Foods',
                        AppTheme.colorPrimary,
                      ),
                      _buildNutritionCard(
                        Icons.fitness_center,
                        '${totalProtein.toInt()}g',
                        'Protein',
                        AppTheme.colorPrimary400,
                      ),
                      _buildNutritionCard(
                        Icons.local_fire_department,
                        '${totalCalories.toInt()}',
                        'Calories',
                        AppTheme.colorDanger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Featured Foods Carousel
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Top Recommendations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    ),
                  ),
                ),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    viewportFraction: 0.85,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                  ),
                  items: topFoods.map((food) {
                    return _buildCarouselCard(food);
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Carousel indicators
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isDark = themeProvider.isDarkMode;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: topFoods.asMap().entries.map((entry) {
                        return Container(
                          width: _currentCarouselIndex == entry.key ? 12 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == entry.key
                                ? AppTheme.colorPrimary
                                : (isDark ? AppTheme.colorDarkSubtext : Colors.grey[300]),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Meal Categories
          ...mealGroups.entries.map((entry) {
            if (entry.value.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
            return _buildMealSection(entry.key, entry.value);
          }).toList(),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to HomeScreen and clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        backgroundColor: AppTheme.colorPrimary,
        icon: const Icon(Icons.home),
        label: Text(AppLocalizations.of(context)!.goToHome),
      ),
    );
  }

  Widget _buildNutritionCard(IconData icon, String value, String label, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? color : color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(FoodRecommendation food) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final texture = _getFoodTexture(food.name);
    final category = _getFoodCategory(food.name, food.category);
    final protein = food.keyNutrients['Protein'] ?? food.keyNutrients['protein'] ?? 0;
    final calories = food.keyNutrients['Energy'] ?? food.keyNutrients['energy'] ?? 0;

    return GestureDetector(
      onTap: () => _showFoodDetails(food),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                Image.network(
                  food.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.colorPrimary,
                      child: const Icon(Icons.restaurant, color: Colors.white, size: 50),
                    );
                  },
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.colorPrimary,
                        AppTheme.colorPrimary400,
                      ],
                    ),
                  ),
                ),

              // Gradient Overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Top Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            texture,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.colorPrimary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${(food.score * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Food Info and Save Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Color.fromARGB(150, 0, 0, 0),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildNutrientChip('Protein: ${protein.toInt()}g', Colors.white),
                            const SizedBox(width: 8),
                            _buildNutrientChip('${calories.toInt()} kcal', Colors.white),
                            const Spacer(),
                            // Save button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _saveFoodToDietPlan(food, category.toLowerCase()),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _savedFoodIds.contains(food.fdcId)
                                        ? AppTheme.colorSuccess
                                        : Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _savedFoodIds.contains(food.fdcId)
                                            ? Icons.check
                                            : Icons.add,
                                        color: _savedFoodIds.contains(food.fdcId)
                                            ? Colors.white
                                            : AppTheme.colorPrimary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _savedFoodIds.contains(food.fdcId) ? 'Saved' : 'Save',
                                        style: TextStyle(
                                          color: _savedFoodIds.contains(food.fdcId)
                                              ? Colors.white
                                              : AppTheme.colorPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<FoodRecommendation> foods) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final icons = {
      'Breakfast': Icons.wb_sunny,
      'Lunch': Icons.restaurant,
      'Dinner': Icons.nightlight_round,
      'Snacks': Icons.cookie,
    };

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icons[mealType] ?? Icons.restaurant,
                  size: 24,
                  color: AppTheme.colorPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  mealType,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.colorPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${foods.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.colorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...foods.map((food) => _buildFoodListItem(food)).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFoodListItem(FoodRecommendation food) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final texture = _getFoodTexture(food.name);
    final protein = food.keyNutrients['Protein'] ?? food.keyNutrients['protein'] ?? 0;
    final calories = food.keyNutrients['Energy'] ?? food.keyNutrients['energy'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.colorDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFoodDetails(food),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Texture badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.colorPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    texture,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.colorDarkText : const Color(0xFF2E2E2E),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${protein.toInt()}g',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${calories.toInt()} kcal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Save button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final category = _getFoodCategory(food.name, food.category);
                      _saveFoodToDietPlan(food, category.toLowerCase());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _savedFoodIds.contains(food.fdcId)
                            ? AppTheme.colorSuccess
                            : AppTheme.colorPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _savedFoodIds.contains(food.fdcId)
                              ? AppTheme.colorSuccess
                              : AppTheme.colorPrimary,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _savedFoodIds.contains(food.fdcId)
                            ? Icons.check
                            : Icons.add,
                        color: _savedFoodIds.contains(food.fdcId)
                            ? Colors.white
                            : AppTheme.colorPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.colorPrimary,
                        AppTheme.colorPrimary400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colorPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${(food.score * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFoodDetails(FoodRecommendation food) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final texture = _getFoodTexture(food.name);
    final category = _getFoodCategory(food.name, food.category);
    final benefits = _generatePersonalizedBenefits(food);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.colorDarkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.colorDarkBorder : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Texture and category badges
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.colorPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              texture,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.colorPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.colorPrimary400.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.colorPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      food.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Score
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.colorPrimary,
                              AppTheme.colorPrimary400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${(food.score * 100).toInt()}% Match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nutrition Facts
                    _buildDetailSection(
                      'Nutrition Facts',
                      Column(
                        children: [
                          _buildNutritionRow('Protein', '${((food.keyNutrients['Protein'] ?? food.keyNutrients['protein'] ?? 0)).toInt()}g', AppTheme.colorPrimary400, isDark),
                          _buildNutritionRow('Calories', '${((food.keyNutrients['Energy'] ?? food.keyNutrients['energy'] ?? 0)).toInt()} kcal', AppTheme.colorDanger, isDark),
                          if ((food.keyNutrients['Fiber'] ?? food.keyNutrients['fiber']) != null)
                            _buildNutritionRow('Fiber', '${((food.keyNutrients['Fiber'] ?? food.keyNutrients['fiber'] ?? 0)).toInt()}g', AppTheme.colorSuccess, isDark),
                          if ((food.keyNutrients['Calcium'] ?? food.keyNutrients['calcium']) != null)
                            _buildNutritionRow('Calcium', '${((food.keyNutrients['Calcium'] ?? food.keyNutrients['calcium'] ?? 0)).toInt()}mg', AppTheme.colorPrimary, isDark),
                        ],
                      ),
                      isDark,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Personalized Benefits
                    _buildDetailSection(
                      'Why This is Perfect for You',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: benefits.map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.colorPrimary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppTheme.colorPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: isDark ? AppTheme.colorDarkText : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                      isDark,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Close button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Widget content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.colorDarkBackground : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.colorDarkBorder : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generatePersonalizedBenefits(FoodRecommendation food) {
    final benefits = <String>[];
    
    // First, use the actual benefits from the API if available
    if (food.benefits != null && food.benefits!.isNotEmpty) {
      // Split the benefits string by newlines or common separators
      final apiBenefits = food.benefits!
          .split(RegExp(r'[\n•\-]'))
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty && b.length > 10)
          .toList();
      
      benefits.addAll(apiBenefits);
    }
    
    // If we don't have enough benefits from API, add some personalized ones
    if (benefits.length < 3) {
      final intakeData = widget.intakeData;
      
      // Based on dietary preference
      if (intakeData.dietaryPreference != null && benefits.length < 5) {
        final pref = intakeData.dietaryPreference!;
        if ((pref.contains('Pure Veg') || pref.contains('Vegetarian')) && 
            (food.foodType?.contains('Veg') ?? false)) {
          benefits.add('✓ Perfectly aligned with your vegetarian preference');
        } else if (pref.contains('Vegan') && (food.foodType?.contains('Vegan') ?? false)) {
          benefits.add('✓ Completely plant-based, ideal for vegan lifestyle');
        }
      }
      
      // Based on texture and eating ability
      if (intakeData.eatingAbility != null && food.texture != null && benefits.length < 5) {
        if (intakeData.eatingAbility == 'liquids_only' && food.texture?.toLowerCase().contains('liquid') == true) {
          benefits.add('✓ Liquid texture - easy to swallow without chewing');
        } else if (intakeData.eatingAbility == 'soft_only' && food.texture?.toLowerCase().contains('soft') == true) {
          benefits.add('✓ Soft texture - gentle on your mouth and easy to eat');
        }
      }
      
      // Based on protein content
      final protein = food.keyNutrients['Protein'] ?? food.keyNutrients['protein'] ?? 0;
      if (protein > 15 && benefits.length < 5) {
        benefits.add('✓ High protein (${protein.toInt()}g) - essential for recovery and strength');
      }
      
      // Based on allergies
      if (intakeData.allergies != null && intakeData.allergies!.isNotEmpty && benefits.length < 5) {
        benefits.add('✓ Safe for your dietary restrictions and allergies');
      }
    }
    
    // Ensure we have at least 3 benefits
    if (benefits.isEmpty) {
      benefits.add('Carefully selected based on your health profile');
      benefits.add('Nutritionally balanced to support your treatment');
      benefits.add('Designed with your comfort and safety in mind');
    }
    
    return benefits.take(6).toList();
  }
}


