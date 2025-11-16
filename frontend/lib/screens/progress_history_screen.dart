import 'package:flutter/material.dart';
import '../models/progress_entry.dart';
import '../services/api_service.dart';

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
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress History'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progressHistory.isEmpty
              ? const Center(child: Text('No progress history available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _progressHistory.length,
                  itemBuilder: (context, index) {
                    final entry = _progressHistory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getScoreColor(entry.adherenceScore),
                          child: Text(
                            '${entry.adherenceScore}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          _formatDate(entry.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: entry.notes.isNotEmpty
                            ? Text(entry.notes)
                            : null,
                        trailing: Icon(
                          _getScoreIcon(entry.adherenceScore),
                          color: _getScoreColor(entry.adherenceScore),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.warning;
    return Icons.error;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddEntryDialog() async {
    final scoreController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Progress Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Adherence Score (0-100)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = int.tryParse(scoreController.text);
              if (score != null && score >= 0 && score <= 100) {
                try {
                  await ApiService().addProgressEntry(
                    score,
                    notesController.text,
                  );
                  Navigator.pop(context);
                  _loadProgressHistory();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add entry: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
