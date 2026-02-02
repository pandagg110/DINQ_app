import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/card_models.dart';
import '../../models/user_models.dart';
import '../share_card/export_qr_card.dart';
import 'export_card_preview.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../utils/asset_path.dart';
import '../../utils/toast_util.dart';

/// 分享 Profile 的底部弹框，样式参考 [ProfileEditDialog]；内容参考 Web ShareModal。
/// 包含 Card/QR 切换、预览占位、分享按钮（WhatsApp/LinkedIn/Twitter）、More（下载、复制链接）。
class ShareProfileDialog {
  /// 公开 Profile 页的基础 URL，用于生成 profileUrl
  static const String profileBaseUrl = 'https://mydinq.com';

  static Future<void> show({
    required BuildContext context,
    required String username,
    required UserData userData,
    List<CardItem>? cards,
  }) {
    final profileUrl = '$profileBaseUrl/$username';
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _ShareProfileBottomSheet(
          username: username,
          userData: userData,
          profileUrl: profileUrl,
          cards: cards,
        );
      },
    );
  }
}

class _ShareProfileBottomSheet extends StatefulWidget {
  const _ShareProfileBottomSheet({
    required this.username,
    required this.userData,
    required this.profileUrl,
    this.cards,
  });

  final String username;
  final UserData userData;
  final String profileUrl;
  final List<CardItem>? cards;

  @override
  State<_ShareProfileBottomSheet> createState() =>
      _ShareProfileBottomSheetState();
}

class _ShareProfileBottomSheetState extends State<_ShareProfileBottomSheet> {
  bool _viewModeCard = true; // true = Card, false = QR
  bool _showMoreMenu = false;
  bool _isDownloading = false;
  String? _downloadError;

  String get _shareTitle {
    final userStore = context.read<UserStore>();
    final isSelf = userStore.user?.userData.domain == widget.userData.domain;
    return isSelf
        ? '${widget.userData.name} here.'
        : 'Came across ${widget.userData.name}\'s personal profile.';
  }

  String get _shareContent {
    final bio = widget.userData.bio;
    return '$_shareTitle\n${widget.profileUrl}\n\n$bio';
  }

  String get _shareContent2 {
    final bio = widget.userData.bio;
    return '$_shareTitle\n\n$bio\n';
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.profileUrl));
    if (mounted) {
      TopToastUtil.showSuccess(
        context: context,
        title: 'Link copied to clipboard',
        description: '',
      );
    }
    setState(() => _showMoreMenu = false);
  }

  Future<void> _openShareUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareWhatsApp() {
    final url =
        'https://wa.me/?text=${Uri.encodeComponent(_shareContent)}';
    _openShareUrl(url);
  }

  void _shareLinkedIn() {
    final url =
        'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(widget.profileUrl)}&title=${Uri.encodeComponent(_shareContent)}';
    _openShareUrl(url);
  }

  void _shareTwitter() {
    final url =
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareContent2)}&url=${Uri.encodeComponent(widget.profileUrl)}';
    _openShareUrl(url);
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });
    // 占位：实际下载需要 og-image 接口或本地生成图片，此处仅关闭 More 并提示
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _showMoreMenu = false;
      });
      TopToastUtil.showCustom(
        context: context,
        icon: Icons.info_outline,
        iconColor: Colors.blue,
        title: 'Download',
        description: 'Image download will be available when og-image is ready.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Share Profile + close
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Profile',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 24, color: Color(0xFF6B7280)),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
          // Content: Card/QR toggle + preview
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Segment: Card | QR Code
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            label: 'Card',
                            iconPath: 'images/card/sharecard.svg',
                            selected: _viewModeCard,
                            onTap: () => setState(() => _viewModeCard = true),
                          ),
                        ),
                        Expanded(
                          child: _SegmentButton(
                            label: 'QR Code',
                            iconPath: 'images/card/qrcode.svg',
                            selected: !_viewModeCard,
                            onTap: () => setState(() => _viewModeCard = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Preview area: ExportCard/ShareCard 布局同步；watch CardStore 使移动卡片时预览同步更新
                  SizedBox(
                    height: 240,
                    child: _viewModeCard
                        ? Builder(
                            builder: (context) {
                              final cardStore = context.watch<CardStore>();
                              return ExportCardPreview(
                                userData: widget.userData,
                                cards: cardStore.cards,
                                height: 240,
                              );
                            },
                          )
                        : Container(
                            
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: ExportQrCard(
                                userInfo: widget.userData,
                                username: widget.username,
                                profileUrl: widget.profileUrl,
                                forExport: false,
                                size: 160,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Footer: action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_downloadError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _downloadError!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
                Container(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SocialImageButton(
                          imageWidth: 24,
                          imageHeight: 24,
                          imagePath: 'profile/share-whatsapp.png',
                          backgroundColor: const Color(0xFF25D366),
                          onTap: _shareWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialImageButton(
                          imagePath: 'profile/share-linkedin.png',
                          backgroundColor: const Color(0xFF007EBB),
                          onTap: _shareLinkedIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialImageButton(
                          imagePath: 'profile/share-x.png',
                          backgroundColor: const Color(0xFF000000),
                          onTap: _shareTwitter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // More button
                      SizedBox(
                        width: 96,
                        height: 48,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _ActionButton(
                              label: 'More',
                              backgroundColor: Colors.white,
                              outline: true,
                              icon: Icons.more_horiz,
                              onTap: () =>
                                  setState(() => _showMoreMenu = !_showMoreMenu),
                            ),
                            if (_showMoreMenu) _buildMoreMenu(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Positioned(
      right: 0,
      bottom: 56,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _isDownloading ? null : _handleDownload,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.download_outlined,
                              size: 20,
                              color: Color(0xFF374151),
                            ),
                      const SizedBox(width: 12),
                      Text(
                        'Download',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _copyLink,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        size: 20,
                        color: Color(0xFF374151),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Copy link',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    this.iconPath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? iconPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPath != null) ...[
                SvgPicture.asset(
                  assetPath(iconPath!),
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    selected ? const Color(0xFF171717) : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? const Color(0xFF171717) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 仅图标的社交分享按钮（WhatsApp / LinkedIn / X），无 label；等分宽度，高度 48，背景色由调用方指定。
class _SocialImageButton extends StatelessWidget {
  const _SocialImageButton({
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
    this.imageWidth = 32,
    this.imageHeight = 32,
  });

  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;
  /// 图片宽度，默认 28
  final double imageWidth;
  /// 图片高度，默认 28
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Image.asset(
            assetPath(imagePath),
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    this.icon,
    this.outline = false,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final IconData? icon;
  final bool outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outline ? Colors.white : backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: outline
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8D8D8)),
                )
              : null,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: outline ? const Color(0xFF374151) : Colors.white,
                ),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: outline ? const Color(0xFF374151) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
