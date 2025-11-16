import 'package:flutter/material.dart';
import '../models/diet_recommendation.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class DietRecommendationScreen extends StatefulWidget {
  const DietRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<DietRecommendationScreen> createState() => _DietRecommendationScreenState();
}

class _DietRecommendationScreenState extends State<DietRecommendationScreen> {
  DietRecommendation? _recommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    try {
      final recommendation = await ApiService().getDietRecommendation();
      if (mounted) {
        setState(() {
          _recommendation = recommendation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Recommendations'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.progressHistory);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendation == null
              ? const Center(child: Text('No recommendations available'))
              : RefreshIndicator(
                  onRefresh: _loadRecommendation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          'Breakfast',
                          _recommendation!.breakfast,
                          Icons.free_breakfast,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Lunch',
                          _recommendation!.lunch,
                          Icons.lunch_dining,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Dinner',
                          _recommendation!.dinner,
                          Icons.dinner_dining,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Snacks',
                          _recommendation!.snacks,
                          Icons.cookie,
                        ),
                        const SizedBox(height: 20),
                        _buildNotesSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Important Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recommendation?.notes != null)
              Text(
                _recommendation!.notes!,
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
