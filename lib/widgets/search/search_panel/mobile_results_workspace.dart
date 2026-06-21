import 'package:flutter/material.dart';

import '../deep_search/deep_search_results.dart';
import '../deep_search/deep_search_results_helpers.dart';

/// 与 TSX `AgenticChat` showMobileResultsWorkspace 对齐。
class MobileResultsWorkspace extends StatelessWidget {
  const MobileResultsWorkspace({
    super.key,
    required this.candidates,
    required this.isSearching,
    required this.isInterrupted,
    required this.onClose,
    required this.onRowClick,
    this.selectedRowId,
  });

  final List<Map<String, dynamic>> candidates;
  final bool isSearching;
  final bool isInterrupted;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> row) onRowClick;
  final String? selectedRowId;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEAE8E3))),
            ),
            padding: EdgeInsets.only(top: topPadding),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    color: const Color(0xFF171717),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      'Search results (${candidates.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          Expanded(
            child: DeepSearchResults(
              candidates: candidates,
              isSearching: isSearching,
              isInterrupted: isInterrupted,
              selectedRowId: selectedRowId,
              onRowClick: (row) => onRowClick(candidateRowToTabCandidate(row)),
            ),
          ),
        ],
      ),
    );
  }
}
