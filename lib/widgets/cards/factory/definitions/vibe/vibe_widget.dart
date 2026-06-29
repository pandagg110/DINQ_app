import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class VibeWidget extends StatelessWidget {
  const VibeWidget({super.key, required this.card, required this.size});

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata as Map<String, dynamic>;
    final totalTokens = _toInt(metadata['totalTokens']);
    final totalDays = _toInt(metadata['totalDays']);
    final platform = metadata['platform']?.toString() ?? '';
    final daily = _parseDaily(metadata['daily']);

    switch (size) {
      case '2x2':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _VibeIcon(),
              MetricDisplay(label: 'Tokens', value: totalTokens),
            ],
          ),
        );
      case '2x4':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _VibeIcon(),
              MiniHeatmap(daily: daily, weeksToShow: 13, compact: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetricDisplay(label: 'Tokens', value: totalTokens),
                  const SizedBox(height: 8),
                  PlatformTag(platform: platform),
                ],
              ),
            ],
          ),
        );
      case '4x2':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _VibeIcon(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MetricDisplay(label: 'Tokens', value: totalTokens),
                        const SizedBox(width: 32),
                        PlatformTag(platform: platform),
                      ],
                    ),
                  ],
                ),
              ),
              MiniHeatmap(daily: daily, weeksToShow: 13, compact: true),
            ],
          ),
        );
      case '4x4':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _VibeIcon(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      child: MetricDisplay(label: 'Tokens', value: totalTokens),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricBox(
                      child: MetricDisplay(label: 'Days', value: totalDays),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MiniHeatmap(daily: daily, weeksToShow: 20),
              const SizedBox(height: 16),
              PlatformTag(platform: platform),
            ],
          ),
        );
      default:
        return const Center(child: Text('Vibe'));
    }
  }
}

class MiniHeatmap extends StatelessWidget {
  const MiniHeatmap({
    super.key,
    required this.daily,
    this.weeksToShow = 13,
    this.compact = false,
  });

  final List<VibeDailyData> daily;
  final int weeksToShow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dataMap = {for (final day in daily) day.date: day.tokens};
    final maxTokens = daily.fold<int>(
      1,
      (max, day) => day.tokens > max ? day.tokens : max,
    );
    final today = DateTime.now();
    var startDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: weeksToShow * 7));
    if (startDate.weekday != DateTime.sunday) {
      startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
    }

    final columns = List.generate(weeksToShow, (week) {
      return List.generate(7, (day) {
        final date = startDate.add(Duration(days: week * 7 + day));
        final key = _dateKey(date);
        return _HeatmapCellData(date: key, tokens: dataMap[key] ?? 0);
      });
    });

    final gap = compact ? 2.0 : 3.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fixedCell = compact ? 8.0 : null;
        final cellSize =
            fixedCell ??
            ((constraints.maxWidth - (weeksToShow - 1) * gap) / weeksToShow)
                .clamp(4.0, 14.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            for (var week = 0; week < columns.length; week++) ...[
              Column(
                children: [
                  for (final cell in columns[week]) ...[
                    Tooltip(
                      message:
                          '${formatCount(cell.tokens)} tokens on ${cell.date}',
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: _heatmapColor(cell.tokens, maxTokens),
                          borderRadius: BorderRadius.circular(compact ? 2 : 3),
                        ),
                      ),
                    ),
                    if (cell != columns[week].last) SizedBox(height: gap),
                  ],
                ],
              ),
              if (week != columns.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class PlatformTag extends StatelessWidget {
  const PlatformTag({super.key, required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    if (platform.isEmpty) return const SizedBox.shrink();
    final lower = platform.toLowerCase();
    final color = _platformColors[lower] ?? const Color(0xFF6B7280);
    final displayName =
        _platformDisplayNames[lower] ??
        '${platform.substring(0, 1).toUpperCase()}${platform.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$displayName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _VibeIcon extends StatelessWidget {
  const _VibeIcon();

  @override
  Widget build(BuildContext context) {
    return const AssetIcon(asset: 'icons/social-icons/Vibe.svg', size: 40);
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class VibeDailyData {
  const VibeDailyData({required this.date, required this.tokens});

  final String date;
  final int tokens;
}

class _HeatmapCellData {
  const _HeatmapCellData({required this.date, required this.tokens});

  final String date;
  final int tokens;
}

const _platformColors = {
  'claude': Color(0xFFD97706),
  'openai': Color(0xFF10A37F),
  'chatgpt': Color(0xFF10A37F),
  'codex': Color(0xFF10A37F),
  'gemini': Color(0xFF4285F4),
  'copilot': Color(0xFF000000),
  'cursor': Color(0xFF1487FA),
};

const _platformDisplayNames = {
  'openai': 'Codex',
  'chatgpt': 'Codex',
  'codex': 'Codex',
};

List<VibeDailyData> _parseDaily(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((item) {
        if (item is! Map) return const VibeDailyData(date: '', tokens: 0);
        return VibeDailyData(
          date: item['date']?.toString() ?? '',
          tokens: _toInt(item['tokens']),
        );
      })
      .where((item) => item.date.isNotEmpty)
      .toList();
}

Color _heatmapColor(int tokens, int maxTokens) {
  if (tokens <= 0) return const Color(0xFFEBEDF0);
  final ratio = tokens / maxTokens;
  if (ratio < 0.25) return const Color(0xFFF5D4C8);
  if (ratio < 0.5) return const Color(0xFFE8A890);
  if (ratio < 0.75) return const Color(0xFFCB7C5D);
  return const Color(0xFFA85A3D);
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
