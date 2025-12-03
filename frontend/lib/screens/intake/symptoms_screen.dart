import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/searchable_list.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import 'allergies_screen.dart';

class SymptomsScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const SymptomsScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  Set<String> selectedSymptoms = {};

  List<MultiSelectOption> _symptomOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      MultiSelectOption(
        id: 'nausea',
        label: 'Nausea',
        icon: Icon(Icons.sick, color: AppTheme.primaryColor(context), size: 36),
      ),
      MultiSelectOption(
        id: 'vomiting',
        label: 'Vomiting',
        icon: Icon(Icons.waves, color: AppTheme.primaryColor(context), size: 36),
      ),
      MultiSelectOption(
        id: 'diarrhea',
        label: 'Diarrhea',
        icon: Icon(Icons.warning, color: AppTheme.colorWarning, size: 36),
      ),
      MultiSelectOption(
        id: 'constipation',
        label: 'Constipation',
        icon: Icon(Icons.block, color: AppTheme.colorDanger, size: 36),
      ),
      MultiSelectOption(
        id: 'fatigue',
        label: 'Fatigue',
        icon: Icon(Icons.battery_0_bar, color: AppTheme.subtextColor(context), size: 36),
      ),
      MultiSelectOption(
        id: 'loss_appetite',
        label: 'Loss of Appetite',
        icon: Icon(Icons.no_meals, color: AppTheme.colorDanger, size: 36),
      ),
      MultiSelectOption(
        id: 'mouth_sores',
        label: l10n.mouthSores,
        icon: Icon(Icons.mood_bad, color: AppTheme.primaryColor(context), size: 36),
      ),
      MultiSelectOption(
        id: 'taste_changes',
        label: l10n.tasteChanges,
        icon: Icon(Icons.restaurant, color: AppTheme.primary400Color(context), size: 36),
      ),
      MultiSelectOption(
        id: 'swallowing_difficulty',
        label: l10n.difficultySwallowing,
        icon: Icon(Icons.accessibility_new, color: AppTheme.colorWarning, size: 36),
      ),
      MultiSelectOption(
        id: 'bloating',
        label: l10n.bloating,
        icon: Icon(Icons.air, color: AppTheme.primary400Color(context), size: 36),
      ),
      MultiSelectOption(
        id: 'none',
        label: l10n.none,
        icon: Icon(Icons.check_circle, color: AppTheme.colorSuccess, size: 36),
      ),
    ];
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.intakeData.symptoms != null) {
      selectedSymptoms = Set<String>.from(widget.intakeData.symptoms!);
    }
  }
  
  void _handleSelectionChange(Set<String> newSelection) {
    setState(() {
      // If "None" is selected, clear all others
      if (newSelection.contains('none') && !selectedSymptoms.contains('none')) {
        selectedSymptoms = {'none'};
      } 
      // If any other symptom is selected, remove "None"
      else if (newSelection.length > selectedSymptoms.length && selectedSymptoms.contains('none')) {
        selectedSymptoms = newSelection..remove('none');
      } 
      else {
        selectedSymptoms = newSelection;
      }
    });
  }
  
  void _continue() {
    widget.intakeData.symptoms = selectedSymptoms.toList();
    
    // Set eating ability based on symptoms
    if (selectedSymptoms.contains('swallowing_difficulty')) {
      widget.intakeData.eatingAbility = 'difficulty_swallowing';
    } else if (selectedSymptoms.contains('mouth_sores')) {
      widget.intakeData.eatingAbility = 'soft_foods';
    } else {
      widget.intakeData.eatingAbility = 'normal';
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllergiesScreen(intakeData: widget.intakeData),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
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
                          'Symptoms',
                          style: AppTheme.h2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.symptomsQuestion,
                      style: AppTheme.h1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.symptomsSubtitle,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Symptoms grid
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MultiSelectCardGrid(
                        options: _symptomOptions(context),
                        selectedIds: selectedSymptoms,
                        onChange: _handleSelectionChange,
                        crossAxisCount: 2,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.all(AppTheme.horizontalPadding),
                child: PrimaryButton(
                  label: AppLocalizations.of(context)!.continueButton,
                  onPressed: selectedSymptoms.isNotEmpty ? _continue : null,
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


