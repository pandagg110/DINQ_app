import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_models.dart';
import '../stores/card_store.dart';
import '../stores/settings_store.dart';
import '../utils/card_layout_utils.dart';
import '../widgets/image_edit_preview.dart';

/// 图片裁剪/编辑页：使用独立组件 [ImageEditPreview] 渲染图片，支持拖拽平移和缩放，
/// 逻辑参考 TSX render.tsx 的编辑模式（offsetX, offsetY, scale）。
class EditImagePage extends StatefulWidget {
  const EditImagePage({
    super.key,
    required this.card,
    this.showBottomSizedBox = true,
  });

  final CardItem card;
  /// 是否显示底部 SizedBox（安全区/占位），默认 true
  final bool showBottomSizedBox;

  @override
  State<EditImagePage> createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> {
  static const double minScale = 1.0;
  static const double maxScale = 3.0;

  late double _offsetX;
  late double _offsetY;
  late double _scale;
  double _scaleStart = 1.0;

  @override
  void initState() {
    super.initState();
    debugPrint('[EditImagePage] 进入页面 cardId=${widget.card.id}');
    final m = widget.card.data.metadata;
    _offsetX = (m['offsetX'] as num?)?.toDouble() ?? 0.0;
    _offsetY = (m['offsetY'] as num?)?.toDouble() ?? 0.0;
    _scale = (m['scale'] as num?)?.toDouble() ?? 1.0;
  }


  void _onScaleStart(ScaleStartDetails details) {
    _scaleStart = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scaleStart * details.scale).clamp(minScale, maxScale);
      _offsetX -= details.focalPointDelta.dx;
      _offsetY += details.focalPointDelta.dy;
    });
  }

  void _saveAndPop() {
    debugPrint(
      '[EditImagePage] Done: scale=$_scale, offsetX=$_offsetX, offsetY=$_offsetY',
    );
    if (mounted) {
      Navigator.of(context).pop(<String, dynamic>{
        'scale': _scale,
        'offsetX': _offsetX,
        'offsetY': _offsetY,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridConfig = context.watch<SettingsStore>().gridConfig;
    // 与 image_edit_form Preview 使用同一套尺寸计算
    final size = CardLayoutUtils.getPreviewCardSize(
      screenWidth,
      gridConfig.mobileGap,
      widget.card.layout.mobile.size,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Edit Image',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF171717)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveAndPop,
            child: const Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF3F4F6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ImageEditPreview(
                    imageUrl: widget.card.data.metadata['url']?.toString() ?? '',
                    caption: widget.card.data.metadata['caption']?.toString() ?? '',
                    offsetX: _offsetX,
                    offsetY: _offsetY,
                    scale: _scale,
                    renderWidth: size.width,
                    renderHeight: size.height,
                    borderRadius: 8,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showBottomSizedBox)
            SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
