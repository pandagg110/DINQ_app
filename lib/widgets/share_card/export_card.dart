/**
 * ExportCard - Flutter 迁移自 Web example/src/app/[username]/components/shareCard/ExportCard.tsx
 * 使用 ShareCard 渲染卡片，支持编辑模式（Logo 上传、leftCard/rightCard 下拉、主题切换）
 */

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/card_models.dart';
import '../../models/user_models.dart';
import '../../services/upload_service.dart';
import 'share_card.dart';

const _firstCards = ['LINKEDIN', 'GITHUB', 'SCHOLAR', 'BIO'];
const _secondCards = ['ACHIEVEMENT_NETWORK', 'CAREER_TRAJECTORY'];

const _cardLabels = {
  'LINKEDIN': 'Linkedin',
  'GITHUB': 'Github',
  'SCHOLAR': 'Scholar',
  'BIO': 'Bio',
  'ACHIEVEMENT_NETWORK': 'Network',
  'CAREER_TRAJECTORY': 'Career',
};

/// ExportCard 组件，对应 Web ExportCard.tsx
/// 使用 ShareCard 渲染，支持 isEditable 时的 Logo/leftCard/rightCard/color/mode 编辑
class ExportCard extends StatefulWidget {
  const ExportCard({
    super.key,
    required this.userInfo,
    this.cards,
    this.verifiedCount = 0,
    this.isEditable = false,
    this.onThemeChange,
    this.height = 315,
    this.scale = 1.0,
  });

  final UserData userInfo;
  final List<CardItem>? cards;
  final int verifiedCount;
  /// 是否显示编辑 UI（对应 pathUsername === "admin"）
  final bool isEditable;
  /// 主题变更回调，用于持久化到 updateUserData
  final void Function(Map<String, dynamic> theme)? onThemeChange;
  final double height;
  final double scale;

  @override
  State<ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends State<ExportCard> {
  bool _uploading = false;
  final _uploadService = UploadService();

  ShareCardTheme get _theme => widget.userInfo.theme ?? ShareCardTheme();

  Map<String, dynamic> get _cardsMap {
    final list = widget.cards;
    if (list == null || list.isEmpty) return {};
    final map = <String, dynamic>{};
    for (final c in list) {
      map[c.data.type] = Map<String, dynamic>.from(c.data.metadata);
    }
    return map;
  }

  void _handleThemeChange(String key, String value) {
    final updated = _theme.copyWith(
      mode: key == 'mode' ? value : null,
      color: key == 'color' ? value : null,
      logo: key == 'logo' ? value : null,
      leftCard: key == 'leftCard' ? value : null,
      rightCard: key == 'rightCard' ? value : null,
    );
    widget.onThemeChange?.call(updated.toJson());
  }

  Future<void> _handleLogoUpload({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      setState(() => _uploading = true);
      final logoUrl = await _uploadService.uploadFile(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      _handleThemeChange('logo', logoUrl);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final scale = widget.scale;
    final displayHeight = widget.height * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: displayHeight,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()..scale(scale),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ShareCard 主体 (600x315 可视，对应 1200x630 scale 0.5)
                  Center(
                    child: SizedBox(
                      width: 600,
                      height: 315,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ShareCard(
                          userInfo: widget.userInfo,
                          cardsMap: _cardsMap,
                          themeMode: theme.mode,
                          themeColor: theme.color,
                          leftCardType: theme.leftCard,
                          rightCardType: theme.rightCard,
                          logoUrl: theme.logo,
                          verifiedCount: widget.verifiedCount,
                        ),
                      ),
                    ),
                  ),
                  // 编辑 UI（仅 isEditable）
                  if (widget.isEditable) _buildEditOverlays(),
                ],
              ),
            ),
          ),
        ),
        if (widget.isEditable) ...[
          const SizedBox(height: 16),
          _buildEditControls(theme),
        ],
      ],
    );
  }

  Widget _buildEditOverlays() {
    final theme = _theme;
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Logo 编辑区域 - 对应 TSX top-[20px] right-[320px]，600x315 下约 left: 219
          Positioned(
            top: 10,
            left: 219,
            child: _LogoEditOverlay(
              logoUrl: theme.logo,
              uploading: _uploading,
              onFileSelected: _handleLogoUpload,
              onRemove: () => _handleThemeChange('logo', ''),
            ),
          ),
          // leftCard 下拉 - 对应 TSX top-[106px] left-[505px]，600x315 下约 left: 252
          if (theme.mode == 'card') ...[
            Positioned(
              top: 53,
              left: 252,
              child: _CardTypeDropdown(
                value: theme.leftCard ?? '',
                options: _firstCards
                    .where((ct) => _cardsMap.containsKey(ct) || ct == 'BIO')
                    .toList(),
                labels: _cardLabels,
                onChanged: (v) => _handleThemeChange('leftCard', v),
              ),
            ),
            Positioned(
              top: 53,
              right: 120,
              child: _CardTypeDropdown(
                value: theme.rightCard ?? '',
                options: _secondCards
                    .where((ct) => _cardsMap.containsKey(ct))
                    .toList(),
                labels: _cardLabels,
                onChanged: (v) => _handleThemeChange('rightCard', v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditControls(ShareCardTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Default / Colorful 圆形按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ColorButton(
                option: 'default',
                isSelected: theme.color == 'default',
                onTap: () => _handleThemeChange('color', 'default'),
              ),
              const SizedBox(width: 12),
              _ColorButton(
                option: 'colorful',
                isSelected: theme.color == 'colorful',
                onTap: () => _handleThemeChange('color', 'colorful'),
              ),
            ],
          ),
          // Classic / Custom 滑动切换
          _ClassicCustomToggle(
            isCustom: theme.mode == 'card',
            onTap: () => _handleThemeChange(
              'mode',
              theme.mode == 'card' ? 'classic' : 'card',
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoEditOverlay extends StatelessWidget {
  const _LogoEditOverlay({
    this.logoUrl,
    required this.uploading,
    required this.onFileSelected,
    required this.onRemove,
  });

  final String? logoUrl;
  final bool uploading;
  final void Function({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) onFileSelected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading
          ? null
          : () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
              );
              if (result != null &&
                  result.files.single.bytes != null &&
                  result.files.single.name.isNotEmpty) {
                final file = result.files.single;
                final ext = file.extension ?? 'jpg';
                final contentType = ext == 'png'
                    ? 'image/png'
                    : ext == 'jpg' || ext == 'jpeg'
                        ? 'image/jpeg'
                        : ext == 'gif'
                            ? 'image/gif'
                            : ext == 'webp'
                                ? 'image/webp'
                                : 'image/jpeg';
                onFileSelected(
                  bytes: file.bytes!,
                  filename: file.name,
                  contentType: contentType,
                );
              }
            },
      child: Container(
        width: 61,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD8D8D8), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (logoUrl != null && logoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(logoUrl!, fit: BoxFit.cover, width: 61, height: 62),
              ),
            if (logoUrl == null || logoUrl!.isEmpty)
              Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[600], size: 24),
            if (uploading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            if (logoUrl != null && logoUrl!.isNotEmpty && !uploading)
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

class _CardTypeDropdown extends StatelessWidget {
  const _CardTypeDropdown({
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final Map<String, String> labels;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value.isEmpty || !options.contains(value)) && options.isNotEmpty
              ? options.first
              : (options.contains(value) ? value : null),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(fontSize: 12, color: Color(0xFF171717)),
          items: options
              .map((ct) => DropdownMenuItem(
                    value: ct,
                    child: Text(labels[ct] ?? ct),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isColorful = option == 'colorful';
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? const Color(0xFF000000) : const Color(0xFFC0C0C0),
              width: isSelected ? 1.63 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: isColorful
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFCDE3FF), Color(0xFFE0DCFF)],
                    ),
                    border: Border.all(color: const Color(0xFFBDD3EC)),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _ClassicCustomToggle extends StatelessWidget {
  const _ClassicCustomToggle({
    required this.isCustom,
    required this.onTap,
  });

  final bool isCustom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const inset = 4.0;
    const sliderWidth = 66.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
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
                      color: Colors.black.withOpacity(0.08),
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
                        color: !isCustom ? const Color(0xFF171717) : const Color(0xFF9CA3AF),
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
                        color: isCustom ? const Color(0xFF171717) : const Color(0xFF9CA3AF),
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
}
