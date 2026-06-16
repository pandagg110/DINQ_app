import 'package:flutter/material.dart';

import '../../../models/deep_search_enrich_models.dart';

bool _shouldShowToolName(String tool) {
  final normalized = tool.trim().toLowerCase();
  return normalized != 'perplexity' && normalized != 'ding ai search';
}

/// 对齐 Web `ToolLogTimeline.tsx`。
class EnrichToolLogTimeline extends StatelessWidget {
  const EnrichToolLogTimeline({
    super.key,
    required this.toolLogs,
    this.errorMessage,
    this.hasMore = false,
  });

  final List<EnrichToolLog> toolLogs;
  final String? errorMessage;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (toolLogs.isEmpty && (errorMessage == null || errorMessage!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final totalItems = toolLogs.length + (errorMessage != null ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < toolLogs.length; i++)
            _LogItem(
              log: toolLogs[i],
              showConnector: !((errorMessage == null) &&
                  !hasMore &&
                  i == totalItems - 1),
            ),
          if (errorMessage != null && errorMessage!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({required this.log, required this.showConnector});

  final EnrichToolLog log;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final isRunning = log.status == 'running';
    final showToolName = _shouldShowToolName(log.tool);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -28,
            top: 2,
            child: SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF716E6A),
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF22C55E),
                      ),
              ),
            ),
          ),
          if (showConnector)
            Positioned(
              left: -18,
              top: 20,
              bottom: -12,
              child: Container(width: 1, color: const Color(0xFFEAE7E0)),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.message.isNotEmpty ? log.message : log.tool,
                style: TextStyle(
                  fontSize: 14,
                  color: isRunning
                      ? const Color(0xFF9E9A94)
                      : const Color(0xFF374151),
                ),
              ),
              if (showToolName)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    log.tool,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9A94),
                    ),
                  ),
                ),
              if (log.sources != null && log.sources!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEAE7E0)),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFFAFAF8),
                  ),
                  child: Column(
                    children: [
                      for (var si = 0; si < log.sources!.length; si++)
                        _SourceRow(source: log.sources![si]),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final EnrichToolLogSource source;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAE7E0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                source.title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF716E6A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              source.domain,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9A94)),
            ),
          ],
        ),
      ),
    );
  }
}
