import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import 'appetite_screen.dart';

class WaterIntakeScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const WaterIntakeScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  String? selectedIntake;
  
  final List<Map<String, dynamic>> waterIntakeOptions = [
    {
      'id': 'low',
      'label': 'Less than 1 Liter',
      'subtitle': '1-4 glasses per day',
      'icon': Icons.water_drop,
    },
    {
      'id': 'moderate',
      'label': '1-2 Liters',
      'subtitle': '4-8 glasses per day',
      'icon': Icons.water,
    },
    {
      'id': 'high',
      'label': 'More than 2 Liters',
      'subtitle': '8+ glasses per day',
      'icon': Icons.water_damage,
    },
    {
      'id': 'unknown',
      'label': 'Not sure',
      'subtitle': 'I don\'t track my water intake',
      'icon': Icons.help_outline,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Don't pre-select - user must make a choice
    selectedIntake = null;
  }
  
  void _continue() {
    if (selectedIntake != null) {
      // Store in waterIntake field
      widget.intakeData.waterIntake = selectedIntake;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppetiteScreen(intakeData: widget.intakeData),
        ),
      );
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
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Water Intake',
                      style: AppTheme.h2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'How much water do you drink daily?',
                  style: AppTheme.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  'Staying hydrated is crucial during treatment',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.colorSubtext,
                  ),
                ),
                const SizedBox(height: 32),
                // Water intake options
                Expanded(
                  child: ListView.separated(
                    itemCount: waterIntakeOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = waterIntakeOptions[index];
                      return OptionCard(
                        id: option['id'],
                        label: option['label'],
                        subtitle: option['subtitle'],
                        icon: Icon(
                          option['icon'],
                          color: AppTheme.colorPrimary,
                        ),
                        selected: selectedIntake == option['id'],
                        onSelect: (id) {
                          setState(() {
                            // Allow deselection by tapping the same option again
                            if (selectedIntake == id) {
                              selectedIntake = null;
                            } else {
                              selectedIntake = id;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Continue button
                PrimaryButton(
                  label: 'Continue',
                  onPressed: selectedIntake != null ? _continue : null,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


