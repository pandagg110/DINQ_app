// NoteEditForm - NOTE 卡片编辑表单
// 编辑 text, fontSize, fontColor, bgColor, align, link

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/card_models.dart';
import '../../../stores/card_store.dart';

const _fontSizes = [12, 14, 16, 18, 20, 24, 28, 32];

// 圆形色板：2 行 x 6 列，与 UI 设计一致
const _colorPalette = [
  '#FFFFFF',
  '#93C5FD',
  '#3B82F6',
  '#FBBF24',
  '#F97316',
  '#F9A8D4',
  '#C4B5FD',
  '#8B5CF6',
  '#6EE7B7',
  '#0D9488',
  '#15803D',
  '#525252',
  '#000000',
];

/// 根据背景色计算对比文字颜色
String _getContrastFontColor(String bgColor) {
  try {
    final hex = bgColor.replaceFirst('#', '');
    if (hex.length < 6) return '#171717';
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5 ? '#000000' : '#FFFFFF';
  } catch (_) {
    return '#171717';
  }
}

final _inputDecoration = InputDecoration(
  hintText: 'Enter your note...',
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFF0C0C0C)),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
);

/// NOTE 编辑表单（含 save 逻辑），供 EditCardDialog 使用
class NoteEditFormWithSave extends StatefulWidget {
  const NoteEditFormWithSave({
    super.key,
    required this.card,
    required this.onSaveReady,
  });

  final CardItem card;
  final void Function(Future<void> Function() save) onSaveReady;

  @override
  State<NoteEditFormWithSave> createState() => _NoteEditFormWithSaveState();
}

class _NoteEditFormWithSaveState extends State<NoteEditFormWithSave> {
  late final TextEditingController _textController;
  late final TextEditingController _linkController;
  late int _fontSize;
  late String _bgColor;
  late String _fontColor;
  late List<String> _align;

  @override
  void initState() {
    super.initState();
    final meta = widget.card.data.metadata;
    _textController = TextEditingController(
      text: meta['text']?.toString() ?? meta['content']?.toString() ?? '',
    );
    _linkController = TextEditingController(
      text: meta['link']?.toString() ?? meta['url']?.toString() ?? '',
    );
    _fontSize = meta['fontSize'] is int
        ? meta['fontSize'] as int
        : (meta['fontSize'] is num
              ? (meta['fontSize'] as num).toInt()
              : int.tryParse(meta['fontSize']?.toString() ?? '14') ?? 14);
    if (!_fontSizes.contains(_fontSize)) _fontSize = 14;
    _bgColor = meta['bgColor']?.toString() ?? '#FFFFFF';
    _fontColor =
        meta['fontColor']?.toString() ?? _getContrastFontColor(_bgColor);
    final alignRaw = meta['align'];
    if (alignRaw is List && alignRaw.length >= 2) {
      _align = [
        alignRaw[0]?.toString() ?? 'left',
        alignRaw[1]?.toString() ?? 'center',
      ];
    } else {
      _align = ['left', 'center'];
    }
    widget.onSaveReady(_performSave);
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _performSave() async {
    if (!mounted) return;
    final cardStore = context.read<CardStore>();
    final newMetadata = Map<String, dynamic>.from(widget.card.data.metadata);
    newMetadata['text'] = _textController.text;
    newMetadata['fontSize'] = _fontSize;
    newMetadata['fontColor'] = _fontColor;
    newMetadata['bgColor'] = _bgColor;
    newMetadata['align'] = _align;
    newMetadata['link'] = _linkController.text.trim();
    newMetadata['url'] = _linkController.text.trim();

    cardStore.updateCardData(
      widget.card.id,
      CardData(
        id: widget.card.data.id,
        type: widget.card.data.type,
        title: widget.card.data.title,
        description: widget.card.data.description,
        metadata: newMetadata,
        status: widget.card.data.status,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _setBgColor(String color) {
    setState(() {
      _bgColor = color;
      _fontColor = _getContrastFontColor(color);
    });
  }

  void _setAlignHorizontal(String h) {
    setState(() => _align = [h, _align.length > 1 ? _align[1] : 'center']);
  }

  void _setAlignVertical(String v) {
    setState(() => _align = [_align.isNotEmpty ? _align[0] : 'left', v]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNotePreview(),
        const SizedBox(height: 20),
        _buildLabel('Font size'),
        const SizedBox(height: 8),
        _buildFontSizeDropdown(),
        const SizedBox(height: 20),
        _buildLabel('Color'),
        const SizedBox(height: 8),
        _buildColorGrid(),
        const SizedBox(height: 20),
        _buildLabel('Text alignment'),
        const SizedBox(height: 8),
        _buildTextAlignment(),
        const SizedBox(height: 20),
        _buildLabel('Link URL'),
        const SizedBox(height: 8),
        TextField(
          controller: _linkController,
          decoration: _inputDecoration.copyWith(
            hintText: 'Enter a Link',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
          maxLines: 1,
        ),
      ],
    );
  }

  /// 使用 NoteCard 渲染方式的预览，颜色/布局修改时实时更新
  Widget _buildNotePreview() {
    final bgColor = _parseColor(_bgColor);
    final fontColor = _parseColor(_fontColor);
    final horizontalAlign = _align.isNotEmpty ? _align[0] : 'left';
    final verticalAlign = _align.length > 1 ? _align[1] : 'center';

    TextAlign textAlign = TextAlign.left;
    if (horizontalAlign == 'center') {
      textAlign = TextAlign.center;
    } else if (horizontalAlign == 'right') {
      textAlign = TextAlign.right;
    }

    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center;
    if (verticalAlign == 'top') {
      mainAxisAlignment = MainAxisAlignment.start;
    } else if (verticalAlign == 'bottom') {
      mainAxisAlignment = MainAxisAlignment.end;
    }

    const previewRadius = 24.0;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(previewRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(previewRadius),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(previewRadius),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            color: bgColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  minLines: 1,
                  style: TextStyle(
                    fontSize: _fontSize.toDouble(),
                    color: fontColor,
                    fontFamily: 'Geist',
                  ),
                  textAlign: textAlign,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: 'Enter your note...',
                    hintStyle: TextStyle(
                      color: fontColor.withValues(alpha: 0.5),
                      fontSize: _fontSize.toDouble(),
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF171717),
      ),
    );
  }

  Widget _buildFontSizeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _fontSize,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
          items: _fontSizes
              .map((s) => DropdownMenuItem(value: s, child: Text('${s}px')))
              .toList(),
          onChanged: (v) => setState(() => _fontSize = v ?? _fontSize),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorPalette.map((c) {
        final selected = _bgColor.toUpperCase() == c.toUpperCase();
        return GestureDetector(
          onTap: () => _setBgColor(c),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _parseColor(c),
              border: Border.all(
                color: selected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
                width: selected ? 2.5 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 与 PreviewEditToggle 同款样式：灰色底 + 白色滑块滑动动画
  Widget _buildTextAlignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAlignSegmentedControl(
          items: const [
            (Icons.format_align_left, 'left'),
            (Icons.format_align_center, 'center'),
            (Icons.format_align_right, 'right'),
          ],
          current: _align.isNotEmpty ? _align[0] : 'left',
          onSelect: _setAlignHorizontal,
        ),
        const SizedBox(height: 8),
        _buildAlignSegmentedControl(
          items: const [
            (Icons.vertical_align_top, 'top'),
            (Icons.vertical_align_center, 'center'),
            (Icons.vertical_align_bottom, 'bottom'),
          ],
          current: _align.length > 1 ? _align[1] : 'center',
          onSelect: _setAlignVertical,
        ),
      ],
    );
  }

  /// 与 PreviewEditToggle 一致：灰色容器 + AnimatedPositioned 滑块
  Widget _buildAlignSegmentedControl({
    required List<(IconData, String)> items,
    required String current,
    required void Function(String) onSelect,
  }) {
    final index = items.indexWhere((e) => e.$2 == current);
    final selectedIndex = index >= 0 ? index : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const inset = 4.0;
        final segmentWidth = (w - inset * 2) / items.length;
        final sliderWidth = segmentWidth - inset;

        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: inset + selectedIndex * segmentWidth,
                top: inset,
                bottom: inset,
                width: sliderWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onSelect(items[i].$2),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Icon(
                            items[i].$1,
                            size: 20,
                            color: selectedIndex == i
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse(h, radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF171717);
    }
  }
}
