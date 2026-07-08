import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/search_service.dart';
import '../../stores/deep_search_enrich_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import 'agentic_chat_widget.dart';
import '../../models/deep_search_enrich_models.dart';
import 'enrich/enrich_header.dart';
import 'enrich/enrich_profile_view.dart';
import 'enrich/enrich_stream_controller.dart';

/// 对齐 Web `AgenticSearchContent.tsx`：主聊天 + Enrich 侧栏/底部面板。
class AgenticSearchContentWidget extends StatefulWidget {
  const AgenticSearchContentWidget({
    super.key,
    this.embeddedInMainTab = true,
    this.onSearchComplete,
  });

  final bool embeddedInMainTab;
  final void Function(List<Map<String, dynamic>> candidates, String query)?
  onSearchComplete;

  @override
  State<AgenticSearchContentWidget> createState() =>
      _AgenticSearchContentWidgetState();
}

class _AgenticSearchContentWidgetState
    extends State<AgenticSearchContentWidget> {
  static const _enrichMinWidth = 360.0;
  static const _enrichMaxWidth = 700.0;
  static const _enrichDefaultWidth = 520.0;

  EnrichStreamController? _enrichController;
  double _enrichWidth = _enrichDefaultWidth;
  bool _isDragging = false;
  bool _controllerReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerReady) return;
    _controllerReady = true;
    _enrichController = EnrichStreamController(
      enrichStore: context.read<DeepSearchEnrichStore>(),
      searchService: SearchService(),
      sessionIdProvider: () =>
          context.read<SearchStore>().deepSearchSessionId ?? '',
    );
  }

  @override
  void dispose() {
    _enrichController?.close();
    super.dispose();
  }

  void _onEnrichRowClick(Map<String, dynamic> row) {
    _enrichController?.openEnrich(row);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.watch<SettingsStore>().isMobile;

    return Consumer<DeepSearchEnrichStore>(
      builder: (context, enrichStore, _) {
        final isEnrichOpen = enrichStore.isOpen;
        final enrichEntry = enrichStore.selectedEntry;
        final selectedRowId = enrichStore.selectedRowId;

        final chat = AgenticChatWidget(
          embeddedInMainTab: widget.embeddedInMainTab,
          onSearchComplete: widget.onSearchComplete,
          onEnrichRowClick: _onEnrichRowClick,
          enrichSelectedRowId: selectedRowId,
        );

        if (isMobile) {
          return Stack(
            children: [
              chat,
              if (isEnrichOpen)
                _EnrichBottomSheet(
                  entry: enrichEntry,
                  selectedRowId: selectedRowId,
                  confidencePct: enrichStore.confidenceFor(selectedRowId),
                  onClose: () => _enrichController?.close(),
                  onRefresh: () =>
                      _enrichController?.refreshEnrich() ?? Future.value(),
                ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 480),
                child: chat,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isEnrichOpen ? _enrichWidth : 0,
              child: isEnrichOpen
                  ? Row(
                      children: [
                        _ResizeHandle(
                          onDragStart: () => setState(() => _isDragging = true),
                          onDragUpdate: (dx) {
                            setState(() {
                              _enrichWidth = (_enrichWidth - dx).clamp(
                                _enrichMinWidth,
                                _enrichMaxWidth,
                              );
                            });
                          },
                          onDragEnd: () => setState(() => _isDragging = false),
                          isDragging: _isDragging,
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: Colors.white,
                            child: Column(
                              children: [
                                EnrichHeader(
                                  entry: enrichEntry,
                                  onClose: () => _enrichController?.close(),
                                  onRefresh: () =>
                                      _enrichController?.refreshEnrich() ??
                                      Future.value(),
                                ),
                                Expanded(
                                  child: enrichEntry == null
                                      ? const SizedBox.shrink()
                                      : SingleChildScrollView(
                                          child: EnrichProfileView(
                                            entry: enrichEntry,
                                            selectedRowId: selectedRowId,
                                            confidencePct: enrichStore
                                                .confidenceFor(selectedRowId),
                                            onRefresh: () =>
                                                _enrichController
                                                    ?.refreshEnrich() ??
                                                Future.value(),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.isDragging,
  });

  final VoidCallback onDragStart;
  final void Function(double dx) onDragUpdate;
  final VoidCallback onDragEnd;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => onDragStart(),
      onHorizontalDragUpdate: (d) => onDragUpdate(d.delta.dx),
      onHorizontalDragEnd: (_) => onDragEnd(),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: SizedBox(
          width: 16,
          child: Center(
            child: Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFDFCFA),
                border: Border.all(color: const Color(0xFFE5E3DE)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnrichBottomSheet extends StatelessWidget {
  const _EnrichBottomSheet({
    required this.entry,
    required this.selectedRowId,
    required this.confidencePct,
    required this.onClose,
    required this.onRefresh,
  });

  final EnrichEntry? entry;
  final String? selectedRowId;
  final int? confidencePct;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEAE8E3))),
              ),
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
                  ],
                ),
              ),
            ),
            Expanded(
              // 内容滚动 + 操作按钮固定底部由 EnrichProfileView 整页模式负责
              child: entry == null
                  ? const SizedBox.shrink()
                  : EnrichProfileView(
                      entry: entry!,
                      isMobile: true,
                      pinActionsToBottom: true,
                      selectedRowId: selectedRowId,
                      confidencePct: confidencePct,
                      onRefresh: onRefresh,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
