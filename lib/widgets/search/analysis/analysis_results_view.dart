import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_constants.dart';
import 'analysis_cards.dart';
import 'analysis_config.dart';
import 'analysis_theme.dart';

/// 与 TSX `AnalysisResultsView.tsx` 对齐。
class AnalysisResultsView extends StatefulWidget {
  const AnalysisResultsView({
    super.key,
    required this.platform,
    required this.cards,
    required this.query,
    this.loading = false,
    this.onEnrich,
  });

  final String platform;
  final Map<String, dynamic> cards;
  final String query;
  final bool loading;
  final VoidCallback? onEnrich;

  @override
  State<AnalysisResultsView> createState() => _AnalysisResultsViewState();
}

class _AnalysisResultsViewState extends State<AnalysisResultsView> {
  List<String>? _shuffledKeys;
  String? _shuffleContextKey;

  @override
  void didUpdateWidget(covariant AnalysisResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contextKey = '${widget.platform}|${widget.query}';
    if (_shuffleContextKey != contextKey) {
      _shuffleContextKey = contextKey;
      _shuffledKeys = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _shuffleContextKey ??= '${widget.platform}|${widget.query}';
    final defaultConfigs = AnalysisPlatformConfig.previewCards(widget.platform);
    final availableConfigs = AnalysisPlatformConfig.allConfigs(widget.platform)
        .where((c) => _hasRawCardData(c.dataKey))
        .toList();

    final previewConfigs = _resolvePreviewConfigs(defaultConfigs, availableConfigs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return _buildCardGrid(previewConfigs, constraints.maxWidth);
          },
        ),
        if (!widget.loading && _hasCompletedCard) ...[
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ActionButton(
                    iconAsset: AnalysisTheme.actionBarChart,
                    label: 'View Full Analysis',
                    wrapLabel: true,
                    onTap: () => _openFullAnalysis(widget.platform, widget.query),
                  ),
                ),
                if (widget.onEnrich != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    iconAsset: AnalysisTheme.actionMicroscope,
                    label: 'Enrich',
                    onTap: widget.onEnrich,
                  ),
                ],
                if (availableConfigs.length > 2) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    iconAsset: AnalysisTheme.actionShuffle,
                    label: 'Shuffle',
                    onTap: () => _handleShuffle(defaultConfigs, availableConfigs),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<AnalysisPreviewCardConfig> _resolvePreviewConfigs(
    List<AnalysisPreviewCardConfig> defaultConfigs,
    List<AnalysisPreviewCardConfig> availableConfigs,
  ) {
    if (_shuffledKeys == null) return defaultConfigs;
    return _shuffledKeys!
        .map(
          (key) => availableConfigs.where((c) => c.key == key).firstOrNull,
        )
        .whereType<AnalysisPreviewCardConfig>()
        .toList();
  }

  Widget _buildCardGrid(
    List<AnalysisPreviewCardConfig> previewConfigs,
    double maxWidth,
  ) {
    const gap = AnalysisTheme.cardGridGap;
    final twoCol = maxWidth >= AnalysisTheme.gridTwoColumnBreakpoint &&
        maxWidth >= AnalysisTheme.minCardWidth * 2 + gap;

    if (!twoCol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < previewConfigs.length; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            _buildCardSlot(previewConfigs[i], previewConfigs),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    var i = 0;
    while (i < previewConfigs.length) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));

      final config = previewConfigs[i];
      if (config.fullWidth ||
          i + 1 >= previewConfigs.length ||
          previewConfigs[i + 1].fullWidth) {
        rows.add(_buildCardSlot(config, previewConfigs));
        i++;
        continue;
      }

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCardSlot(previewConfigs[i], previewConfigs)),
              const SizedBox(width: gap),
              Expanded(child: _buildCardSlot(previewConfigs[i + 1], previewConfigs)),
            ],
          ),
        ),
      );
      i += 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildCardSlot(
    AnalysisPreviewCardConfig config,
    List<AnalysisPreviewCardConfig> previewConfigs,
  ) {
    final cardState = widget.cards[config.dataKey];
    if (!_hasRawCardData(config.dataKey)) {
      final hasAnySibling = previewConfigs.any(
        (c) => c.key != config.key && _hasRawCardData(c.dataKey),
      );
      if (!hasAnySibling) return const SizedBox.shrink();
      return const SizedBox.shrink();
    }

    final cardData = _readCardDataMap(cardState);
    if (cardData == null) return const SizedBox.shrink();

    final props = AnalysisPlatformConfig.extractCardProps(config.component, cardData);
    if (props == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: AnalysisCardBuilder.build(
        component: config.component,
        cardKey: config.key,
        props: props,
        platform: widget.platform,
        isStreaming: widget.loading,
      ),
    );
  }

  bool get _hasCompletedCard {
    return widget.cards.values.any((value) {
      if (value is! Map) return false;
      return value['status'] == 'completed' && value['data'] != null;
    });
  }

  /// 与 TSX `cards[c.dataKey]?.data` truthy 检查对齐。
  bool _hasRawCardData(String dataKey) {
    final cardState = widget.cards[dataKey];
    if (cardState is! Map) return false;
    return cardState['data'] != null;
  }

  Map<String, dynamic>? _readCardDataMap(dynamic cardState) {
    if (cardState is! Map) return null;
    final data = cardState['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  void _handleShuffle(
    List<AnalysisPreviewCardConfig> defaultConfigs,
    List<AnalysisPreviewCardConfig> availableConfigs,
  ) {
    final currentKeys = {
      ...(_shuffledKeys ?? defaultConfigs.map((c) => c.key)),
    };
    final candidates =
        availableConfigs.where((c) => !currentKeys.contains(c.key)).toList();
    final pool = candidates.length >= 2 ? candidates : availableConfigs;
    final picked = <String>[];
    final remaining = [...pool];
    final random = math.Random();
    while (picked.length < 2 && remaining.isNotEmpty) {
      final index = random.nextInt(remaining.length);
      picked.add(remaining.removeAt(index).key);
    }
    setState(() => _shuffledKeys = picked);
  }

  static Future<void> _openFullAnalysis(String platform, String query) async {
    final uri = Uri.parse(
      '$analysisBaseUrl/$platform?user=${Uri.encodeComponent(query)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconAsset,
    required this.label,
    this.onTap,
    this.wrapLabel = false,
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onTap;
  final bool wrapLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AnalysisTheme.actionBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: wrapLabel ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(AnalysisTheme.primary, BlendMode.srcIn),
                ),
                const SizedBox(width: 6),
                if (wrapLabel)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AnalysisTheme.primary,
                        height: 1.3,
                      ),
                    ),
                  )
                else
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AnalysisTheme.primary,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
