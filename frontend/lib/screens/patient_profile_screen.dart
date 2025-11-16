import 'package:flutter/material.dart';
import '../models/patient_profile.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
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
  void dispose() {
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
        Navigator.pushNamed(context, AppRoutes.dietRecommendation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
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
      appBar: AppBar(
        title: const Text('Patient Profile'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Please provide your information for personalized recommendations',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _ageController,
                  label: 'Age',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCancerType,
                  decoration: const InputDecoration(
                    labelText: 'Cancer Type',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Stage',
                    border: OutlineInputBorder(),
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
                CustomTextField(
                  controller: _allergiesController,
                  label: 'Allergies (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _otherConditionsController,
                  label: 'Other Medical Conditions (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Save & Get Recommendations',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
