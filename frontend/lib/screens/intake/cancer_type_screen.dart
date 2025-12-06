import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import '../../services/gemini_service.dart';
import '../../providers/theme_provider.dart';
import 'treatment_stage_screen.dart';

class CancerTypeScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const CancerTypeScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<CancerTypeScreen> createState() => _CancerTypeScreenState();
}

class _CancerTypeScreenState extends State<CancerTypeScreen> {
  String? selectedType;
  final TextEditingController _customTypeController = TextEditingController();
  bool _isProcessingCustomInput = false;
  
  List<Map<String, dynamic>> _getCancerTypes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'id': 'Breast Cancer', 'name': l10n.breastCancer, 'icon': Icons.favorite_rounded, 'color': Color(0xFFFF6B9D)},
      {'id': 'Lung Cancer', 'name': l10n.lungCancer, 'icon': Icons.air_rounded, 'color': Color(0xFF64B5F6)},
      {'id': 'Colorectal Cancer', 'name': l10n.colorectalCancer, 'icon': Icons.local_hospital_rounded, 'color': Color(0xFF9575CD)},
      {'id': 'Prostate Cancer', 'name': l10n.prostateCancer, 'icon': Icons.medical_services_rounded, 'color': Color(0xFF4DD0E1)},
      {'id': 'Stomach Cancer', 'name': l10n.stomachCancer, 'icon': Icons.restaurant_rounded, 'color': Color(0xFFFFB74D)},
      {'id': 'Liver Cancer', 'name': l10n.liverCancer, 'icon': Icons.healing_rounded, 'color': Color(0xFFA1887F)},
      {'id': 'Pancreatic Cancer', 'name': l10n.pancreaticCancer, 'icon': Icons.science_rounded, 'color': Color(0xFF81C784)},
      {'id': 'Kidney Cancer', 'name': l10n.kidneyCancer, 'icon': Icons.water_drop_rounded, 'color': Color(0xFF4FC3F7)},
      {'id': 'Bladder Cancer', 'name': l10n.bladderCancer, 'icon': Icons.bubble_chart_rounded, 'color': Color(0xFF90CAF9)},
      {'id': 'Thyroid Cancer', 'name': l10n.thyroidCancer, 'icon': Icons.thermostat_rounded, 'color': Color(0xFFBA68C8)},
      {'id': 'Skin Cancer', 'name': l10n.skinCancer, 'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFFFD54F)},
      {'id': 'Blood Cancer', 'name': l10n.bloodCancer, 'icon': Icons.bloodtype_rounded, 'color': Color(0xFFEF5350)},
    ];
  }
  
  @override
  void initState() {
    super.initState();
    // Don't pre-select any type
    selectedType = null;
  }
  
  @override
  void dispose() {
    _customTypeController.dispose();
    super.dispose();
  }
  
  void _handleSelection(String type) {
    setState(() {
      // Allow deselection by tapping the same option again
      if (selectedType == type) {
        selectedType = null;
      } else {
        selectedType = type;
      }
    });
  }
  
  Future<void> _processCustomInput() async {
    if (_customTypeController.text.trim().isEmpty) return;
    
    setState(() {
      _isProcessingCustomInput = true;
    });
    
    try {
      // Use Gemini to understand and standardize the input
      final processedInput = await GeminiService.understandCancerType(
        _customTypeController.text.trim()
      );
      
      setState(() {
        selectedType = processedInput;
        _isProcessingCustomInput = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.understoodInput}: $processedInput'),
            backgroundColor: AppTheme.colorSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingCustomInput = false;
        selectedType = _customTypeController.text.trim();
      });
    }
  }
  
  void _continue() {
    if (selectedType != null) {
      widget.intakeData.cancerType = selectedType;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TreatmentStageScreen(intakeData: widget.intakeData),
        ),
      );
    }
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
                          'Cancer Type',
                          style: AppTheme.h2.copyWith(
                            color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.cancerTypeQuestion,
                      style: AppTheme.h1.copyWith(
                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.cancerTypeSubtitle,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Cancer type grid
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
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _getCancerTypes(context).length,
                        itemBuilder: (context, index) {
                          final type = _getCancerTypes(context)[index];
                          final isSelected = selectedType == type['id'];
                          
                          return InkWell(
                            onTap: () => _handleSelection(type['id']),
                            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppTheme.primaryColor(context).withOpacity(0.15)
                                    : AppTheme.surfaceColor(context),
                                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppTheme.primaryColor(context) 
                                      : AppTheme.borderColor(context),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: AppTheme.defaultShadow,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type['icon'],
                                    size: 32,
                                    color: isSelected 
                                        ? AppTheme.primaryColor(context) 
                                        : AppTheme.subtextColor(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    type['name'],
                                    textAlign: TextAlign.center,
                                    style: AppTheme.bodyMedium.copyWith(
                                        color: isSelected 
                                          ? AppTheme.primaryColor(context) 
                                          : Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.colorText,
                                      fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppTheme.primaryColor(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Custom input section with professional design
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor(context).withOpacity(0.05),
                              AppTheme.surfaceColor(context),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor(context).withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor(context).withOpacity(0.08),
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
                                    color: AppTheme.primaryColor(context).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: AppTheme.primaryColor(context),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Other Cancer Type',
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
                                          color: AppTheme.primaryColor(context).withOpacity(0.8),
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
                              'Can\'t find your cancer type? Type it below and our AI will help identify and process it.',
                              style: AppTheme.caption.copyWith(
                                color: isDark ? AppTheme.colorDarkSubtext : AppTheme.subtextColor(context),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.colorDarkSurface : Colors.white,
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
                                controller: _customTypeController,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g., Bone cancer, Brain cancer, Ovarian cancer...',
                                  hintStyle: TextStyle(
                                    color: (isDark ? AppTheme.colorDarkSubtext : AppTheme.subtextColor(context)).withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.primaryColor(context).withOpacity(0.7),
                                    size: 22,
                                  ),
                                  suffixIcon: _isProcessingCustomInput
                                      ? Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryColor(context),
                                              ),
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: AppTheme.primaryColor(context),
                                          ),
                                          tooltip: 'Process with AI',
                                          onPressed: _processCustomInput,
                                        ),
                                  filled: true,
                                  fillColor: isDark ? AppTheme.colorDarkSurface : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderColor(context),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderColor(context).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor(context),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _processCustomInput(),
                                textCapitalization: TextCapitalization.words,
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
                child: PrimaryButton(
                  label: AppLocalizations.of(context)!.continueButton,
                  onPressed: selectedType != null ? _continue : null,
                  fullWidth: true,
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


