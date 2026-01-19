import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/layout/app_header.dart';

class GitHubAnalysisPage extends StatelessWidget {
  const GitHubAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final user = query['user'] ?? query['url'] ?? '';

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
                  Text('GitHub Analysis', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(user.isEmpty ? 'Provide a GitHub username to analyze.' : 'Analyzing @$user'),
                  const SizedBox(height: 24),
                  _buildPlaceholderCard('Contribution Heatmap'),
                  const SizedBox(height: 16),
                  _buildPlaceholderCard('Language Breakdown'),
                  const SizedBox(height: 16),
                  _buildPlaceholderCard('Top Repositories'),
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

