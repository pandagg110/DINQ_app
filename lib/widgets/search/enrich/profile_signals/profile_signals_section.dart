import 'package:flutter/material.dart';

import '../../../../models/deep_search_enrich_models.dart';
import 'github_signal_card.dart';
import 'linkedin_signal_card.dart';
import 'profile_signals_adapters.dart';
import 'profile_signals_shared.dart';
import 'scholar_signal_card.dart';

/// 对齐 Web `EnrichDinqCardsSection`（Profile signals）。
class EnrichDinqCardsSection extends StatelessWidget {
  const EnrichDinqCardsSection({
    super.key,
    required this.cards,
    this.loading = false,
  });

  final List<EnrichDinqCard> cards;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final renderItems = buildProfileSignalItems(cards);

    if (renderItems.isEmpty && !loading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSignalsSectionHeader(title: 'Profile signals'),
          if (renderItems.isEmpty && loading)
            const ProfileSignalSkeleton()
          else
            for (var i = 0; i < renderItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              ProfileSignalFrame(
                child: _ProfileSignalCard(item: renderItems[i]),
              ),
            ],
        ],
      ),
    );
  }
}

class _ProfileSignalCard extends StatelessWidget {
  const _ProfileSignalCard({required this.item});

  final ProfileSignalItem item;

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'LINKEDIN':
        return LinkedInProfileSignalCard(
          metadata: item.metadata,
          url: item.url,
        );
      case 'GITHUB':
        return GitHubProfileSignalCard(
          metadata: item.metadata,
          url: item.url,
        );
      case 'SCHOLAR':
        return ScholarProfileSignalCard(
          metadata: item.metadata,
          url: item.url,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
