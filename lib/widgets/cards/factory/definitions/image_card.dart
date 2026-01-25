import 'package:flutter/material.dart';
import '../card_definition.dart';

class ImageCardDefinition extends CardDefinition {
  @override
  String get type => 'IMAGE';

  @override
  String get icon => '/icons/image.svg';

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
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
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

    // 打印图片路径和裁剪参数
    if (imageUrl.isNotEmpty) {
      debugPrint('ImageCard - 需要加载的图片路径: $imageUrl');
      debugPrint('ImageCard - 裁剪参数: offsetX=$offsetX, offsetY=$offsetY, scale=$scale');
      debugPrint('ImageCard - 渲染尺寸: renderWidth=$renderWidth, renderHeight=$renderHeight');
    }

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
                  
                  if (renderWidth != null && renderWidth > 0 && renderHeight != null && renderHeight > 0) {
                    imageWidth = renderWidth;
                    imageHeight = renderHeight;
                  } else {
                    // 如果没有指定尺寸，使用容器尺寸（类似 TSX 的 min-h-full min-w-full）
                    imageWidth = containerWidth;
                    imageHeight = containerHeight;
                  }
                  
                  return Center(
                    child: Transform.translate(
                      // TSX: translate(calc(-50% - offsetX), calc(-50% + offsetY))
                      // Flutter: Center 已经将中心点对齐，translate 只需要应用 offsetX 和 offsetY
                      offset: Offset(-offsetX, offsetY),
                      child: Transform.scale(
                        scale: scale,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: imageWidth,
                            height: imageHeight,
                            child: Image.network(
                              imageUrl,
                              fit: renderWidth != null && renderHeight != null
                                  ? BoxFit.contain
                                  : BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('ImageCard - 图片加载失败: $imageUrl');
                                debugPrint('ImageCard - 错误: $error');
                                return Container(
                                  color: const Color(0xFFF3F4F6),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                );
                              },
                            ),
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
