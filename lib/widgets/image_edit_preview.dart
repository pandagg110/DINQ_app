import 'package:flutter/material.dart';

/// 独立的图片编辑预览组件：仅负责按 offsetX/offsetY/scale 渲染图片与可选 caption，
/// 不依赖 CardRenderer，避免与卡片业务的选中、编辑弹窗等逻辑耦合，便于在编辑页单独维护。
class ImageEditPreview extends StatelessWidget {
  const ImageEditPreview({
    super.key,
    required this.imageUrl,
    this.caption = '',
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scale = 1.0,
    this.renderWidth,
    this.renderHeight,
    this.borderRadius = 24,
  });

  final String imageUrl;
  final String caption;
  final double offsetX;
  final double offsetY;
  final double scale;
  final double? renderWidth;
  final double? renderHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (imageUrl.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final containerWidth = constraints.maxWidth;
                  final containerHeight = constraints.maxHeight;

                  double? imageWidth;
                  double? imageHeight;
                  if (renderWidth != null &&
                      renderWidth! > 0 &&
                      renderHeight != null &&
                      renderHeight! > 0) {
                    imageWidth = renderWidth;
                    imageHeight = renderHeight;
                  } else {
                    imageWidth = containerWidth;
                    imageHeight = containerHeight;
                  }
                  return Center(
                    child: Container(
                      width: imageWidth,
                      height: imageHeight,
                      child: Transform.translate(
                        offset: Offset(-offsetX, offsetY),
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            height: imageHeight,
                            child: Image.network(imageUrl, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        // 第一层：背景
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 9999,
                    spreadRadius: 9999,
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final containerWidth = constraints.maxWidth;
                  final containerHeight = constraints.maxHeight;
                  double? imageWidth;
                  double? imageHeight;
                  if (renderWidth != null &&
                      renderWidth! > 0 &&
                      renderHeight != null &&
                      renderHeight! > 0) {
                    imageWidth = renderWidth;
                    imageHeight = renderHeight;
                  } else {
                    imageWidth = containerWidth;
                    imageHeight = containerHeight;
                  }
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Transform.translate(
                        offset: Offset(-offsetX, offsetY),
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            height: imageHeight,
                            child: Image.network(imageUrl, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 第二层：图片，位置与大小仍由 offsetX / offsetY / scale 决定（不裁剪，避免切割）
        if (imageUrl.isEmpty)
          Positioned.fill(
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🖼️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text(
                    'No media',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (caption.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 12,
            child: _buildCaptionDisplay(context, caption),
          ),
        // 最上层：仅边框，不遮挡图片
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: Colors.transparent,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionDisplay(BuildContext context, String caption) {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          caption,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF171717),
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
