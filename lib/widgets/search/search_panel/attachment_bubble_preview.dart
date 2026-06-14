import 'package:flutter/material.dart';

import '../message_group/attachment_file_chip.dart';
import '../message_group/pdf_preview_modal.dart';

/// 与 TSX AttachmentBubblePreview 对齐。
class AttachmentBubblePreview extends StatefulWidget {
  const AttachmentBubblePreview({super.key, this.attachment});

  final Map<String, dynamic>? attachment;

  @override
  State<AttachmentBubblePreview> createState() =>
      _AttachmentBubblePreviewState();
}

class _AttachmentBubblePreviewState extends State<AttachmentBubblePreview> {
  bool _showModal = false;

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    if (attachment == null) return const SizedBox.shrink();

    final name = attachment['name']?.toString() ?? 'File';
    final url = attachment['url']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AttachmentFileChip(
          name: name,
          onTap: () => setState(() => _showModal = true),
        ),
        if (_showModal && url.isNotEmpty)
          PdfPreviewModal(
            url: url,
            name: name,
            onClose: () => setState(() => _showModal = false),
          ),
      ],
    );
  }
}
