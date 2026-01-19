import 'package:flutter/material.dart';
import '../../widgets/layout/app_header.dart';

class GitHubComparePage extends StatelessWidget {
  const GitHubComparePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Text('GitHub Compare', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _compareCard('Candidate A')),
                      const SizedBox(width: 16),
                      Expanded(child: _compareCard('Candidate B')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareCard(String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(height: 160, color: const Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Container(height: 120, color: const Color(0xFFF3F4F6)),
        ],
      ),
    );
  }
}

