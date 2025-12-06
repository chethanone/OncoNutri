import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import 'cancer_type_screen.dart';

class DietaryPreferenceScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const DietaryPreferenceScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<DietaryPreferenceScreen> createState() => _DietaryPreferenceScreenState();
}

class _DietaryPreferenceScreenState extends State<DietaryPreferenceScreen> {
  String? selectedPreference;
  
  List<Map<String, dynamic>> _getPreferences(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'id': 'pure_veg',
        'label': l10n.pureVegetarian,
        'subtitle': l10n.pureVegSubtitle,
        'icon': Icons.eco,
        'color': Colors.green,
        'description': 'Lacto-vegetarian diet including milk and dairy products',
      },
      {
        'id': 'veg_egg',
        'label': l10n.vegetarianEggs,
        'subtitle': l10n.vegEggsSubtitle,
        'icon': Icons.egg_alt,
        'color': Colors.orange,
        'description': 'Ovo-lacto-vegetarian diet including eggs and dairy',
      },
      {
        'id': 'non_veg',
        'label': l10n.nonVegetarian,
        'subtitle': l10n.nonVegSubtitle,
        'icon': Icons.restaurant,
        'color': Colors.red,
        'description': 'Omnivore diet including all food types',
      },
      {
        'id': 'pescatarian',
        'label': l10n.pescatarian,
        'subtitle': l10n.pescatarianSubtitle,
        'icon': Icons.set_meal,
        'color': Colors.blue,
        'description': 'Plant-based diet with fish and seafood',
      },
      {
        'id': 'vegan',
        'label': l10n.vegan,
        'subtitle': l10n.veganSubtitle,
        'icon': Icons.spa,
        'color': Colors.lightGreen,
        'description': 'Completely plant-based, no dairy or eggs',
      },
      {
        'id': 'jain',
        'label': l10n.jain,
        'subtitle': l10n.jainSubtitle,
        'icon': Icons.self_improvement,
        'color': Colors.amber,
        'description': 'Strict vegetarian following Jain principles',
      },
    ];
  }
  
  @override
  void initState() {
    super.initState();
    selectedPreference = widget.intakeData.dietaryPreference;
  }
  
  void _continue() {
    if (selectedPreference != null) {
      widget.intakeData.dietaryPreference = selectedPreference;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CancerTypeScreen(intakeData: widget.intakeData),
        ),
      );
    }
  }
  
  void _showPreferenceDetails(Map<String, dynamic> preference) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.colorDarkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (preference['color'] as Color).withOpacity(isDark ? 0.3 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    preference['icon'],
                    color: preference['color'],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preference['label'],
                        style: AppTheme.h2.copyWith(
                          color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                        ),
                      ),
                      Text(
                        preference['subtitle'],
                        style: AppTheme.caption.copyWith(
                          color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              preference['description'],
              style: AppTheme.body.copyWith(
                color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: selectedPreference == preference['id'] 
                    ? 'Deselect ${preference['label']}'
                    : 'Select ${preference['label']}',
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Allow deselection by clicking the same option
                    if (selectedPreference == preference['id']) {
                      selectedPreference = null;
                    } else {
                      selectedPreference = preference['id'];
                    }
                  });
                },
                fullWidth: true,
              ),
            ),
          ],
        ),
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
                          'Dietary Preference',
                          style: AppTheme.h2.copyWith(
                            color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.dietaryPreferenceQuestion,
                      style: AppTheme.h1.copyWith(
                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.dietaryPreferenceSubtitle,
                      style: AppTheme.body.copyWith(
                        color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Preference cards
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
                  itemCount: _getPreferences(context).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pref = _getPreferences(context)[index];
                    final isSelected = selectedPreference == pref['id'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPreference = pref['id'];
                        });
                      },
                      onLongPress: () => _showPreferenceDetails(pref),
                      child: AnimatedContainer(
                        duration: AppTheme.fadeInDuration,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (pref['color'] as Color).withOpacity(isDark ? 0.2 : 0.1)
                              : (isDark ? AppTheme.colorDarkSurface : AppTheme.colorSurface),
                          border: Border.all(
                            color: isSelected
                                ? pref['color']
                                : (isDark ? AppTheme.colorDarkBorder : AppTheme.colorBorder),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                          boxShadow: (isSelected && !isDark)
                              ? AppTheme.selectedShadow
                              : (!isDark ? AppTheme.defaultShadow : []),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (pref['color'] as Color).withOpacity(isDark ? 0.3 : 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  pref['icon'],
                                  color: pref['color'],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pref['label'],
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pref['subtitle'],
                                      style: AppTheme.caption.copyWith(
                                        color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Info button
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                  color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                                  size: 20,
                                ),
                                onPressed: () => _showPreferenceDetails(pref),
                              ),
                              // Check mark
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: pref['color'],
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                child: Column(
                  children: [
                    Text(
                      'Long press any option for more details',
                      style: AppTheme.caption.copyWith(
                        color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: AppLocalizations.of(context)!.continueButton,
                      onPressed: selectedPreference != null ? _continue : null,
                      fullWidth: true,
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


