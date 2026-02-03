import 'package:flutter/material.dart';
import '../card_definition.dart';

class ImageCardDefinition extends CardDefinition {
  @override
  String get type => 'IMAGE';

  @override
  String get icon => '/icons/img.png';

  @override
  String get name => 'Image';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
    desktop: CardSizeConfig(
      supported: ['2x2', '2x4', '4x2', '4x4'],
      defaultSize: '4x4',
    ),
    mobile: CardSizeConfig(
      supported: ['2x2', '2x4', '4x2', '4x4'],
      defaultSize: '4x4',
    ),
  );

  @override
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
    return null; // No adaptation needed
  }

  @override
  Widget render(CardRenderParams params) {
    return _ImageCardWidget(card: params.card);
  }
}

class _ImageCardWidget extends StatelessWidget {
  const _ImageCardWidget({required this.card});

  final dynamic card;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final imageUrl = metadata['url']?.toString() ?? '';
    final caption = metadata['caption']?.toString() ?? '';

    // 从 metadata 读取裁剪参数
    final offsetX = (metadata['offsetX'] as num?)?.toDouble() ?? 0.0;
    final offsetY = (metadata['offsetY'] as num?)?.toDouble() ?? 0.0;
    final scale = (metadata['scale'] as num?)?.toDouble() ?? 1.0;
    final renderWidth = (metadata['renderWidth'] as num?)?.toDouble();
    final renderHeight = (metadata['renderHeight'] as num?)?.toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF3F4F6),
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Image content
          if (imageUrl.isNotEmpty)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 获取容器尺寸
                  final containerWidth = constraints.maxWidth;
                  final containerHeight = constraints.maxHeight;

                  // 计算图片尺寸
                  double? imageWidth;
                  double? imageHeight;

                  if (renderWidth != null &&
                      renderWidth > 0 &&
                      renderHeight != null &&
                      renderHeight > 0) {
                    imageWidth = renderWidth;
                    imageHeight = renderHeight;
                  } else {
                    // 如果没有指定尺寸，使用容器尺寸（类似 TSX 的 min-h-full min-w-full）
                    imageWidth = containerWidth;
                    imageHeight = containerHeight;
                  }
                  return Center(
                    child: OverflowBox(
                      maxHeight: imageHeight,
                      maxWidth: imageWidth + 1000,
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

          // Empty state
          if (imageUrl.isEmpty)
            const Center(
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

          // Caption display (左下角)
          if (caption.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 12,
              child: _buildCaptionDisplay(context, caption),
            ),
        ],
      ),
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
