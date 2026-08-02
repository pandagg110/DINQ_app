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
import 'profile_share_download.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../utils/asset_path.dart';

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
  bool _isDownloading = false;
  String? _downloadError;
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey _previewBoundaryKey = GlobalKey();
  late Map<String, String> _shareTheme;

  @override
  void initState() {
    super.initState();
    final theme = widget.userData.theme ?? ShareCardTheme();
    _shareTheme = {
      'mode': theme.mode,
      'color': theme.color,
      if (theme.logo != null && theme.logo!.isNotEmpty) 'logo': theme.logo!,
      if (theme.leftCard != null && theme.leftCard!.isNotEmpty)
        'leftCard': theme.leftCard!,
      if (theme.rightCard != null && theme.rightCard!.isNotEmpty)
        'rightCard': theme.rightCard!,
    };
  }

  /// Live profile for self (avatar/name edits), else the snapshot passed in.
  UserData _resolveUserData(UserStore userStore) {
    final domain = widget.userData.domain;
    final own = userStore.user?.userData;
    if (own != null && own.domain == domain) return own;
    final owner = userStore.cardOwner;
    if (owner != null && owner.domain == domain) return owner;
    return widget.userData;
  }

  String _shareTitle(UserData userData, bool isSelf) {
    return isSelf
        ? '${userData.name} here.'
        : 'Came across ${userData.name}\'s personal profile.';
  }

  bool _isSelf(UserStore userStore) {
    return userStore.user?.userData.domain == widget.userData.domain;
  }

  String _shareContent(UserData userData, bool isSelf) {
    final bio = userData.bio;
    return '${_shareTitle(userData, isSelf)}\n${widget.profileUrl}\n\n$bio';
  }

  String _shareContent2(UserData userData, bool isSelf) {
    final bio = userData.bio;
    return '${_shareTitle(userData, isSelf)}\n\n$bio\n';
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
  }

  Future<void> _openShareUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // 无法打开时静默忽略（如无浏览器、用户取消等）
    }
  }

  void _shareWhatsApp() {
    final userStore = context.read<UserStore>();
    final userData = _resolveUserData(userStore);
    final isSelf = _isSelf(userStore);
    final url =
        'https://wa.me/?text=${Uri.encodeComponent(_shareContent(userData, isSelf))}';
    _openShareUrl(url);
  }

  void _shareLinkedIn() {
    final userStore = context.read<UserStore>();
    final userData = _resolveUserData(userStore);
    final isSelf = _isSelf(userStore);
    final url =
        'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(widget.profileUrl)}&title=${Uri.encodeComponent(_shareContent(userData, isSelf))}';
    _openShareUrl(url);
  }

  void _shareTwitter() {
    final userStore = context.read<UserStore>();
    final userData = _resolveUserData(userStore);
    final isSelf = _isSelf(userStore);
    final url =
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareContent2(userData, isSelf))}&url=${Uri.encodeComponent(widget.profileUrl)}';
    _openShareUrl(url);
  }

  Future<void> _showMoreMenu() async {
    final box = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final buttonRect = box.localToGlobal(Offset.zero) & box.size;
    const menuHeight = 96.0;
    const gapAboveButton = 8.0;
    // 菜单在 More 按钮正上方、宽度与按钮一致、右对齐
    final position = RelativeRect.fromLTRB(
      buttonRect.left,
      buttonRect.top - menuHeight - gapAboveButton,
      overlay.size.width - buttonRect.right,
      overlay.size.height - buttonRect.top + gapAboveButton,
    );
    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      menuPadding: EdgeInsets.zero,
      color: Colors.white,
      constraints: const BoxConstraints.tightFor(width: 144),
      items: [
        PopupMenuItem<String>(
          value: 'download',
          enabled: !_isDownloading,
          child: Row(
            children: [
              _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.download_outlined,
                      size: 20,
                      color: Color(0xFF374151),
                    ),
              const SizedBox(width: 12),
              const Text(
                'Download',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy_link',
          child: Row(
            children: [
              Icon(Icons.link, size: 20, color: Color(0xFF374151)),
              SizedBox(width: 12),
              Text(
                'Copy link',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (result == 'download') {
      await _handleDownload();
    } else if (result == 'copy_link') {
      await _copyLink();
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null || !box.hasSize
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await shareProfileBoundary(
        boundaryKey: _previewBoundaryKey,
        profileName: widget.userData.name,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _downloadError = 'Unable to generate profile image.');
        TopToastUtil.showError(
          context: context,
          title: 'Download failed',
          description: 'Please try again after the preview finishes loading.',
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShareThemeChange(String key, String value) async {
    setState(() {
      if (value.isEmpty) {
        _shareTheme.remove(key);
      } else {
        _shareTheme[key] = value;
      }
    });

    final payloadTheme = {
      'mode': _shareTheme['mode'] ?? 'classic',
      'color': _shareTheme['color'] ?? 'default',
      if ((_shareTheme['logo'] ?? '').isNotEmpty) 'logo': _shareTheme['logo'],
      if ((_shareTheme['leftCard'] ?? '').isNotEmpty)
        'left_card': _shareTheme['leftCard'],
      if ((_shareTheme['rightCard'] ?? '').isNotEmpty)
        'right_card': _shareTheme['rightCard'],
    };

    try {
      await context.read<UserStore>().updateUserData({'theme': payloadTheme});
    } catch (_) {
      if (!mounted) return;
      TopToastUtil.showCustom(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Update failed',
        description: 'Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final userData = _resolveUserData(userStore);
    final isSelf = _isSelf(userStore);
    final mediaSize = MediaQuery.of(context).size;
    final maxHeight = mediaSize.height * 0.9;
    final cardScale = (mediaSize.width - 48) / 600;
    final cardPreviewHeight = (315 * cardScale) + (isSelf ? 64 : 0);
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAE8E3))),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Text(
                    'Share Profile',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF4B5563),
                    ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content: Card/QR toggle + preview
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
                  const SizedBox(height: 24),
                  // Preview area: ExportCard/ShareCard 布局同步；watch CardStore 使移动卡片时预览同步更新
                  RepaintBoundary(
                    key: _previewBoundaryKey,
                    child: SizedBox(
                      height: _viewModeCard ? cardPreviewHeight : 330,
                      child: _viewModeCard
                          ? Builder(
                              builder: (context) {
                                final cardStore = context.watch<CardStore>();
                                return ExportCardPreview(
                                  userData: userData,
                                  cards: cardStore.cards,
                                  height: cardPreviewHeight,
                                  isEditable: isSelf,
                                  theme: _shareTheme,
                                  onThemeChange: _handleShareThemeChange,
                                );
                              },
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: ExportQrCard(
                                  userInfo: userData,
                                  username: widget.username,
                                  profileUrl: widget.profileUrl,
                                  forExport: false,
                                ),
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
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SocialImageButton(
                          imagePath: 'profile/share-whatsapp.png',
                          backgroundColor: const Color(0xFF25D366),
                          onTap: _shareWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialImageButton(
                          imagePath: 'profile/share-linkedin.png',
                          backgroundColor: const Color(0xFF367CB6),
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
                      // More button（使用 showMenu 弹出菜单）
                      SizedBox(
                        key: _moreButtonKey,
                        width: 56,
                        height: 48,
                        child: _ActionButton(
                          label: 'More',
                          backgroundColor: Colors.white,
                          outline: true,
                          icon: Icons.more_horiz,
                          showLabel: false,
                          onTap: _showMoreMenu,
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
                      color: Colors.black.withValues(alpha: 0.06),
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
                    selected
                        ? const Color(0xFF171717)
                        : const Color(0xFF6B7280),
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
                  color: selected
                      ? const Color(0xFF171717)
                      : const Color(0xFF6B7280),
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
  });

  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;

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
            width: 20,
            height: 20,
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
    this.showLabel = true,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final IconData? icon;
  final bool outline;
  final bool showLabel;
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
              if (icon != null && showLabel) const SizedBox(width: 6),
              if (showLabel)
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
