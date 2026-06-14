import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../stores/search_store.dart';
import 'search_box_types.dart';

/// 与 TSX CitationPanel 对齐
class CitationPanel extends StatefulWidget {
  const CitationPanel({
    super.key,
    required this.onSearch,
    required this.onClearTool,
    required this.onCanSubmitChange,
    required this.panelHandle,
    this.mode = CitationMode.author,
    this.onModeChange,
  });

  final ValueChanged<({String query})> onSearch;
  final VoidCallback onClearTool;
  final ValueChanged<bool> onCanSubmitChange;
  final ToolPanelHandle panelHandle;
  final CitationMode mode;
  final ValueChanged<CitationMode>? onModeChange;

  @override
  State<CitationPanel> createState() => _CitationPanelState();
}

class _CitationPanelState extends State<CitationPanel> {
  final TextEditingController _controller = TextEditingController();
  late CitationMode _mode;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    widget.onSearch((query: query));
    _controller.clear();
    widget.onCanSubmitChange(false);
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    widget.panelHandle.getCanSubmit = () => _canSubmit;
    widget.panelHandle.submit = _submit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingFill());
  }

  @override
  void didUpdateWidget(covariant CitationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) _mode = widget.mode;
  }

  void _consumePendingFill() {
    final store = context.read<SearchStore>();
    final fill = store.pendingFill?.trim();
    if (fill == null || fill.isEmpty) return;
    store.clearPendingFill();
    widget.onSearch((query: fill));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: kToolPanelHeaderDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeButton(
                label: 'By Author',
                icon: Icons.person_outline,
                selected: _mode == CitationMode.author,
                onTap: () {
                  setState(() {
                    _mode = CitationMode.author;
                    _controller.clear();
                  });
                  widget.onModeChange?.call(CitationMode.author);
                  widget.onCanSubmitChange(_canSubmit);
                },
              ),
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFFD6D3CD),
              ),
              _modeButton(
                label: 'By Paper',
                icon: Icons.description_outlined,
                selected: _mode == CitationMode.paper,
                onTap: () {
                  setState(() {
                    _mode = CitationMode.paper;
                    _controller.clear();
                  });
                  widget.onModeChange?.call(CitationMode.paper);
                  widget.onCanSubmitChange(_canSubmit);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: searchBoxInputDecoration(
              hintText: _mode == CitationMode.author
                  ? 'e.g. Yann LeCun, Geoffrey Hinton'
                  : 'e.g. Attention Is All You Need',
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937), height: 1.75),
            onChanged: (_) => widget.onCanSubmitChange(_canSubmit),
            onSubmitted: (_) {
              if (_canSubmit) _submit();
            },
          ),
        ),
      ],
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                label,
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
