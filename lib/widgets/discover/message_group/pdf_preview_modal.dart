import 'package:flutter/material.dart';

/// PDF 预览 Modal（与 TSX PdfPreviewModal 对应）
class PdfPreviewModal extends StatelessWidget {
  const PdfPreviewModal({
    super.key,
    required this.url,
    required this.name,
    required this.onClose,
  });

  final String url;
  final String name;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black54,
          onDismiss: onClose,
        ),
        Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: url.isNotEmpty
                        ? const Center(
                            child: Text(
                              'PDF 预览（可在此嵌入 WebView）',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
