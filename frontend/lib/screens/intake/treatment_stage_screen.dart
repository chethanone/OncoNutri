import 'package:flutter/material.dart';
import '../../models/intake_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_components.dart';
import '../../l10n/app_localizations.dart';
import 'symptoms_screen.dart';

class TreatmentStageScreen extends StatefulWidget {
  final IntakeData intakeData;
  
  const TreatmentStageScreen({Key? key, required this.intakeData}) : super(key: key);
  
  @override
  State<TreatmentStageScreen> createState() => _TreatmentStageScreenState();
}

class _TreatmentStageScreenState extends State<TreatmentStageScreen> {
  String? selectedStage;
  
  List<Map<String, dynamic>> _getStages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'name': l10n.preTreatment,
        'value': 'pre_treatment',
        'subtitle': l10n.preTreatmentDesc,
        'icon': Icons.assessment
      },
      {
        'name': l10n.chemotherapy,
        'value': 'chemotherapy',
        'subtitle': l10n.chemotherapyDesc,
        'icon': Icons.medical_services
      },
      {
        'name': l10n.radiation,
        'value': 'radiation',
        'subtitle': l10n.radiationDesc,
        'icon': Icons.wb_sunny
      },
      {
        'name': l10n.surgeryRecovery,
        'value': 'surgery',
        'subtitle': l10n.surgeryRecoveryDesc,
        'icon': Icons.healing
      },
      {
        'name': l10n.postTreatment,
        'value': 'post_treatment',
        'subtitle': l10n.postTreatmentDesc,
        'icon': Icons.check_circle_outline
      },
      {
        'name': l10n.maintenance,
        'value': 'maintenance',
        'subtitle': l10n.maintenanceDesc,
        'icon': Icons.favorite
      },
    ];
  }
  
  @override
  void initState() {
    super.initState();
    // Don't pre-select - user must make a choice
    selectedStage = null;
  }
  
  void _continue() {
    if (selectedStage != null) {
      widget.intakeData.treatmentStage = selectedStage;
      // Navigate to symptoms screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SymptomsScreen(intakeData: widget.intakeData),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
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
                      'Treatment Stage',
                      style: AppTheme.h2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.treatmentStageQuestion,
                  style: AppTheme.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.treatmentStageSubtitle,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.subtextColor(context),
                  ),
                ),
                const SizedBox(height: 32),
                // Treatment stages
                Expanded(
                  child: ListView.separated(
                    itemCount: _getStages(context).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stage = _getStages(context)[index];
                      return OptionCard(
                        id: stage['value'],
                        label: stage['name'],
                        subtitle: stage['subtitle'],
                        icon: Icon(
                          stage['icon'],
                          color: AppTheme.primaryColor(context),
                        ),
                        selected: selectedStage == stage['value'],
                        onSelect: (id) {
                          setState(() {
                            // Allow deselection by tapping the same option again
                            if (selectedStage == id) {
                              selectedStage = null;
                            } else {
                              selectedStage = id;
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
                label: AppLocalizations.of(context)!.continueButton,
                onPressed: selectedStage != null ? _continue : null,
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


