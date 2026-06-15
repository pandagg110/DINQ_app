import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../stores/search_store.dart';
import 'search_box_types.dart';

/// 与 TSX AnalysisPanel 对齐（移动端简化版）
class AnalysisPanel extends StatefulWidget {
  const AnalysisPanel({
    super.key,
    required this.onSearch,
    required this.onClearTool,
    required this.onCanSubmitChange,
    required this.panelHandle,
    this.platform = 'scholar',
    this.onPlatformChange,
    this.candidates,
    this.onClearCandidates,
  });

  final ValueChanged<AnalysisSearchParams> onSearch;
  final VoidCallback onClearTool;
  final ValueChanged<bool> onCanSubmitChange;
  final ToolPanelHandle panelHandle;
  final String platform;
  final ValueChanged<String>? onPlatformChange;
  final List<Map<String, dynamic>>? candidates;
  final VoidCallback? onClearCandidates;

  @override
  State<AnalysisPanel> createState() => _AnalysisPanelState();
}

class _AnalysisPanelState extends State<AnalysisPanel> {
  final TextEditingController _controller = TextEditingController();
  late String _platform;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;
  bool get _hasCandidates => widget.candidates != null && widget.candidates!.isNotEmpty;

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    widget.onSearch(AnalysisSearchParams(platform: _platform, query: query));
    _controller.clear();
    widget.onCanSubmitChange(false);
  }

  @override
  void initState() {
    super.initState();
    _platform = widget.platform;
    widget.panelHandle.getCanSubmit = () => _canSubmit;
    widget.panelHandle.submit = _submit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingFill());
  }

  @override
  void didUpdateWidget(covariant AnalysisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.platform != widget.platform) _platform = widget.platform;
  }

  void _consumePendingFill() {
    final store = context.read<SearchStore>();
    final fill = store.pendingFill?.trim();
    if (fill == null || fill.isEmpty) return;
    _controller.text = fill;
    store.clearPendingFill();
    final detected = _detectPlatform(fill);
    if (detected != null && detected != _platform) {
      _platform = detected;
      widget.onPlatformChange?.call(detected);
    }
    widget.onCanSubmitChange(_canSubmit);
    setState(() {});
  }

  String? _detectPlatform(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('scholar.google.com')) return 'scholar';
    if (lower.contains('github.com')) return 'github';
    if (lower.contains('linkedin.com')) return 'linkedin';
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchStore>(
      builder: (context, store, _) {
        if (store.pendingFill != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _consumePendingFill();
          });
        }
        return _buildContent();
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: kToolPanelHeaderDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _platformButton('scholar', Icons.school_outlined),
                  _divider(),
                  _platformButton('github', Icons.code),
                  _divider(),
                  _platformButton('linkedin', Icons.business),
                ],
              ),
              if (_hasCandidates) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.candidates!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final c = widget.candidates![index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            widget.onSearch(
                              AnalysisSearchParams(
                                platform: _platform,
                                query: c['url']?.toString() ?? c['name']?.toString() ?? '',
                                candidateData: c,
                              ),
                            );
                            widget.onClearCandidates?.call();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (c['content'] != null)
                                  Text(
                                    c['content'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!_hasCandidates)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: searchBoxInputDecoration(
                hintText: kAnalysisPlaceholders[_platform] ??
                    kAnalysisPlaceholders['scholar']!,
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937), height: 1.75),
              onChanged: (value) {
                final detected = _detectPlatform(value);
                if (detected != null && detected != _platform) {
                  setState(() => _platform = detected);
                  widget.onPlatformChange?.call(detected);
                }
                widget.onCanSubmitChange(_canSubmit);
              },
              onSubmitted: (_) {
                if (_canSubmit) _submit();
              },
            ),
          ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFD6D3CD),
    );
  }

  Widget _platformButton(String platform, IconData icon) {
    final selected = _platform == platform;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _platform = platform;
            _controller.clear();
          });
          widget.onPlatformChange?.call(platform);
          widget.onClearCandidates?.call();
          widget.onCanSubmitChange(_canSubmit);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? const Color(0xFF6B6862) : const Color(0xFF9E9B93),
              ),
              const SizedBox(width: 6),
              Text(
                kAnalysisPlatformLabels[platform] ?? platform,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? const Color(0xFF6B6862) : const Color(0xFF9E9B93),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
