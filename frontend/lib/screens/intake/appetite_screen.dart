import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import 'allergies_screen.dart';

class AppetiteScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const AppetiteScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<AppetiteScreen> createState() => _AppetiteScreenState();
}

class _AppetiteScreenState extends State<AppetiteScreen> {
  String? selectedAppetite;
  
  final List<Map<String, dynamic>> appetiteOptions = [
    {
      'id': 'low',
      'label': 'Low',
      'subtitle': 'Little interest in eating',
      'icon': Icons.no_meals,
    },
    {
      'id': 'normal',
      'label': 'Normal',
      'subtitle': 'Regular appetite',
      'icon': Icons.restaurant_menu,
    },
    {
      'id': 'increased',
      'label': 'Increased',
      'subtitle': 'Eating more than usual',
      'icon': Icons.restaurant,
    },
    {
      'id': 'varies',
      'label': 'Varies',
      'subtitle': 'Changes day to day',
      'icon': Icons.swap_horiz,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Don't pre-select - user must make a choice
    selectedAppetite = null;
  }
  
  void _continue() {
    if (selectedAppetite != null) {
      // Save appetite level to intake data
      widget.intakeData.appetiteLevel = selectedAppetite;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AllergiesScreen(intakeData: widget.intakeData),
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
                      'Appetite Level',
                      style: AppTheme.h2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'How is your appetite?',
                  style: AppTheme.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us recommend appropriate portion sizes',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.colorSubtext,
                  ),
                ),
                const SizedBox(height: 32),
                // Appetite options
                Expanded(
                  child: ListView.separated(
                    itemCount: appetiteOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = appetiteOptions[index];
                      return OptionCard(
                        id: option['id'],
                        label: option['label'],
                        subtitle: option['subtitle'],
                        icon: Icon(
                          option['icon'],
                          color: AppTheme.colorPrimary,
                        ),
                        selected: selectedAppetite == option['id'],
                        onSelect: (id) {
                          setState(() {
                            // Allow deselection by tapping the same option again
                            if (selectedAppetite == id) {
                              selectedAppetite = null;
                            } else {
                              selectedAppetite = id;
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
                  onPressed: selectedAppetite != null ? _continue : null,
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


