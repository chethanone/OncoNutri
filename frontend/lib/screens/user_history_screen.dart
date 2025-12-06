import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_theme.dart';
import '../l10n/app_localizations.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('user_history');
    
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _historyItems = decoded.map((item) => HistoryItem.fromJson(item)).toList();
      // Sort by timestamp, newest first
      _historyItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearHistory),
        content: Text(AppLocalizations.of(context)!.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_history');
      setState(() {
        _historyItems.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History cleared successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'recommendation':
        return Icons.restaurant_menu;
      case 'profile_update':
        return Icons.person;
      case 'food_saved':
        return Icons.bookmark;
      case 'food_removed':
        return Icons.delete_outline;
      case 'name_update':
        return Icons.edit;
      case 'health_update':
        return Icons.medical_information;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'recommendation':
        return Colors.green;
      case 'profile_update':
        return Colors.blue;
      case 'food_saved':
        return Colors.orange;
      case 'food_removed':
        return Colors.red;
      case 'name_update':
        return Colors.purple;
      case 'health_update':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.colorDarkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User History',
          style: TextStyle(
            color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D)),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyItems.length,
                  itemBuilder: (context, index) {
                    final item = _historyItems[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.colorDarkSurface : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 60,
              color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.colorDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getColorForType(item.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForType(item.type),
              color: _getColorForType(item.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(item.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryItem {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  HistoryItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        type: json['type'],
        title: json['title'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

// Helper class to add history items from other parts of the app
class HistoryLogger {
  static Future<void> logEvent({
    required String type,
    required String title,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('user_history');
    
    List<HistoryItem> items = [];
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      items = decoded.map((item) => HistoryItem.fromJson(item)).toList();
    }

    items.add(HistoryItem(
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
    ));

    // Keep only last 100 items
    if (items.length > 100) {
      items = items.sublist(items.length - 100);
    }

    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString('user_history', encoded);
  }
}
