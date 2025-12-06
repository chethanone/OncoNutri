import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';
import '../../providers/theme_provider.dart';
import '../food_recommendations_screen_v2.dart';
import '../user_history_screen.dart';

class AllergiesScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const AllergiesScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  Set<String> selectedAllergies = {};
  final TextEditingController _customAllergyController = TextEditingController();
  bool _isProcessingCustomInput = false;
  
  List<Map<String, dynamic>> allergyOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Get dietary preference from intake data
    final dietaryPref = widget.intakeData.dietaryPreference?.toLowerCase() ?? '';
    
    // Base allergen options that apply to everyone
    List<Map<String, dynamic>> baseOptions = [
      {'id': 'Dairy', 'label': l10n.dairy, 'icon': Icons.water_drop, 'subtitle': l10n.dairySubtitle},
      {'id': 'Gluten', 'label': l10n.gluten, 'icon': Icons.grain, 'subtitle': l10n.glutenSubtitle},
      {'id': 'Nuts', 'label': l10n.nuts, 'icon': Icons.nature, 'subtitle': l10n.nutsSubtitle},
      {'id': 'Soy', 'label': l10n.soy, 'icon': Icons.eco, 'subtitle': l10n.soySubtitle},
      {'id': 'Diabetic', 'label': l10n.diabeticDiet, 'icon': Icons.monitor_heart, 'subtitle': l10n.diabeticSubtitle},
      {'id': 'Low Sodium', 'label': l10n.lowSodium, 'icon': Icons.no_food, 'subtitle': l10n.lowSodiumSubtitle},
    ];
    
    // Add non-veg allergens only if dietary preference allows them
    if (dietaryPref.contains('pure_veg') || dietaryPref.contains('veg') || dietaryPref.contains('jain')) {
      // Pure Veg/Jain: Already excludes all non-veg, so no need to show as allergens
      // Don't add Eggs, Seafood, Meat, Poultry
    } else if (dietaryPref.contains('vegan')) {
      // Vegan: Already excludes all animal products, so no need to show as allergens
      // Don't add Eggs, Dairy, Seafood, Meat, Poultry
      baseOptions.removeWhere((option) => option['id'] == 'Dairy'); // Already excluded by vegan
    } else if (dietaryPref.contains('veg') && dietaryPref.contains('egg')) {
      // Veg+Egg: Can have eggs and dairy, but not meat/seafood
      // Don't add Seafood, Meat, Poultry (already excluded)
      baseOptions.insert(3, {'id': 'Eggs', 'label': l10n.eggs, 'icon': Icons.egg, 'subtitle': l10n.eggsSubtitle});
    } else if (dietaryPref.contains('pesc')) {
      // Pescatarian: Can have seafood and eggs, but not meat/poultry
      // Don't add Meat, Poultry (already excluded)
      baseOptions.insert(3, {'id': 'Eggs', 'label': l10n.eggs, 'icon': Icons.egg, 'subtitle': l10n.eggsSubtitle});
      baseOptions.insert(4, {'id': 'Seafood', 'label': l10n.seafood, 'icon': Icons.set_meal, 'subtitle': l10n.seafoodSubtitle});
    } else {
      // Non-Veg: Show all allergen options
      baseOptions.insert(3, {'id': 'Eggs', 'label': l10n.eggs, 'icon': Icons.egg, 'subtitle': l10n.eggsSubtitle});
      baseOptions.insert(4, {'id': 'Seafood', 'label': l10n.seafood, 'icon': Icons.set_meal, 'subtitle': l10n.seafoodSubtitle});
      baseOptions.insert(5, {'id': 'Red Meat', 'label': l10n.redMeat, 'icon': Icons.restaurant, 'subtitle': l10n.redMeatSubtitle});
      baseOptions.insert(6, {'id': 'Poultry', 'label': l10n.poultry, 'icon': Icons.food_bank, 'subtitle': l10n.poultrySubtitle});
    }
    
    return baseOptions;
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.intakeData.allergies != null) {
      selectedAllergies = Set<String>.from(widget.intakeData.allergies!);
    }
  }
  
  @override
  void dispose() {
    _customAllergyController.dispose();
    super.dispose();
  }
  
  void _handleToggle(String allergy) {
    setState(() {
      if (selectedAllergies.contains(allergy)) {
        selectedAllergies.remove(allergy);
      } else {
        selectedAllergies.add(allergy);
      }
    });
  }
  
  Future<void> _processCustomAllergy() async {
    if (_customAllergyController.text.trim().isEmpty) return;
    
    setState(() {
      _isProcessingCustomInput = true;
    });
    
    try {
      // Use Gemini to understand and categorize the allergy
      final processedAllergies = await GeminiService.understandAllergies(
        _customAllergyController.text.trim()
      );
      
      setState(() {
        for (var allergy in processedAllergies) {
          selectedAllergies.add(allergy);
        }
        _isProcessingCustomInput = false;
        _customAllergyController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.addedAllergies}: ${processedAllergies.join(", ")}'),
            backgroundColor: AppTheme.colorSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingCustomInput = false;
        // Add as-is if processing fails
        selectedAllergies.add(_customAllergyController.text.trim());
        _customAllergyController.clear();
      });
    }
  }
  
  void _continue() async {
    widget.intakeData.allergies = selectedAllergies.toList();
    widget.intakeData.dietaryRestrictions = selectedAllergies.toList();
    
    // Mark intake as completed
    await AuthService.setIntakeCompleted();
    
    // Log history
    final allergiesText = selectedAllergies.isEmpty ? 'No allergies' : selectedAllergies.join(', ');
    await HistoryLogger.logEvent(
      type: 'recommendation',
      title: 'New Recommendations Generated',
      description: 'Generated personalized diet recommendations with preferences: $allergiesText',
    );
    
    // Navigate to recommendations
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodRecommendationsScreenV2(intakeData: widget.intakeData),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Food Restrictions',
                          style: AppTheme.h2.copyWith(
                            color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.allergiesQuestion,
                      style: AppTheme.h1.copyWith(
                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.allergiesSubtitle,
                      style: AppTheme.body.copyWith(
                        color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Allergy cards in scrollable grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: allergyOptions(context).length,
                        itemBuilder: (context, index) {
                          final option = allergyOptions(context)[index];
                          final isSelected = selectedAllergies.contains(option['id']);
                          
                          return InkWell(
                            onTap: () => _handleToggle(option['id']),
                            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? (isDark ? AppTheme.colorPrimary.withOpacity(0.2) : AppTheme.colorPrimary.withOpacity(0.15))
                                    : (isDark ? AppTheme.colorDarkSurface : Colors.white),
                                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppTheme.colorPrimary 
                                      : (isDark ? AppTheme.colorDarkBorder : Colors.grey.shade300),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isDark ? [] : AppTheme.defaultShadow,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    option['icon'],
                                    size: 32,
                                    color: isSelected 
                                        ? AppTheme.colorPrimary 
                                        : (isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    option['label'],
                                    textAlign: TextAlign.center,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: isSelected 
                                          ? AppTheme.colorPrimary 
                                          : (isDark ? AppTheme.colorDarkText : AppTheme.colorText),
                                      fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option['subtitle'],
                                    textAlign: TextAlign.center,
                                    style: AppTheme.caption.copyWith(
                                      color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppTheme.colorPrimary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Custom input section with professional design (matching cancer type screen)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isDark 
                              ? null
                              : LinearGradient(
                                  colors: [
                                    AppTheme.colorPrimary.withOpacity(0.05),
                                    Colors.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: isDark ? AppTheme.colorDarkSurface : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.colorPrimary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: AppTheme.colorPrimary.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: AppTheme.colorPrimary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.otherAllergies,
                                        style: AppTheme.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'AI-powered understanding',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.colorPrimary.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.otherAllergiesDesc,
                              style: AppTheme.caption.copyWith(
                                color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.colorDarkBackground : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isDark ? [] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _customAllergyController,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.otherAllergiesPlaceholder,
                                  hintStyle: TextStyle(
                                    color: (isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext).withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.edit_note_rounded,
                                    color: AppTheme.colorPrimary.withOpacity(0.7),
                                  ),
                                  suffixIcon: _isProcessingCustomInput
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isDark ? AppTheme.colorPrimary : AppTheme.colorPrimary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: AppTheme.colorPrimary,
                                          ),
                                          onPressed: _processCustomAllergy,
                                        ),
                                  filled: true,
                                  fillColor: isDark ? AppTheme.colorDarkBackground : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.colorPrimary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                onSubmitted: (_) => _processCustomAllergy(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: AppLocalizations.of(context)!.getRecommendations,
                      onPressed: selectedAllergies.isNotEmpty ? _continue : null,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // Skip allergies, set to empty
                        widget.intakeData.allergies = [];
                        widget.intakeData.dietaryRestrictions = [];
                        _continue();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.skipNoAllergies,
                        style: TextStyle(
                          color: AppTheme.colorSubtext,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


