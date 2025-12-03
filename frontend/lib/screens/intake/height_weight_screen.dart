import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import 'dietary_preference_screen.dart';

class HeightWeightScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const HeightWeightScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.intakeData.height != null) {
      _heightController.text = widget.intakeData.height.toString();
    }
    if (widget.intakeData.weight != null) {
      _weightController.text = widget.intakeData.weight.toString();
    }
  }
  
  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  double? _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (height == null || weight == null || height <= 0) return null;
    
    // BMI = weight (kg) / (height (m))^2
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }
  
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  void _showBMIWarning(String category, double bmi) {
    if (category == 'Normal') return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              category == 'Underweight' ? Icons.warning_amber : Icons.info_outline,
              color: category == 'Underweight' ? AppTheme.colorWarning : AppTheme.colorDanger,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'BMI Alert',
                style: AppTheme.h2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (category == 'Underweight' ? AppTheme.colorWarning : AppTheme.colorDanger).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (category == 'Underweight' ? AppTheme.colorWarning : AppTheme.colorDanger).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your BMI: ${bmi.toStringAsFixed(1)}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: $category',
                    style: AppTheme.body.copyWith(
                      color: category == 'Underweight' ? AppTheme.colorWarning : AppTheme.colorDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category == 'Underweight'
                  ? 'Your BMI indicates you may be underweight. Our nutrition plan will focus on healthy weight gain and nutrient-dense foods.'
                  : 'Your BMI indicates you may be overweight. Our nutrition plan will be tailored to help you achieve a healthier weight while supporting your treatment.',
              style: AppTheme.body.copyWith(
                color: AppTheme.subtextColor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to next screen after user acknowledges the warning
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DietaryPreferenceScreen(intakeData: widget.intakeData),
                ),
              );
            },
            child: Text(
              'I Understood',
              style: TextStyle(
                color: AppTheme.primaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _continue() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid height and weight'),
          backgroundColor: AppTheme.colorDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    widget.intakeData.height = height;
    widget.intakeData.weight = weight;
    
    final bmi = _calculateBMI();
    if (bmi != null) {
      final category = _getBMICategory(bmi);
      
      if (category != 'Normal') {
        // Show warning and wait for user to click "I Understood"
        _showBMIWarning(category, bmi);
        // Navigation happens in the dialog button callback
      } else {
        // Navigate immediately if BMI is normal
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DietaryPreferenceScreen(intakeData: widget.intakeData),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBMI();
    
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
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Health Metrics',
                          style: AppTheme.h2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What is your height and weight?',
                      style: AppTheme.h1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us calculate your BMI and personalize your nutrition plan',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Input fields
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
                  child: Column(
                    children: [
                      // Height input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor(context)),
                          boxShadow: AppTheme.defaultShadow,
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
                                    Icons.height,
                                    color: AppTheme.primaryColor(context),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Height',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: 'Enter height',
                                suffixText: 'cm',
                                suffixStyle: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.subtextColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: Icon(
                                  Icons.straighten,
                                  color: AppTheme.primaryColor(context),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor(context),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Weight input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor(context)),
                          boxShadow: AppTheme.defaultShadow,
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
                                    Icons.monitor_weight,
                                    color: AppTheme.primaryColor(context),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Weight',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: 'Enter weight',
                                suffixText: 'kg',
                                suffixStyle: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.subtextColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: Icon(
                                  Icons.scale,
                                  color: AppTheme.primaryColor(context),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor(context),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // BMI Display
                      if (bmi != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor(context).withOpacity(0.1),
                                AppTheme.primaryColor(context).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor(context).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: AppTheme.primaryColor(context),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Your BMI',
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    bmi.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'kg/m²',
                                    style: AppTheme.body.copyWith(
                                      color: AppTheme.subtextColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getBMICategory(bmi) == 'Normal'
                                      ? AppTheme.colorSuccess.withOpacity(0.2)
                                      : (_getBMICategory(bmi) == 'Underweight'
                                          ? AppTheme.colorWarning.withOpacity(0.2)
                                          : AppTheme.colorDanger.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getBMICategory(bmi),
                                  style: TextStyle(
                                    color: _getBMICategory(bmi) == 'Normal'
                                        ? AppTheme.colorSuccess
                                        : (_getBMICategory(bmi) == 'Underweight'
                                            ? AppTheme.colorWarning
                                            : AppTheme.colorDanger),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              // Continue button
              Padding(
                padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                child: PrimaryButton(
                  label: 'Continue',
                  onPressed: (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty)
                      ? _continue
                      : null,
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


