import 'package:flutter/material.dart';
import '../models/progress_entry.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class ProgressHistoryScreen extends StatefulWidget {
  const ProgressHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends State<ProgressHistoryScreen> {
  List<ProgressEntry> _progressHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressHistory();
  }

  Future<void> _loadProgressHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await ApiService().getProgressHistory();
      if (mounted) {
        setState(() {
          _progressHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(AppLocalizations.of(context)!.failedToLoadHistory)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.progressTracking),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progressHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _progressHistory.length,
                  itemBuilder: (context, index) {
                    return _buildProgressCard(_progressHistory[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.logProgress),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Progress Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your nutrition adherence',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEntryDialog(),
            icon: const Icon(Icons.add_rounded),
            label: Text(AppLocalizations.of(context)!.addFirstEntry),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ProgressEntry entry) {
    final color = _getScoreColor(entry.adherenceScore);
    final percentage = entry.adherenceScore / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${entry.adherenceScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreLabel(entry.adherenceScore),
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(_getScoreIcon(entry.adherenceScore), color: color, size: 28),
              ],
            ),
          ),
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (entry.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.notes,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.check_circle_rounded;
    if (score >= 60) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Improvement';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showAddEntryDialog() async {
    final scoreController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_chart_rounded, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.logProgress),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                decoration: InputDecoration(
                  labelText: 'Adherence Score (0-100)',
                  prefixIcon: const Icon(Icons.percent_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = int.tryParse(scoreController.text);
              if (score != null && score >= 0 && score <= 100) {
                try {
                  final entry = ProgressEntry(
                    date: DateTime.now(),
                    adherenceScore: score,
                    notes: notesController.text,
                  );
                  await ApiService().addProgressEntry(entry);
                  Navigator.pop(context);
                  _loadProgressHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.progressLoggedSuccess),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(child: Text(AppLocalizations.of(context)!.failedToAddEntry)),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.enterValidScore),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.addEntry),
          ),
        ],
      ),
    );
  }
}


