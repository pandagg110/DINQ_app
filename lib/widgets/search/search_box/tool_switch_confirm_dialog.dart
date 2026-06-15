import 'package:flutter/material.dart';

/// 与 TSX `SearchBox.tsx` 中 `getToolConfirmMessage` 对齐。
String getToolConfirmMessage(String toolId) {
  switch (toolId) {
    case 'find-advisor':
      return 'Upload a resume and describe your research interests to find matching academic advisors.';
    case 'who-cites-me':
      return 'Find papers and researchers that cite your work, then explore citation context and relevance.';
    case 'analysis':
      return 'Analyze a GitHub, Scholar, or LinkedIn profile and turn it into structured evaluation insights.';
    default:
      return 'Switch the search box to this tool.';
  }
}

/// 与 TSX `ConfirmDialog` + `handleToolSelect` 对齐。
Future<bool?> showToolSwitchConfirm({
  required BuildContext context,
  required String toolLabel,
  required String toolId,
  required bool isMobile,
}) {
  final title = 'Switch to $toolLabel?';
  final message = getToolConfirmMessage(toolId);

  if (isMobile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ToolSwitchConfirmSheet(
        title: title,
        message: message,
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: _ToolSwitchConfirmBody(
            title: title,
            message: message,
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        ),
      ),
    ),
  );
}

class _ToolSwitchConfirmSheet extends StatelessWidget {
  const _ToolSwitchConfirmSheet({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _ToolSwitchConfirmBody(
              title: title,
              message: message,
              onCancel: () => Navigator.of(context).pop(false),
              onConfirm: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolSwitchConfirmBody extends StatelessWidget {
  const _ToolSwitchConfirmBody({
    required this.title,
    required this.message,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF575757),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF575757),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ConfirmButton(
                label: 'Cancel',
                outlined: true,
                onTap: onCancel,
              ),
              const SizedBox(width: 8),
              _ConfirmButton(
                label: 'Switch',
                outlined: false,
                onTap: onConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.label,
    required this.outlined,
    required this.onTap,
  });

  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.white : const Color(0xFF171717),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: outlined
                ? Border.all(color: const Color(0xFFE5E5E5))
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: outlined ? const Color(0xFF171717) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
