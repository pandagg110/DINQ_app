import 'package:flutter/material.dart';

/// 对齐 Web `components/common/ConfirmDialog.tsx`。
class ConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    required String okText,
    ButtonStyle? okStyle,
    String cancelText = 'Cancel',
    bool showCancelButton = true,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: _ConfirmDialogContent(
              title: title,
              content: content,
              okText: okText,
              okStyle: okStyle,
              cancelText: cancelText,
              showCancelButton: showCancelButton,
              onCancel: () => Navigator.of(ctx).pop(false),
              onConfirm: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 24,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _ConfirmDialogContent(
                title: title,
                content: content,
                okText: okText,
                okStyle: okStyle,
                cancelText: cancelText,
                showCancelButton: showCancelButton,
                onCancel: () => Navigator.of(ctx).pop(false),
                onConfirm: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialogContent extends StatelessWidget {
  const _ConfirmDialogContent({
    required this.title,
    required this.content,
    required this.okText,
    this.okStyle,
    required this.cancelText,
    required this.showCancelButton,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String content;
  final String okText;
  final ButtonStyle? okStyle;
  final String cancelText;
  final bool showCancelButton;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  static const _kTextPrimary = Color(0xFF171717);
  static const _kTextBody = Color(0xFF575757);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kHoverBg = Color(0xFFF5F5F5);

  ButtonStyle get _defaultOkStyle => ElevatedButton.styleFrom(
        backgroundColor: _kTextPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      );

  ButtonStyle get _cancelStyle => OutlinedButton.styleFrom(
        foregroundColor: _kTextPrimary,
        backgroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: _kBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                  height: 1.3,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCancel,
                borderRadius: BorderRadius.circular(999),
                hoverColor: _kHoverBg,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close, size: 20, color: Color(0xFF575757)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _kTextBody,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showCancelButton) ...[
              OutlinedButton(
                onPressed: onCancel,
                style: _cancelStyle,
                child: Text(cancelText),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton(
              onPressed: onConfirm,
              style: okStyle ?? _defaultOkStyle,
              child: Text(okText),
            ),
          ],
        ),
      ],
    );
  }
}
