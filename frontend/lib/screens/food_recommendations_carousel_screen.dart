import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/intake_data.dart';
import '../models/food_recommendation.dart';
import '../models/saved_meal_plan.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class FoodRecommendationsCarouselScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const FoodRecommendationsCarouselScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<FoodRecommendationsCarouselScreen> createState() => _FoodRecommendationsCarouselScreenState();
}

class _FoodRecommendationsCarouselScreenState extends State<FoodRecommendationsCarouselScreen> {
  List<FoodRecommendation>? _recommendations;
  bool _isLoading = true;
  String? _error;
  int _currentCarouselIndex = 0;
  Set<int> _selectedFoods = {};
  final Map<int, double> _foodBudgets = {};
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final recommendations = await ApiService.getRecommendations(widget.intakeData);
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recommendations: $e');
      setState(() {
        _error = 'Failed to load recommendations. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildRecommendations(),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorPrimary),
          ),
          const SizedBox(height: 24),
          Text(
            'Creating your personalized plan...',
            style: AppTheme.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best foods from around the world',
            style: AppTheme.body.copyWith(color: AppTheme.colorSubtext),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.colorDanger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.colorDanger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTheme.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.colorSubtext),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendations() {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return const Center(child: Text('No recommendations available'));
    }

    // Debug: Print image URLs
    print('Checking ${_recommendations!.length} recommendations for images:');
    for (var rec in _recommendations!) {
      print('  ${rec.name}: imageUrl=${rec.imageUrl}');
    }

    double totalCalories = 0;
    double totalProtein = 0;
    
    for (var rec in _recommendations!) {
      totalCalories += (rec.keyNutrients['energy'] ?? 0);
      totalProtein += (rec.keyNutrients['protein'] ?? 0);
    }

    return Column(
      children: [
        // Header
        _buildHeader(totalCalories, totalProtein),
        
        // Featured Carousel
        const SizedBox(height: 16),
        _buildFeaturedCarousel(),
        
        // List of all foods
        Expanded(
          child: _buildFoodList(),
        ),
        
        // Bottom buttons
        _buildBottomButtons(),
      ],
    );
  }
  
  Widget _buildHeader(double totalCalories, double totalProtein) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.colorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_menu, color: AppTheme.colorPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Nutrition Plan',
                      style: AppTheme.h2.copyWith(fontSize: 20),
                    ),
                    Text(
                      'AI-powered personalized recommendations',
                      style: AppTheme.caption.copyWith(color: AppTheme.colorSubtext),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge(
                Icons.restaurant,
                '${_recommendations!.length}',
                'Foods',
                AppTheme.colorPrimary,
              ),
              _buildStatBadge(
                Icons.fitness_center,
                '${totalProtein.toInt()}g',
                'Protein',
                Colors.orange,
              ),
              _buildStatBadge(
                Icons.local_fire_department,
                '${totalCalories.toInt()}',
                'Calories',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBadge(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.h2.copyWith(fontSize: 18, color: color),
          ),
          Text(
            label,
            style: AppTheme.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedCarousel() {
    // Show top 10 foods in carousel
    final featuredFoods = _recommendations!.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Featured Recommendations',
            style: AppTheme.h2.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        CarouselSlider.builder(
          itemCount: featuredFoods.length,
          itemBuilder: (context, index, realIndex) {
            final food = featuredFoods[index];
            return _buildCarouselCard(food, index);
          },
          options: CarouselOptions(
            height: 240,
            viewportFraction: 0.75,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() => _currentCarouselIndex = index);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Carousel indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: featuredFoods.asMap().entries.map((entry) {
            return Container(
              width: _currentCarouselIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentCarouselIndex == entry.key
                    ? AppTheme.colorPrimary
                    : AppTheme.colorPrimary.withOpacity(0.2),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCarouselCard(FoodRecommendation food, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Food Image
            food.imageUrl != null
                ? Builder(
                    builder: (context) {
                      print('Loading image for ${food.name}: ${food.imageUrl}');
                      return Image.network(
                        food.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image load error for ${food.name}: $error');
                          return Container(
                            color: AppTheme.colorPrimary.withOpacity(0.1),
                            child: const Icon(
                              Icons.restaurant,
                              size: 80,
                              color: AppTheme.colorPrimary,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppTheme.colorPrimary.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Container(
                    color: AppTheme.colorPrimary.withOpacity(0.2),
                    child: const Icon(
                      Icons.restaurant,
                      size: 80,
                      color: AppTheme.colorPrimary,
                    ),
                  ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Rank badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.colorPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            // Score badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${(food.score * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Food details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (food.cuisine != null)
                      Text(
                        food.cuisine!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildNutrientChip(
                          Icons.fitness_center,
                          '${food.keyNutrients['protein']?.toInt() ?? 0}g',
                        ),
                        const SizedBox(width: 8),
                        _buildNutrientChip(
                          Icons.local_fire_department,
                          '${food.keyNutrients['energy']?.toInt() ?? 0}cal',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutrientChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFoodList() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _recommendations!.length,
        itemBuilder: (context, index) {
          final food = _recommendations![index];
          return _buildFoodListItem(food, index);
        },
      ),
    );
  }
  
  Widget _buildFoodListItem(FoodRecommendation food, int index) {
    final scorePercent = (food.score * 100).toInt();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showFoodDetails(food),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: index < 3 
                        ? AppTheme.colorPrimary 
                        : AppTheme.colorPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index < 3 ? Colors.white : AppTheme.colorPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        food.category ?? food.cuisine ?? 'Recommended',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.colorPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Nutrients
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${food.keyNutrients['protein']?.toInt() ?? 0}g',
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${food.keyNutrients['energy']?.toInt() ?? 0}cal',
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scorePercent >= 80
                        ? Colors.green.withOpacity(0.1)
                        : scorePercent >= 70
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: scorePercent >= 80
                            ? Colors.green
                            : scorePercent >= 70
                                ? Colors.orange
                                : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$scorePercent%',
                        style: TextStyle(
                          color: scorePercent >= 80
                              ? Colors.green
                              : scorePercent >= 70
                                  ? Colors.orange
                                  : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.colorSubtext),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showSavePlanDialog();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.colorPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Plan',
                style: TextStyle(
                  color: AppTheme.colorPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFoodDetails(FoodRecommendation food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.colorSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Food image
            if (food.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  food.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: AppTheme.colorPrimary.withOpacity(0.1),
                      child: const Icon(Icons.restaurant, size: 80),
                    );
                  },
                ),
              ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: AppTheme.h1.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    if (food.cuisine != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.colorPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          food.cuisine!,
                          style: AppTheme.body.copyWith(color: AppTheme.colorPrimary),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    if (food.benefits != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.health_and_safety, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancer-Fighting Benefits',
                                  style: AppTheme.h2.copyWith(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              food.benefits!,
                              style: AppTheme.body.copyWith(
                                height: 1.5,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (food.preparation != null) ...[
                      Text('Preparation', style: AppTheme.h2),
                      const SizedBox(height: 8),
                      Text(food.preparation!, style: AppTheme.body),
                      const SizedBox(height: 16),
                    ],
                    
                    Text('Nutritional Information (per 100g)', style: AppTheme.h2),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutrientCard(
                            'Protein',
                            '${food.keyNutrients['protein']?.toInt() ?? 0}g',
                            Icons.fitness_center,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNutrientCard(
                            'Calories',
                            '${food.keyNutrients['energy']?.toInt() ?? 0}',
                            Icons.local_fire_department,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutrientCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  void _showSavePlanDialog() {
    final TextEditingController budgetController = TextEditingController();
    final TextEditingController planNameController = TextEditingController(
      text: 'My Meal Plan ${DateTime.now().toString().substring(0, 10)}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Save Meal Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: planNameController,
                decoration: InputDecoration(
                  hintText: 'Enter plan name',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Daily Budget (₹)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your daily budget',
                  prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Color(0xFFFF9800)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_recommendations!.length} foods will be saved to your diet plan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(budgetController.text) ?? 500.0;
              final planName = planNameController.text.trim();
              if (planName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a plan name')),
                );
                return;
              }
              Navigator.pop(context);
              _saveMealPlan(planName, budget);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D2D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMealPlan(String planName, double budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final estimatedCostPerFood = budget / _recommendations!.length;
      
      final mealPlanItems = _recommendations!.map((food) {
        return MealPlanItem(
          foodName: food.name,
          category: food.category,
          estimatedCost: estimatedCostPerFood,
          imageUrl: food.imageUrl,
          benefits: food.benefits,
          nutrients: food.keyNutrients,
        );
      }).toList();

      final mealPlan = SavedMealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        planName: planName,
        createdAt: DateTime.now(),
        items: mealPlanItems,
        totalBudget: budget,
        notes: 'Generated from AI recommendations on ${DateTime.now().toString().substring(0, 10)}',
      );

      List<String> savedPlans = prefs.getStringList('saved_meal_plans') ?? [];
      savedPlans.add(json.encode(mealPlan.toJson()));
      await prefs.setStringList('saved_meal_plans', savedPlans);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Meal plan saved successfully!')),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


