import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import 'allergies_screen.dart';

class EatingAbilityScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const EatingAbilityScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<EatingAbilityScreen> createState() => _EatingAbilityScreenState();
}

class _EatingAbilityScreenState extends State<EatingAbilityScreen> {
  String? selectedAbility;
  
  @override
  void initState() {
    super.initState();
    // Don't pre-select - user must make a choice
    selectedAbility = null;
  }
  
  List<Map<String, dynamic>> _getAbilityOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'id': 'normal',
        'label': l10n.normalEating,
        'subtitle': l10n.normalEatingDesc,
        'icon': Icons.restaurant_menu,
      },
      {
        'id': 'reduced',
        'label': l10n.reducedEating,
        'subtitle': l10n.reducedEatingDesc,
        'icon': Icons.remove_circle_outline,
      },
      {
        'id': 'soft_only',
        'label': l10n.softFoodsOnly,
        'subtitle': l10n.softFoodsOnlyDesc,
        'icon': Icons.soup_kitchen,
      },
      {
        'id': 'liquids_only',
        'label': l10n.liquidsOnly,
        'subtitle': l10n.liquidsOnlyDesc,
        'icon': Icons.local_drink,
      },
      {
        'id': 'cannot_eat',
        'label': l10n.cannotEat,
        'subtitle': l10n.cannotEatDesc,
        'icon': Icons.block,
      },
    ];
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.colorDanger),
            const SizedBox(width: 8),
            Text(l10n.emergencyNotice),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cannotEatWarning,
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
                    l10n.emergencyContacts,
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.nationalHelpline,
                    style: AppTheme.body.copyWith(
                      color: AppTheme.colorDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.localER,
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
            label: l10n.goBack,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedAbility = null;
              });
            },
          ),
          PrimaryButton(
            label: l10n.continueAnyway,
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
    final l10n = AppLocalizations.of(context)!;
    final abilityOptions = _getAbilityOptions(context);
    
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
                      l10n.eatingAbilityQuestion,
                      style: AppTheme.h2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.eatingAbilityQuestion,
                  style: AppTheme.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.eatingAbilitySubtitle,
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
                  label: l10n.continueButton,
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


