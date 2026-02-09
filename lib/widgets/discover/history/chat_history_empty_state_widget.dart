import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 与 TSX ChatHistoryEmptyState 一致：empty | error | locked | upgrade_pro
class ChatHistoryEmptyStateWidget extends StatelessWidget {
  const ChatHistoryEmptyStateWidget({
    super.key,
    required this.type,
    this.message,
    this.tier,
  });

  final String type; // 'empty' | 'error' | 'locked' | 'upgrade_pro'
  final String? message;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final isFreeUser = tier == 'free';

    // Upgrade to Pro prompt for Basic users
    if (type == 'upgrade_pro') {
      return _buildUnlockSection(
        context,
        buttonLabel: 'Upgrade to Pro',
      );
    }

    // Locked state for Free users
    if (type == 'locked') {
      return _buildUnlockSection(
        context,
        buttonLabel: 'Upgrade',
      );
    }

    // Error state for free user (show upgrade message)
    if (type == 'error' && isFreeUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/discover/lock.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.lock, size: 20, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chat History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upgrade to Pro to save and access your search history',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/settings/subscription'),
              child: const Text('View Plans →', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
            ),
          ],
        ),
      );
    }

    // Error state (generic)
    if (type == 'error') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 20, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Failed to load history',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    // Empty state
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.history, size: 20, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          const Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your search history will appear here',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockSection(BuildContext context, {required String buttonLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/discover/lock.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.lock, size: 24, color: Color(0xFF171717)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save Every Conversation And Pick Up Exactly Where You Left Off.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF636363), height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Column(
              children: [
                _featureRow('Unlimited History'),
                const SizedBox(height: 8),
                _featureRow('Search Your Past Chats'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/pricing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1487FA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: Color(0xFF22C55E)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF636363), height: 1.4),
        ),
      ],
    );
  }
}
