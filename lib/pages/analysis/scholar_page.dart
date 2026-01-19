import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/layout/app_header.dart';

class ScholarAnalysisPage extends StatelessWidget {
  const ScholarAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final user = query['user'] ?? '';

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scholar Analysis', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(user.isEmpty ? 'Provide a scholar profile to analyze.' : 'Analyzing $user'),
                  const SizedBox(height: 24),
                  _buildPlaceholderCard('Citation Overview'),
                  const SizedBox(height: 16),
                  _buildPlaceholderCard('Research Topics'),
                  const SizedBox(height: 16),
                  _buildPlaceholderCard('Collaboration Network'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(height: 140, color: const Color(0xFFF3F4F6)),
        ],
      ),
    );
  }
}

