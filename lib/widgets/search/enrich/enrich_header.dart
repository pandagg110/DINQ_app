import 'package:flutter/material.dart';

import '../../../models/deep_search_enrich_models.dart';
import 'enrich_tool_log_timeline.dart';

String enrichPanelTitle({
  required bool isError,
  required bool isDone,
  required bool hasPerson,
  required bool fromCache,
  String? name,
}) {
  if (isError) return 'Enrich failed';
  final suffix = name != null && name.isNotEmpty ? "$name's profile" : 'profile';
  if (!isDone && hasPerson && fromCache) {
    return "From DINQ's database · $suffix";
  }
  if (isDone || hasPerson) return 'Enriched $suffix';
  return 'Enriching $suffix';
}

/// 对齐 Web `EnrichHeader.tsx`。
class EnrichHeader extends StatefulWidget {
  const EnrichHeader({
    super.key,
    required this.entry,
    required this.onClose,
    this.onRefresh,
  });

  final EnrichEntry? entry;
  final VoidCallback onClose;
  final Future<void> Function()? onRefresh;

  @override
  State<EnrichHeader> createState() => _EnrichHeaderState();
}

class _EnrichHeaderState extends State<EnrichHeader> {
  bool _expanded = false;
  bool _refreshing = false;
  bool _hadPerson = false;

  @override
  void didUpdateWidget(covariant EnrichHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entry = widget.entry;
    final hasPerson = entry?.person != null;
    if (!_hadPerson && hasPerson) {
      _expanded = false;
    } else if (entry?.status == EnrichStatus.streaming && !hasPerson) {
      _expanded = true;
    }
    _hadPerson = hasPerson;
  }

  Future<void> _handleRefresh() async {
    final onRefresh = widget.onRefresh;
    final entry = widget.entry;
    if (onRefresh == null ||
        entry?.requestParams == null ||
        entry?.status == EnrichStatus.streaming ||
        _refreshing) {
      return;
    }
    setState(() {
      _refreshing = true;
      _expanded = true;
    });
    try {
      await onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDone = entry?.status == EnrichStatus.done;
    final isError = entry?.status == EnrichStatus.error;
    final isStreaming = entry?.status == EnrichStatus.streaming;
    final hasPerson = entry?.person != null;
    final fromCache = entry?.fromCache ?? false;
    final isUpdating = isStreaming && hasPerson;
    final logs = entry?.toolLogs ?? const <EnrichToolLog>[];
    final hasLogs = logs.isNotEmpty;
    final name = entry?.person?.name;
    final title = enrichPanelTitle(
      isError: isError,
      isDone: isDone,
      hasPerson: hasPerson,
      fromCache: fromCache,
      name: name,
    );
    final canRefresh = widget.onRefresh != null &&
        entry?.requestParams != null &&
        !isStreaming &&
        !_refreshing;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F7F4),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: hasLogs ? () => setState(() => _expanded = !_expanded) : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171717),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUpdating) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF9E9A94),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Fetching latest',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9A94),
                                ),
                              ),
                            ],
                            if (hasLogs)
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: const Color(0xFF9CA3AF),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canRefresh ? _handleRefresh : null,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    color: const Color(0xFF6B7280),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          if (hasLogs && entry != null)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EnrichToolLogTimeline(
                        toolLogs: entry.toolLogs,
                        errorMessage: entry.errorMessage,
                        hasMore: isDone,
                      ),
                      if (isDone)
                        const Padding(
                          padding: EdgeInsets.only(left: 28, top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 14, color: Color(0xFF22C55E)),
                              SizedBox(width: 8),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
