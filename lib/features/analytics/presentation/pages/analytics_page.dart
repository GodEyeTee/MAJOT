// lib/features/analytics/presentation/pages/analytics_page.dart
import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'Analytics Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Your analytics data will appear here',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
