import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class RedditCardDefinition extends CardDefinition {
  @override
  String get type => 'REDDIT';

  @override
  String get icon => '/icons/social-icons/Reddit.svg';

  @override
  String get name => 'Reddit';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
    desktop: CardSizeConfig(
      supported: ['2x2', '2x4', '4x2', '4x4'],
      defaultSize: '4x4',
    ),
    mobile: CardSizeConfig(
      supported: ['2x2', '2x4', '4x2', '4x4'],
      defaultSize: '4x4',
    ),
  );

  @override
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
    final data = cardAdapterMap(rawMetadata);
    return {
      'name': data['name'] ?? '',
      'total_karma': data['total_karma'] ?? 0,
      'icon_img': data['icon_img'] ?? '',
      'created': data['created'] ?? 0,
      'created_utc': data['created_utc'] ?? 0,
      'account_age_days': data['account_age_days'] ?? 0,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final data = params.card.data.metadata;
    final name = data['name']?.toString() ?? '';
    final karma = data['total_karma'] ?? 0;
    final accountAge = _formatAccountAge(data['account_age_days'] ?? 0);

    if (name.isEmpty) return const SizedBox.shrink();

    final size = params.size.toLowerCase();
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Reddit.svg', size: 40),
          const Spacer(),
          if (size == '4x4')
            Row(
              children: [
                Expanded(
                  child: _OutlinedMetric(label: 'Karma', value: karma),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlinedMetric(
                    label: 'Reddit Age',
                    value: accountAge,
                  ),
                ),
              ],
            )
          else if (size == '4x2')
            Row(
              children: [
                Expanded(
                  child: _Metric(label: 'Karma', value: karma),
                ),
                Expanded(
                  child: _Metric(label: 'Reddit Age', value: accountAge),
                ),
              ],
            )
          else if (size == '2x4') ...[
            _Metric(label: 'Karma', value: karma),
            const SizedBox(height: 16),
            _Metric(label: 'Reddit Age', value: accountAge),
          ] else
            _Metric(label: 'Karma', value: karma),
        ],
      ),
    );
  }

  String _formatAccountAge(dynamic rawDays) {
    final days = rawDays is num
        ? rawDays.toInt()
        : int.tryParse('$rawDays') ?? 0;
    final totalMonths = days ~/ 30;
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    if (years == 0) return '${months}mo';
    if (months == 0) return '${years}y';
    return '${years}y ${months}mo';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _OutlinedMetric extends StatelessWidget {
  const _OutlinedMetric({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEFEFEF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _Metric(label: label, value: value),
    );
  }
}
