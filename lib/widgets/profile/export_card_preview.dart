import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/card_models.dart';
import '../../models/user_models.dart';
import '../../services/upload_service.dart';
import '../share_card/share_card.dart';

/// 分享卡片预览组件，对应 Web [ExportCard](example/.../shareCard/ExportCard.tsx)。
/// 使用已迁移的 [ShareCard] 渲染主区域，并包含 Classic/Custom、Default/Colorful 控制。
class ExportCardPreview extends StatefulWidget {
  const ExportCardPreview({
    super.key,
    required this.userData,
    this.cards,
    this.height = 240,
    this.verifiedCount = 0,

    /// 可选主题初始值（与 TSX userInfo.theme 对应）
    this.theme,

    /// 是否可编辑主题（对应 TSX pathUsername === "admin"）
    this.isEditable = false,

    /// 主题变更回调（对应 TSX handleThemeChange -> updateUserData）
    this.onThemeChange,
  });

  final UserData userData;
  final List<CardItem>? cards;
  final double height;
  final int verifiedCount;

  /// theme.color, theme.mode, theme.leftCard, theme.rightCard, theme.logo
  final Map<String, String>? theme;
  final bool isEditable;
  final void Function(String key, String value)? onThemeChange;

  @override
  State<ExportCardPreview> createState() => _ExportCardPreviewState();
}

/// 与 ExportCard.tsx 一致
const List<String> _firstCards = ['LINKEDIN', 'GITHUB', 'SCHOLAR', 'BIO'];
const List<String> _secondCards = ['ACHIEVEMENT_NETWORK', 'CAREER_TRAJECTORY'];
const Map<String, String> _cardLabels = {
  'LINKEDIN': 'Linkedin',
  'GITHUB': 'Github',
  'SCHOLAR': 'Scholar',
  'BIO': 'Bio',
  'ACHIEVEMENT_NETWORK': 'Network',
  'CAREER_TRAJECTORY': 'Career',
};

class _ExportCardPreviewState extends State<ExportCardPreview> {
  /// classic | card，与 TSX userInfo.theme.mode 对应
  late String _themeMode;

  /// default | colorful，与 TSX userInfo.theme.color 对应
  late String _themeColor;

  /// Card 模式下的左/右卡片类型，与 TSX theme.leftCard / theme.rightCard 对应
  String? _leftCard;
  String? _rightCard;
  String? _logoUrl;
  bool _uploadingLogo = false;
  final _uploadService = UploadService();

  @override
  void initState() {
    super.initState();
    final userTheme = widget.userData.theme;
    _themeMode = widget.theme?['mode'] ?? userTheme?.mode ?? 'classic';
    _themeColor = widget.theme?['color'] ?? userTheme?.color ?? 'default';
    _leftCard = widget.theme?['leftCard'] ?? userTheme?.leftCard;
    _rightCard = widget.theme?['rightCard'] ?? userTheme?.rightCard;
    _logoUrl = widget.theme?['logo'] ?? userTheme?.logo;
  }

  @override
  void didUpdateWidget(ExportCardPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme ||
        widget.userData.theme != oldWidget.userData.theme) {
      final userTheme = widget.userData.theme;
      _themeMode = widget.theme?['mode'] ?? userTheme?.mode ?? 'classic';
      _themeColor = widget.theme?['color'] ?? userTheme?.color ?? 'default';
      _leftCard = widget.theme?['leftCard'] ?? userTheme?.leftCard;
      _rightCard = widget.theme?['rightCard'] ?? userTheme?.rightCard;
      _logoUrl = widget.theme?['logo'] ?? userTheme?.logo;
    }
  }

  /// 与 TSX cards.reduce: acc[card.data.type] = cloneDeep(card.data.metadata)
  Map<String, dynamic> get _cardsMap {
    final list = widget.cards;
    if (list == null || list.isEmpty) return {};
    final map = <String, dynamic>{};
    for (final c in list) {
      final meta = c.data.metadata;
      map[c.data.type] = Map<String, dynamic>.from(meta);
    }
    return map;
  }

  void _handleThemeChange(String key, String value) {
    setState(() {
      switch (key) {
        case 'mode':
          _themeMode = value;
          break;
        case 'color':
          _themeColor = value;
          break;
        case 'leftCard':
          _leftCard = value.isEmpty ? null : value;
          break;
        case 'rightCard':
          _rightCard = value.isEmpty ? null : value;
          break;
        case 'logo':
          _logoUrl = value.isEmpty ? null : value;
          break;
      }
    });
    widget.onThemeChange?.call(key, value);
  }

  Future<void> _pickAndUploadLogo() async {
    if (_uploadingLogo) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    try {
      setState(() => _uploadingLogo = true);
      final logoUrl = await _uploadService.uploadFile(
        bytes: file.bytes!,
        filename: file.name,
        contentType: contentType,
      );
      _handleThemeChange('logo', logoUrl);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  /// 可选：Card 模式下左卡选项（与 TSX FIRST_CARDS.filter(ct => cardsMap[ct] || ct === 'BIO')）
  List<String> get _firstCardOptions {
    final map = _cardsMap;
    return _firstCards
        .where((ct) => map.containsKey(ct) || ct == 'BIO')
        .toList();
  }

  /// 可选：Card 模式下右卡选项（与 TSX SECOND_CARDS.filter(ct => cardsMap[ct])）
  List<String> get _secondCardOptions {
    final map = _cardsMap;
    return _secondCards.where((ct) => map.containsKey(ct)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 与 ExportCard.tsx 一致：固定尺寸 ShareCard 再缩放适配（TSX: 1200x630 scale 0.5 -> 600x315）
          Expanded(child: _buildPreviewCard()),
          // Edit Background Color and Mode（与 ExportCard.tsx 一致）
          if (widget.isEditable) ...[
            const SizedBox(height: 16),
            _buildControlsRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 600).clamp(
          0.0,
          constraints.maxHeight / 315,
        );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 600 * scale,
            height: 315 * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 1200,
                      height: 630,
                      child: ShareCard(
                        userInfo: widget.userData,
                        cardsMap: _cardsMap,
                        themeMode: _themeMode,
                        themeColor: _themeColor,
                        leftCardType: _leftCard,
                        rightCardType: _rightCard,
                        logoUrl: _logoUrl,
                        verifiedCount: widget.verifiedCount,
                      ),
                    ),
                  ),
                ),
                if (widget.isEditable && _themeMode == 'card')
                  _buildCardDropdownOverlays(scale),
                if (widget.isEditable) _buildLogoUploadHotspot(scale),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoUploadHotspot(double scale) {
    return Positioned(
      top: 20 * scale,
      right: 20 * scale,
      child: SizedBox(
        width: 60 * scale,
        height: 60 * scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickAndUploadLogo,
                child: const SizedBox.expand(),
              ),
            ),
            if (_uploadingLogo)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 18 * scale,
                    height: 18 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if ((_logoUrl ?? '').isNotEmpty && !_uploadingLogo)
              Positioned(
                top: -7 * scale,
                right: -7 * scale,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleThemeChange('logo', ''),
                  child: Container(
                    width: 18 * scale,
                    height: 18 * scale,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12 * scale,
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

  Widget _buildCardDropdownOverlays(double scale) {
    final firstOptions = _firstCardOptions;
    final secondOptions = _secondCardOptions;
    final leftValue = _leftCard ?? firstOptions.firstOrNull ?? 'BIO';
    final rightValue =
        _rightCard ?? secondOptions.firstOrNull ?? 'ACHIEVEMENT_NETWORK';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (firstOptions.isNotEmpty)
          Positioned(
            top: 106 * scale,
            left: 170 * scale,
            child: SizedBox(
              width: 112 * scale,
              height: 32 * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: _buildDropdownField(
                  value: firstOptions.contains(leftValue)
                      ? leftValue
                      : firstOptions.first,
                  options: firstOptions,
                  onChanged: (v) => _handleThemeChange('leftCard', v),
                ),
              ),
            ),
          ),
        if (secondOptions.isNotEmpty)
          Positioned(
            top: 106 * scale,
            left: 456 * scale,
            child: SizedBox(
              width: 112 * scale,
              height: 32 * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: _buildDropdownField(
                  value: secondOptions.contains(rightValue)
                      ? rightValue
                      : secondOptions.first,
                  options: secondOptions,
                  onChanged: (v) => _handleThemeChange('rightCard', v),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Default/Colorful 圆形按钮 + Classic/Custom 滑动切换
  Widget _buildControlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildColorButton(
              option: 'default',
              isSelected: _themeColor == 'default',
            ),
            const SizedBox(width: 12),
            _buildColorButton(
              option: 'colorful',
              isSelected: _themeColor == 'colorful',
            ),
          ],
        ),
        _buildClassicCustomToggle(),
      ],
    );
  }

  /// Default 为白底圆；Colorful 为渐变圆（与 TSX ColorfulIcon 一致）
  Widget _buildColorButton({required String option, required bool isSelected}) {
    final isColorful = option == 'colorful';
    return GestureDetector(
      onTap: widget.isEditable
          ? () {
              _handleThemeChange('color', option);
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF000000)
                  : const Color(0xFFC0C0C0),
              width: isSelected ? 1.63 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Center(
            child: isColorful
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFCDE3FF), Color(0xFFE0DCFF)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFBDD3EC),
                        width: 1,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Classic | Custom 滑动切换（与 ExportCard.tsx 一致）
  Widget _buildClassicCustomToggle() {
    const inset = 4.0;
    const sliderWidth = 62.0; // calc(50% - 8px)
    final isCustom = _themeMode == 'card';
    return GestureDetector(
      onTap: () => _handleThemeChange('mode', isCustom ? 'classic' : 'card'),
      child: Container(
        width: 140,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: isCustom ? (70 + inset) : inset,
              top: inset,
              bottom: inset,
              width: sliderWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
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
                Expanded(
                  child: Center(
                    child: Text(
                      'Classic',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: !isCustom
                            ? const Color(0xFF171717)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isCustom
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
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> options,
    required void Function(String) onChanged,
  }) {
    return SizedBox(
      width: 112,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD8D8D8)),
            ),
            fillColor: Colors.white,
            filled: true,
            isDense: true,
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 15),
          items: options
              .map(
                (ct) => DropdownMenuItem(
                  value: ct,
                  child: Text(
                    _cardLabels[ct] ?? ct,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: widget.isEditable
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
        ),
      ),
    );
  }
}
