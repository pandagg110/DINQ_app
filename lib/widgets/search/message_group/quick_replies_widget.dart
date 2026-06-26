import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../stores/quick_replies_store.dart';

/// 与 TSX `QuickReplies.tsx` 严格对齐。
class QuickRepliesWidget extends StatefulWidget {
  const QuickRepliesWidget({
    super.key,
    required this.blockId,
    required this.options,
    required this.onSelect,
    this.showCustomInput = true,
    this.ephemeral = false,
  });

  final String blockId;
  final List<String> options;
  final ValueChanged<String> onSelect;
  final bool showCustomInput;
  final bool ephemeral;

  @override
  State<QuickRepliesWidget> createState() => _QuickRepliesWidgetState();
}

class _QuickRepliesWidgetState extends State<QuickRepliesWidget> {
  final TextEditingController _customInputController = TextEditingController();

  @override
  void dispose() {
    _customInputController.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!widget.ephemeral) {
      context.read<QuickRepliesStore>().markUsed(widget.blockId);
    }
    widget.onSelect(trimmed);
  }

  double _resolveMaxWidth(BoxConstraints constraints) {
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      return constraints.maxWidth;
    }
    final media = MediaQuery.sizeOf(context);
    return media.width - MediaQuery.paddingOf(context).horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final isUsed = context.watch<QuickRepliesStore>().isUsed(widget.blockId);
    if ((!widget.ephemeral && isUsed) || widget.options.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.options.length == 2) {
      final primary = widget.options[0];
      final secondary = widget.options[1];
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _BinaryQuickReplies(
              maxWidth: _resolveMaxWidth(constraints),
              primary: primary,
              secondary: secondary,
              onPrimary: () => _submit(primary),
              onSecondary: () => _submit(secondary),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.options.map((opt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => _submit(opt),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2A2826),
                    side: const BorderSide(color: Color(0xFFE5E3DE)),
                    backgroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 15, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.showCustomInput) _CustomInputRow(onSubmit: _submit),
        ],
      ),
    );
  }
}

/// 双选项：Web `mt-3 flex items-center gap-5`，主按钮文字在按钮内换行。
class _BinaryQuickReplies extends StatelessWidget {
  const _BinaryQuickReplies({
    required this.maxWidth,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
  });

  static const _binaryGap = 20.0;

  final double maxWidth;
  final String primary;
  final String secondary;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: _PrimaryButton(label: primary, onTap: onPrimary),
          ),
          const SizedBox(width: _binaryGap),
          Expanded(
            child: _SecondaryButton(label: secondary, onTap: onSecondary),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2826),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF3A3836),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: _labelStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.subdirectory_arrow_left,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.25,
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFF6B6862).withValues(alpha: 0.08),
        splashColor: const Color(0xFF6B6862).withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: Color(0xFFA5A39E),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}

class _CustomInputRow extends StatefulWidget {
  const _CustomInputRow({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_CustomInputRow> createState() => _CustomInputRowState();
}

class _CustomInputRowState extends State<_CustomInputRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E3DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              onSubmitted: widget.onSubmit,
              style: const TextStyle(
                fontSize: 15,
                height: 1.25,
                color: Color(0xFF2A2826),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Or type your own…',
                hintStyle: TextStyle(color: Color(0xFFA5A39E)),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Material(
            color: hasText
                ? const Color(0xFFD5D3CE)
                : const Color(0xFFE5E3DE),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: hasText ? () => widget.onSubmit(_controller.text) : null,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: hasText
                      ? const Color(0xFF6B6862)
                      : const Color(0xFF6B6862).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
