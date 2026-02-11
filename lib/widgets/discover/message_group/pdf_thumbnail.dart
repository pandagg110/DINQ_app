import 'package:flutter/material.dart';

/// PDF 预览缩略图（与 TSX PdfThumbnail 对应）
class PdfThumbnail extends StatelessWidget {
  const PdfThumbnail({
    super.key,
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.description, size: 40, color: Color(0xFFD1D5DB)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF616A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PDF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
