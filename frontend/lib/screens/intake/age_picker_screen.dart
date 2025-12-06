import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import 'height_weight_screen.dart';

class AgePickerScreen extends StatefulWidget {
  final IntakeData? intakeData;
  
  const AgePickerScreen({Key? key, this.intakeData}) : super(key: key);
  
  @override
  State<AgePickerScreen> createState() => _AgePickerScreenState();
}

class _AgePickerScreenState extends State<AgePickerScreen> {
  late IntakeData _intakeData;
  String? selectedAgeRange;
  
  final List<String> ageRanges = [
    '18-29',
    '30-39',
    '40-49',
    '50-59',
    '60-69',
    '70-79',
    '80+',
  ];
  
  @override
  void initState() {
    super.initState();
    _intakeData = widget.intakeData ?? IntakeData();
    selectedAgeRange = _intakeData.ageRange;
  }
  
  void _continue() {
    if (selectedAgeRange != null) {
      _intakeData.ageRange = selectedAgeRange;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HeightWeightScreen(intakeData: _intakeData),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.colorDarkBackground : AppTheme.colorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header with back button
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.colorDarkSurface : AppTheme.colorSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? [] : AppTheme.defaultShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Title and subtitle
              Text(
                AppLocalizations.of(context)!.ageQuestion,
                style: AppTheme.h1.copyWith(
                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.ageSubtitle,
                style: AppTheme.body.copyWith(
                  color: isDark ? AppTheme.colorDarkSubtext : AppTheme.colorSubtext,
                ),
              ),
              const SizedBox(height: 32),
              // Age options
              Expanded(
                child: ListView.separated(
                  itemCount: ageRanges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ageRange = ageRanges[index];
                    final isSelected = selectedAgeRange == ageRange;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          // Allow deselection by tapping the same option again
                          if (selectedAgeRange == ageRange) {
                            selectedAgeRange = null;
                          } else {
                            selectedAgeRange = ageRange;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppTheme.colorSuccess.withOpacity(0.2) : AppTheme.colorSuccess.withOpacity(0.1))
                              : (isDark ? AppTheme.colorDarkSurface : AppTheme.colorSurface),
                          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.colorSuccess
                                : (isDark ? AppTheme.colorDarkBorder : AppTheme.colorBorder),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: (isSelected && !isDark)
                              ? AppTheme.selectedShadow
                              : (!isDark ? AppTheme.cardShadow : []),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.colorSuccess
                                    : (isDark ? AppTheme.colorDarkBorder : AppTheme.colorCream),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppTheme.colorDarkText : AppTheme.colorPrimary),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '$ageRange ${AppLocalizations.of(context)!.ageYears}',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppTheme.colorSuccess,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedAgeRange != null ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary,
                    disabledBackgroundColor: isDark ? AppTheme.colorDarkBorder : AppTheme.colorBorder,
                    foregroundColor: isDark ? AppTheme.colorDarkBackground : Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTheme.bodyLarge.copyWith(
                      color: isDark ? AppTheme.colorDarkBackground : Colors.white,
                      fontSize: 16,
                    ),
                  ),
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


