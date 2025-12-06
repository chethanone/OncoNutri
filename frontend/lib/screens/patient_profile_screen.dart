import 'package:flutter/material.dart';
import '../models/patient_profile.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _otherConditionsController = TextEditingController();
  
  String? _selectedCancerType;
  String? _selectedStage;
  bool _isLoading = false;

  final List<String> _cancerTypes = [
    'Breast Cancer',
    'Lung Cancer',
    'Colorectal Cancer',
    'Prostate Cancer',
    'Stomach Cancer',
    'Liver Cancer',
    'Other',
  ];

  final List<String> _stages = ['Stage I', 'Stage II', 'Stage III', 'Stage IV'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _otherConditionsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = PatientProfile(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        cancerType: _selectedCancerType!,
        stage: _selectedStage!,
        allergies: _allergiesController.text,
        otherConditions: _otherConditionsController.text,
      );

      final success = await ApiService().savePatientProfile(profile);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.profileSavedSuccess),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        // Navigate back to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text(AppLocalizations.of(context)!.failedToSaveProfile)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${AppLocalizations.of(context)!.errorMessage}: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.patientProfile),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Let\'s Get to Know You',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your information helps us create personalized nutrition recommendations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                prefixIcon: Icon(Icons.cake_outlined, color: Theme.of(context).primaryColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                prefixIcon: Icon(Icons.monitor_weight_outlined, color: Theme.of(context).primaryColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCancerType,
                        decoration: InputDecoration(
                          labelText: 'Cancer Type',
                          prefixIcon: Icon(Icons.medical_services_outlined, color: Theme.of(context).primaryColor),
                        ),
                        items: _cancerTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCancerType = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select cancer type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStage,
                        decoration: InputDecoration(
                          labelText: 'Stage',
                          prefixIcon: Icon(Icons.timeline_outlined, color: Theme.of(context).primaryColor),
                        ),
                        items: _stages.map((stage) {
                          return DropdownMenuItem(value: stage, child: Text(stage));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStage = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select stage';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _allergiesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Allergies (optional)',
                          prefixIcon: Icon(Icons.warning_amber_outlined, color: Theme.of(context).primaryColor),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _otherConditionsController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Other Medical Conditions (optional)',
                          prefixIcon: Icon(Icons.description_outlined, color: Theme.of(context).primaryColor),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.save_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Profile',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}


