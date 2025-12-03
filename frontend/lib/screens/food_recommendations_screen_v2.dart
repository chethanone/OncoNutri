import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';
import 'dart:math';
import '../models/food_recommendation.dart';
import '../models/intake_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
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
      final token = await AuthService.getToken();
      
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
                  child: Text('${food.name} added to your diet plan'),
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
            content: Text('Failed to add food to diet plan'),
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
            content: Text('Error: $e'),
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

      final recommendations = await ApiService.getRecommendations(widget.intakeData);
      
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
    if (_isLoading) {
      final currentTip = _nutritionTips[_currentTipIndex];
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                          child: Text(
                            'Creating your personalized nutrition plan...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: currentTip['color'].withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: currentTip['color'].withOpacity(0.3),
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
                                      color: Colors.grey[600],
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
                            color: Colors.grey[800],
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
          title: const Text('Recommendations'),
          backgroundColor: AppTheme.colorPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.colorDanger),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRecommendations,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildRecommendationsView();
  }

  Widget _buildRecommendationsView() {
    final mealGroups = _categorizeFoodsByMeal();
    final topFoods = _recommendations!.take(5).toList();
    
    double totalProtein = 0;
    double totalCalories = 0;
    for (var food in _recommendations!) {
      totalProtein += food.keyNutrients['protein'] ?? 0;
      totalCalories += food.keyNutrients['energy'] ?? 0;
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
                gradient: LinearGradient(
                  colors: [
                    AppTheme.colorPrimary.withOpacity(0.1),
                    AppTheme.colorPrimary400.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.colorPrimary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Nutrition Goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                  child: const Text(
                    'Top Recommendations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                Row(
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
                            : Colors.grey[300],
                      ),
                    );
                  }).toList(),
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
        label: const Text('Go to Home'),
      ),
    );
  }

  Widget _buildNutritionCard(IconData icon, String value, String label, Color color) {
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
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(FoodRecommendation food) {
    final texture = _getFoodTexture(food.name);
    final category = _getFoodCategory(food.name, food.category);
    final protein = food.keyNutrients['protein'] ?? 0;
    final calories = food.keyNutrients['energy'] ?? 0;

    return GestureDetector(
      onTap: () => _showFoodDetails(food),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
    final texture = _getFoodTexture(food.name);
    final protein = food.keyNutrients['protein'] ?? 0;
    final calories = food.keyNutrients['energy'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
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
                              color: Colors.grey[700],
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
                              color: Colors.grey[700],
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                          _buildNutritionRow('Protein', '${(food.keyNutrients['protein'] ?? 0).toInt()}g', AppTheme.colorPrimary400),
                          _buildNutritionRow('Calories', '${(food.keyNutrients['energy'] ?? 0).toInt()} kcal', AppTheme.colorDanger),
                          if (food.keyNutrients['fiber'] != null)
                            _buildNutritionRow('Fiber', '${(food.keyNutrients['fiber'] ?? 0).toInt()}g', AppTheme.colorSuccess),
                          if (food.keyNutrients['calcium'] != null)
                            _buildNutritionRow('Calcium', '${(food.keyNutrients['calcium'] ?? 0).toInt()}mg', AppTheme.colorPrimary),
                        ],
                      ),
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
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
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

  Widget _buildDetailSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
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
                  color: Colors.grey[700],
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
    final intakeData = widget.intakeData;
    
    // Based on dietary preference (most important)
    if (intakeData.dietaryPreference != null) {
      final pref = intakeData.dietaryPreference!;
      if (pref == 'Pure Veg' || pref == 'Vegetarian') {
        benefits.add('100% Pure Vegetarian - perfectly aligned with your Pure Veg preference');
      } else if (pref == 'Vegan') {
        benefits.add('Completely plant-based - no animal products, ideal for vegan lifestyle');
      } else if (pref == 'Jain') {
        benefits.add('Jain-friendly - no root vegetables or restricted ingredients');
      } else if (pref == 'Veg+Egg' || pref == 'Eggetarian') {
        benefits.add('Vegetarian with eggs - provides both plant and egg-based nutrition');
      } else if (pref == 'Pescatarian') {
        benefits.add('Pescatarian-friendly - includes fish and seafood with plant foods');
      }
    }
    
    // Based on eating ability (critical for texture)
    if (intakeData.eatingAbility == 'liquids_only') {
      benefits.add('Completely liquid texture - easy to swallow without any chewing required');
    } else if (intakeData.eatingAbility == 'soft_only') {
      benefits.add('Soft and gentle texture - requires minimal chewing, easy on your mouth');
    } else if (intakeData.eatingAbility == 'reduced') {
      benefits.add('Easy to digest and eat - perfect for when your appetite is reduced');
    }
    
    // Based on symptoms
    if (intakeData.symptoms != null && intakeData.symptoms!.isNotEmpty) {
      for (var symptom in intakeData.symptoms!) {
        if (symptom.toLowerCase().contains('nausea')) {
          benefits.add('Gentle on stomach - helps manage nausea and reduces discomfort');
          break;
        } else if (symptom.toLowerCase().contains('sore mouth')) {
          benefits.add('Smooth and soothing - won\'t irritate your mouth or throat');
          break;
        } else if (symptom.toLowerCase().contains('fatigue')) {
          benefits.add('Energy-boosting nutrition - helps combat fatigue during treatment');
          break;
        }
      }
    }
    
    // Based on allergies (safety)
    if (intakeData.allergies != null && intakeData.allergies!.isNotEmpty) {
      final allergyList = intakeData.allergies!.join(', ');
      benefits.add('Allergen-safe - free from your listed allergies ($allergyList)');
    }
    
    // Based on protein content
    final protein = food.keyNutrients['protein'] ?? 0;
    if (protein > 15) {
      benefits.add('High protein (${protein.toInt()}g per 100g) - essential for maintaining muscle mass during treatment');
    } else if (protein > 8) {
      benefits.add('Good protein source (${protein.toInt()}g per 100g) - supports healing and recovery');
    }
    
    // Based on calories
    final calories = food.keyNutrients['energy'] ?? 0;
    if (calories > 300) {
      benefits.add('Energy-dense (${calories.toInt()} kcal) - helps you meet daily caloric needs');
    } else if (calories < 150 && intakeData.appetiteLevel == 'low') {
      benefits.add('Light option (${calories.toInt()} kcal) - perfect when appetite is low');
    }
    
    // Based on cancer type
    if (intakeData.cancerType != null) {
      benefits.add('Recommended for ${intakeData.cancerType} - supports immune function and healing');
    }
    
    // Based on treatment stage
    if (intakeData.treatmentStage?.toLowerCase().contains('active') ?? false) {
      benefits.add('Treatment-friendly - gentle on your digestive system during active therapy');
    } else if (intakeData.treatmentStage?.toLowerCase().contains('recovery') ?? false) {
      benefits.add('Recovery nutrition - helps rebuild strength after treatment');
    }
    
    // Generic benefits based on food type (if we don't have enough specific ones)
    if (benefits.length < 3) {
      if (food.name.toLowerCase().contains('dal') || food.name.toLowerCase().contains('lentil')) {
        benefits.add('Rich in fiber and plant protein - promotes digestive health');
      }
      if (food.name.toLowerCase().contains('paneer')) {
        benefits.add('Excellent calcium source - supports bone health during treatment');
      }
      if (food.name.toLowerCase().contains('smoothie') || food.name.toLowerCase().contains('juice')) {
        benefits.add('Easy to digest and hydrating - perfect for staying nourished');
      }
      if (food.name.toLowerCase().contains('soup') || food.name.toLowerCase().contains('broth')) {
        benefits.add('Warm and comforting - provides hydration and nutrition together');
      }
    }
    
    // Always have at least 3 benefits
    if (benefits.length < 3) {
      benefits.add('Carefully selected based on your complete health profile');
      benefits.add('Balanced nutrition to support your treatment journey');
      benefits.add('Designed with your comfort and safety in mind');
    }
    
    return benefits.take(6).toList();
  }
}


