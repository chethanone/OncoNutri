import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intake_data.dart';
import '../models/food_recommendation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/ui_components.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';

class FoodRecommendationsScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const FoodRecommendationsScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<FoodRecommendationsScreen> createState() => _FoodRecommendationsScreenState();
}

class _FoodRecommendationsScreenState extends State<FoodRecommendationsScreen> {
  List<FoodRecommendation>? _recommendations;
  bool _isLoading = true;
  String? _error;
  
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
      // Get auth token
      final token = await AuthService.getValidToken();
      print('🔑 Loading recommendations with token: ${token != null ? "Present" : "Missing"}');
      
      final recommendations = await ApiService.getRecommendations(widget.intakeData, token: token);
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recommendations: $e'); // Debug log
      setState(() {
        _error = 'Failed to load recommendations. Please check your connection and try again.\n\nError: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.colorSuccess,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Analyzing your profile',
                      style: AppTheme.h2.copyWith(
                        color: AppTheme.colorText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Our AI is finding the best foods for you',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.colorSubtext,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
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
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTheme.body.copyWith(
                              color: AppTheme.colorSubtext,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loadRecommendations,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.colorPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusButton,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Try Again',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildPlanSummaryHeader(),
                      Expanded(
                        child: _buildCompleteNutritionPlan(),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
      ),
    );
  }
                              'Something went wrong',
                              style: AppTheme.h2,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: AppTheme.body.copyWith(
                                color: AppTheme.subtextColor(context),
                              ),
                            ),
                            const SizedBox(height: 32),
                            PrimaryButton(
                              label: 'Try Again',
                              onPressed: _loadRecommendations,
                              fullWidth: true,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Header with Plan Summary
                        _buildPlanSummaryHeader(),
                        // Complete Food List (no tabs)
                        Expanded(
                          child: _buildCompleteNutritionPlan(),
                        ),
                        // Action Buttons
                        _buildActionButtons(),
                      ],
                    ),
        ),
      ),
    );
  }
  
  Widget _buildPlanSummaryHeader() {
    double totalCalories = 0;
    double totalProtein = 0;
    
    if (_recommendations != null) {
      for (var rec in _recommendations!) {
        totalCalories += (rec.keyNutrients['energy'] ?? 0);
        totalProtein += (rec.keyNutrients['protein'] ?? 0);
      }
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.horizontalPadding,
        AppTheme.spaceMd,
        AppTheme.horizontalPadding,
        AppTheme.spaceMd,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.colorSuccess,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Daily Plan',
                      style: AppTheme.h2.copyWith(
                        fontSize: 20,
                        color: AppTheme.colorText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_recommendations?.length ?? 0} personalized recommendations',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.colorSubtext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${_recommendations?.length ?? 0}',
                  'Foods',
                  Icons.restaurant_rounded,
                  AppTheme.colorAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '${totalProtein.toInt()}g',
                  'Protein',
                  Icons.fitness_center_rounded,
                  AppTheme.colorAccentSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '${totalCalories.toInt()}',
                  'Calories',
                  Icons.local_fire_department_rounded,
                  AppTheme.colorWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.h3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              fontSize: 12,
              color: AppTheme.colorSubtext,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompleteNutritionPlan() {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return Center(
        child: Text(
          'No recommendations available',
          style: AppTheme.body.copyWith(color: AppTheme.colorSubtext),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.horizontalPadding,
        0,
        AppTheme.horizontalPadding,
        AppTheme.horizontalPadding,
      ),
      itemCount: _recommendations!.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations![index];
        return _buildFoodCard(recommendation, index);
      },
    );
  }
  
  Widget _buildFoodCard(FoodRecommendation recommendation, int index) {
    final scorePercent = (recommendation.score * 100).toInt();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          onTap: () => _showFoodDetails(recommendation),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: AppTheme.colorBorder,
                width: 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: index < 3
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.colorSuccess,
                                  Color(0xFF66BB6A),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: index < 3 ? null : AppTheme.colorCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index < 3
                                ? Colors.white
                                : AppTheme.colorPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Food name and score
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.foodName,
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colorText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.colorSuccess.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: AppTheme.colorSuccess,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$scorePercent% match',
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.colorSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.colorSubtext,
                      size: 24,
                    ),
                  ],
                ),
                if (recommendation.reason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.colorCream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppTheme.colorPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recommendation.reason,
                            style: AppTheme.caption.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: AppTheme.colorSubtext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.name,
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category
                          if (recommendation.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                  color: AppTheme.primary400Color(context).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  recommendation.category!,
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.primaryColor(context),
                                    fontSize: 10,
                                  ),
                                ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Protein content
                          Icon(
                            Icons.fitness_center,
                            size: 12,
                            color: AppTheme.subtextColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recommendation.keyNutrients['protein']?.toStringAsFixed(1) ?? '0'}g',
                            style: AppTheme.caption,
                          ),
                          const SizedBox(width: 12),
                          // Calorie content
                          Icon(
                            Icons.local_fire_department,
                            size: 12,
                            color: AppTheme.subtextColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recommendation.keyNutrients['energy']?.toStringAsFixed(0) ?? '0'}kcal',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Score indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(recommendation.score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: _getScoreColor(recommendation.score),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$scorePercent%',
                        style: AppTheme.body.copyWith(
                          color: _getScoreColor(recommendation.score),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.subtextColor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppTheme.colorSuccess;
    if (score >= 0.6) return AppTheme.colorPrimary;
    return AppTheme.colorWarning;
  }
  
  Widget _buildMealList(int day) {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return Center(
        child: Text(
          'No recommendations available',
          style: AppTheme.body.copyWith(color: AppTheme.colorSubtext),
        ),
      );
    }
    
    // Show different foods for each day by cycling through the recommendations
    // Day 0: items 0,1,2,3  Day 1: items 1,2,3,4  Day 2: items 2,3,4,5
    final int startIndex = day;
    final int itemsPerDay = 4; // Breakfast, Lunch, Snack, Dinner
    
    final dayRecommendations = <FoodRecommendation>[];
    for (int i = 0; i < itemsPerDay; i++) {
      final index = (startIndex + i) % _recommendations!.length;
      dayRecommendations.add(_recommendations![index]);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.horizontalPadding),
      itemCount: dayRecommendations.length,
      itemBuilder: (context, index) {
        return _buildMealCard(dayRecommendations[index], index);
      },
    );
  }
  
  Widget _buildMealCard(FoodRecommendation recommendation, int index) {
    final mealTimes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
    final mealTime = mealTimes[index % mealTimes.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMealDetails(recommendation, mealTime),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Plate icon (36px as per spec)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary400Color(context).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: AppTheme.primaryColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Title (16px semi-bold)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        recommendation.name,
                        style: AppTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        mealTime,
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                // Kcal + Protein (right stacked)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(recommendation.keyNutrients['energy'] ?? 0).toInt()} kcal',
                      style: AppTheme.bodyMedium.copyWith(fontSize: 14),
                    ),
                    Text(
                      '${(recommendation.keyNutrients['protein'] ?? 0).toInt()}g protein',
                      style: AppTheme.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showFoodDetails(FoodRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.colorBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Food name
              Text(
                recommendation.name,
                style: AppTheme.h1,
              ),
              const SizedBox(height: 8),
              // Category and score
              Row(
                children: [
                  if (recommendation.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary400Color(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recommendation.category!,
                        style: AppTheme.body.copyWith(
                          color: AppTheme.colorPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(recommendation.score).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: _getScoreColor(recommendation.score),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(recommendation.score * 100).toInt()}% Match',
                          style: AppTheme.body.copyWith(
                            color: _getScoreColor(recommendation.score),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Nutrients
              Text(
                'Key Nutrients (per 100g)',
                style: AppTheme.h2.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...recommendation.keyNutrients.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatNutrientName(entry.key),
                        style: AppTheme.body,
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)} ${_getNutrientUnit(entry.key)}',
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              // Why recommended
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary400Color(context).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary400Color(context).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.primaryColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Why recommended for you',
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRecommendationReason(recommendation),
                      style: AppTheme.body.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Add to Diet Plan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _addToDietPlan(recommendation);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add to Diet Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Future<void> _addToDietPlan(FoodRecommendation recommendation) async {
    try {
      // Get auth token
      final token = await AuthService.getValidToken();
      
      // Save to backend API
      final success = await ApiService.saveFoodToDietPlan(
        recommendation,
        mealType: 'snack', // You can add logic to determine meal type
        token: token,
      );
      
      if (!success) {
        throw Exception('API call failed');
      }
      
      // Also save to SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      final selectedFoodsJson = prefs.getStringList('selected_diet_foods') ?? [];
      
      // Check if already added locally
      final existingIds = selectedFoodsJson.map((json) {
        final decoded = jsonDecode(json);
        return decoded['fdcId'] as int;
      }).toList();
      
      if (!existingIds.contains(recommendation.fdcId)) {
        selectedFoodsJson.add(jsonEncode(recommendation.toJson()));
        await prefs.setStringList('selected_diet_foods', selectedFoodsJson);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${recommendation.name} ${AppLocalizations.of(context)!.dietPlanAdded}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.colorAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error adding to diet plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dietPlanAddFailed),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
  
  String _formatNutrientName(String key) {
    final names = {
      'protein': 'Protein',
      'energy': 'Energy',
      'carbohydrate': 'Carbohydrates',
      'fiber': 'Fiber',
      'fat': 'Fat',
      'iron': 'Iron',
      'calcium': 'Calcium',
      'vitamin_a': 'Vitamin A',
      'vitamin_c': 'Vitamin C',
      'vitamin_d': 'Vitamin D',
    };
    return names[key] ?? key.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }
  
  String _getNutrientUnit(String key) {
    if (key == 'energy') return 'kcal';
    if (key.startsWith('vitamin')) return 'IU';
    return 'g';
  }
  
  String _getRecommendationReason(FoodRecommendation recommendation) {
    final protein = recommendation.keyNutrients['protein'] ?? 0;
    final energy = recommendation.keyNutrients['energy'] ?? 0;
    
    List<String> reasons = [];
    
    if (protein > 10) {
      reasons.add('High in protein to support recovery');
    } else if (protein > 5) {
      reasons.add('Good protein content for healing');
    }
    
    if (energy > 200) {
      reasons.add('Provides sustained energy');
    }
    
    if (recommendation.category?.toLowerCase() == 'pulses') {
      reasons.add('Rich in fiber and nutrients');
    }
    
    if (recommendation.category?.toLowerCase() == 'vegetable') {
      reasons.add('Packed with vitamins and antioxidants');
    }
    
    if (reasons.isEmpty) {
      reasons.add('Selected based on your specific nutritional needs and cancer type');
    }
    
    return reasons.join('. ') + '.';
  }
  
  void _showMealDetails(FoodRecommendation recommendation, String mealTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
        builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
        ),
        child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary400Color(context).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                            child: Icon(
                              Icons.restaurant,
                              color: AppTheme.primaryColor(context),
                            ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.name,
                                style: AppTheme.h2,
                              ),
                              Text(
                                mealTime,
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Nutrition Facts', style: AppTheme.bodyMedium),
                    const SizedBox(height: 12),
                    _buildNutrientRow('Calories', '${(recommendation.keyNutrients['energy'] ?? 0).toInt()} kcal'),
                    _buildNutrientRow('Protein', '${(recommendation.keyNutrients['protein'] ?? 0).toInt()}g'),
                    _buildNutrientRow('Fiber', '${(recommendation.keyNutrients['fiber'] ?? 0).toInt()}g'),
                    _buildNutrientRow('Vitamin C', '${(recommendation.keyNutrients['vitamin_c'] ?? 0).toInt()}mg'),
                    const SizedBox(height: 16),
                    Text('Category', style: AppTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(recommendation.category ?? 'Unknown'),
                      backgroundColor: AppTheme.primary400Color(context).withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Close',
                      onPressed: () => Navigator.pop(context),
                      fullWidth: true,
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
  
  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body),
          Text(value, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.horizontalPadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colorShadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Save Plan',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.dietPlanSaved)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Go to Home',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



