import 'package:flutter/material.dart';

import '../../../constants/shortlist_constants.dart';
import '../../../models/shortlist_models.dart';
import '../../../theme/dinq_tokens.dart';
import '../shortlist_strings.dart';

/// 对齐 Web `ConfirmModal.tsx`。
class ShortlistConfirmModal extends StatelessWidget {
  const ShortlistConfirmModal({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.variant = ShortlistConfirmVariant.defaultVariant,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String? message;
  final String? confirmLabel;
  final String? cancelLabel;
  final ShortlistConfirmVariant variant;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    ShortlistConfirmVariant variant = ShortlistConfirmVariant.defaultVariant,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => ShortlistConfirmModal(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        variant: variant,
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          Navigator.pop(ctx);
          await onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirm = confirmLabel ?? ShortlistStrings.confirmModalConfirm;
    final cancel = cancelLabel ?? ShortlistStrings.confirmModalCancel;
    final destructive = variant == ShortlistConfirmVariant.destructive;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 40,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B6962),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  label: cancel,
                  onTap: onCancel,
                  outlined: true,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: confirm,
                  onTap: onConfirm,
                  destructive: destructive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum ShortlistConfirmVariant { defaultVariant, destructive }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined
          ? Colors.white
          : destructive
              ? const Color(0xFFB94A4A)
              : const Color(0xFF171717),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: outlined
                ? Border.all(color: const Color(0xFFE5E3DE))
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: outlined
                  ? const Color(0xFF6B6962)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 对齐 `my_first_app` `_ShortlistStatusPill`。
class ShortlistStatusBadge extends StatelessWidget {
  const ShortlistStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeFavoriteStatus(status);
    final color = shortlistStatusAccentColor(normalized);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              ShortlistStrings.statusLabelFor(normalized),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 对齐 `my_first_app` `_ShortlistCheckbox`。
class ShortlistSelectCheckbox extends StatelessWidget {
  const ShortlistSelectCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.size = ShortlistCheckboxSize.sm,
  });

  final bool checked;
  final VoidCallback onChanged;
  final ShortlistCheckboxSize size;

  @override
  Widget build(BuildContext context) {
    final box = size == ShortlistCheckboxSize.md ? 20.0 : 20.0;
    final icon = size == ShortlistCheckboxSize.md ? 14.0 : 14.0;
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: box,
        height: box,
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF2F6FED) : DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: checked ? const Color(0xFF2F6FED) : const Color(0xFFD7D2CA),
            width: checked ? 0.5 : 1,
          ),
        ),
        child: checked
            ? Icon(Icons.check_rounded, size: icon, color: DinqTokens.bgCard)
            : null,
      ),
    );
  }
}

enum ShortlistCheckboxSize { sm, md }

bool isRecentlyAddedFavorite(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return false;
  final t = DateTime.tryParse(createdAt);
  if (t == null) return false;
  return DateTime.now().difference(t).inMilliseconds < shortlistNewThresholdMs;
}

String buildEnrichTextFromFavorite(FavoriteItem item) {
  return [
    item.name,
    item.roleTitle,
    item.company,
    item.evidence,
    if (item.profileUrl.isNotEmpty) 'Profile: ${item.profileUrl}',
  ].where((e) => e.toString().trim().isNotEmpty).join('. ');
}
