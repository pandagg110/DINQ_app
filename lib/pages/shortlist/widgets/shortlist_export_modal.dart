import 'package:flutter/material.dart';

import '../shortlist_strings.dart';

/// 对齐 Web `ExportModal.tsx`。
enum ShortlistExportFormat { csv, pdf }

class ShortlistExportModal extends StatelessWidget {
  const ShortlistExportModal({
    super.key,
    required this.onSelect,
    required this.onCancel,
    this.asSheet = true,
  });

  final ValueChanged<ShortlistExportFormat> onSelect;
  final VoidCallback onCancel;
  final bool asSheet;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<ShortlistExportFormat> onSelect,
    bool asSheet = true,
  }) {
    if (asSheet) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ShortlistExportModal(
          onSelect: (format) {
            Navigator.pop(ctx);
            onSelect(format);
          },
          onCancel: () => Navigator.pop(ctx),
          asSheet: true,
        ),
      );
    }
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => ShortlistExportModal(
        onSelect: (format) {
          Navigator.pop(ctx);
          onSelect(format);
        },
        onCancel: () => Navigator.pop(ctx),
        asSheet: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (asSheet) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ShortlistStrings.exportModalTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ShortlistStrings.exportModalSubtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6962),
              ),
            ),
            const SizedBox(height: 20),
            _ExportOptions(onSelect: onSelect),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ShortlistStrings.exportModalTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ShortlistStrings.exportModalSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6962),
                  ),
                ),
                const SizedBox(height: 20),
                _ExportOptions(onSelect: onSelect),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 16, color: Color(0xFF8A8880)),
                tooltip: ShortlistStrings.exportModalClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOptions extends StatelessWidget {
  const _ExportOptions({required this.onSelect});

  final ValueChanged<ShortlistExportFormat> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExportOptionTile(
          icon: Icons.download_outlined,
          label: ShortlistStrings.exportCsvLabel,
          description: ShortlistStrings.exportCsvDescription,
          onTap: () => onSelect(ShortlistExportFormat.csv),
        ),
        const SizedBox(height: 8),
        _ExportOptionTile(
          icon: Icons.description_outlined,
          label: ShortlistStrings.exportPdfLabel,
          description: ShortlistStrings.exportPdfDescription,
          onTap: () => onSelect(ShortlistExportFormat.pdf),
        ),
      ],
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAE8E3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEAE8E3)),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF6B6962)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A8880),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
