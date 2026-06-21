import 'package:flutter/material.dart';

import 'deep_search_models.dart';
import 'sub_agent_helpers.dart';
import 'trace_status.dart';
import 'trace_strings.dart';

enum SearchActivityLinePlacement { inline, sticky }

/// 与 TSX `SearchActivityLine` 对齐：搜索进行中展示当前工具/思考状态。
class SearchActivityLine extends StatefulWidget {
  const SearchActivityLine({
    super.key,
    required this.status,
    required this.isSearching,
    this.placement = SearchActivityLinePlacement.inline,
  });

  final LatestTraceStatus? status;
  final bool isSearching;
  final SearchActivityLinePlacement placement;

  @override
  State<SearchActivityLine> createState() => _SearchActivityLineState();
}

class _SearchActivityLineState extends State<SearchActivityLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == null && !widget.isSearching) {
      return const SizedBox.shrink();
    }

    final isSticky = widget.placement == SearchActivityLinePlacement.sticky;
    final padding = isSticky
        ? const EdgeInsets.fromLTRB(20, 4, 20, 16)
        : const EdgeInsets.fromLTRB(20, 8, 20, 12);

    String headline;
    String? detail;

    final status = widget.status;
    if (status is ToolTraceStatus) {
      final gerund = status.toolKey != null
          ? toolToGerund(status.toolName)
          : toolToGerund(status.toolName);
      final details = <String>[
        if (status.query != null && status.query!.isNotEmpty) status.query!,
        if (status.maxResults != null) 'x${status.maxResults}',
      ];
      headline = details.isNotEmpty
          ? gerund.replaceAll(RegExp(r'[.…]+$'), '')
          : gerund;
      detail = details.isNotEmpty ? details.join(' · ') : null;
    } else if (status is ThinkingTraceStatus) {
      headline = TraceStrings.statusLineThinking;
      detail = status.text;
    } else {
      headline = TraceStrings.preparingToolsEllipsis;
    }

    return Padding(
      padding: padding,
      child: _ActivityLineRow(
        controller: _shimmerController,
        headline: headline,
        detail: detail,
      ),
    );
  }
}

class _ActivityLineRow extends StatelessWidget {
  const _ActivityLineRow({
    required this.controller,
    required this.headline,
    this.detail,
  });

  final AnimationController controller;
  final String headline;
  final String? detail;

  static const _shimmerColors = <Color>[
    Color(0xFF7D7971),
    Color(0xFFB8B5AE),
    Color(0xFF7D7971),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment(-1 + controller.value * 2, 0),
                    end: Alignment(controller.value * 2, 0),
                    colors: _shimmerColors,
                    stops: const [0, 0.5, 1],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 20 / 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC6C3BD)),
                ),
              ),
              Expanded(
                child: Text(
                  detail!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 20 / 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A39E),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

LatestTraceStatus? resolveSearchActivityStatus({
  required DeepSearchRoundStatus roundStatus,
  required List<MessagePart> contentBlocks,
  required Map<String, SubAgentInfo> subAgents,
}) {
  return getLatestTraceStatus(
    status: roundStatus,
    contentBlocks: contentBlocks,
    subAgents: subAgents,
  );
}
