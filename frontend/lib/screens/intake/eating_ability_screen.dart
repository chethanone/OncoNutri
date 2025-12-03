import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import 'allergies_screen.dart';

class EatingAbilityScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const EatingAbilityScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<EatingAbilityScreen> createState() => _EatingAbilityScreenState();
}

class _EatingAbilityScreenState extends State<EatingAbilityScreen> {
  String? selectedAbility;
  
  final List<Map<String, dynamic>> abilityOptions = [
    {
      'id': 'normal',
      'label': 'Normal',
      'subtitle': 'Can eat regular foods',
      'icon': Icons.restaurant_menu,
    },
    {
      'id': 'reduced',
      'label': 'Reduced',
      'subtitle': 'Eating smaller portions',
      'icon': Icons.remove_circle_outline,
    },
    {
      'id': 'soft_only',
      'label': 'Soft Foods Only',
      'subtitle': 'Difficulty with solid foods',
      'icon': Icons.soup_kitchen,
    },
    {
      'id': 'liquids_only',
      'label': 'Liquids Only',
      'subtitle': 'Can only consume liquids',
      'icon': Icons.local_drink,
    },
    {
      'id': 'cannot_eat',
      'label': 'Cannot Eat',
      'subtitle': 'Unable to eat or drink',
      'icon': Icons.block,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Don't pre-select - user must make a choice
    selectedAbility = null;
  }
  
  void _continue() {
    if (selectedAbility != null) {
      // Save eating ability to intake data
      widget.intakeData.eatingAbility = selectedAbility;
      // Show emergency warning if cannot eat
      if (selectedAbility == 'cannot_eat') {
        _showEmergencyDialog();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllergiesScreen(intakeData: widget.intakeData),
          ),
        );
      }
    }
  }
  
  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: AppTheme.colorDanger),
            SizedBox(width: 8),
            Text('Important Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you cannot eat or drink, please contact your healthcare provider immediately.',
              style: AppTheme.body,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colorWarning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Helpline',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Emergency: 102 (India)',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.colorDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GhostButton(
            label: 'Go Back',
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedAbility = null;
              });
            },
          ),
          PrimaryButton(
            label: 'Continue',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllergiesScreen(intakeData: widget.intakeData),
                ),
              );
            },
          ),
        ],
      ),
    );
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
                      'Eating Ability',
                      style: AppTheme.h2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'What can you currently eat?',
                  style: AppTheme.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us suggest appropriate food textures',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.colorSubtext,
                  ),
                ),
                const SizedBox(height: 32),
                // Eating ability options
                Expanded(
                  child: ListView.separated(
                    itemCount: abilityOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = abilityOptions[index];
                      final isCannotEat = option['id'] == 'cannot_eat';
                      return OptionCard(
                        id: option['id'],
                        label: option['label'],
                        subtitle: option['subtitle'],
                        icon: Icon(
                          option['icon'],
                          color: isCannotEat ? AppTheme.colorDanger : AppTheme.colorPrimary,
                        ),
                        selected: selectedAbility == option['id'],
                        onSelect: (id) {
                          setState(() {
                            // Allow deselection by tapping the same option again
                            if (selectedAbility == id) {
                              selectedAbility = null;
                            } else {
                              selectedAbility = id;
                            }
                          });
                        },
                        variant: OptionCardVariant.defaultVariant,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Continue button
                PrimaryButton(
                  label: 'Continue',
                  onPressed: selectedAbility != null ? _continue : null,
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


