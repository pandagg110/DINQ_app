import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/organization_share_models.dart';
import '../../utils/asset_path.dart';
import '../share_card/export_organization_card_preview.dart';
import '../share_card/export_organization_qr_card.dart';

/// 组织分享底部弹框，对齐 Web ShareModal organization 分支。
/// 独立于 [ShareProfileDialog]，不影响 My DINQ 个人分享逻辑。
class ShareOrganizationDialog {
  static const String profileBaseUrl = 'https://dinq.me';

  static Future<void> show({
    required BuildContext context,
    required OrganizationShareTarget organization,
    String? profileUrl,
  }) {
    final resolvedProfileUrl =
        profileUrl ?? '$profileBaseUrl/${organization.slug}';
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _ShareOrganizationBottomSheet(
          organization: organization,
          profileUrl: resolvedProfileUrl,
        );
      },
    );
  }
}

class _ShareOrganizationBottomSheet extends StatefulWidget {
  const _ShareOrganizationBottomSheet({
    required this.organization,
    required this.profileUrl,
  });

  final OrganizationShareTarget organization;
  final String profileUrl;

  @override
  State<_ShareOrganizationBottomSheet> createState() =>
      _ShareOrganizationBottomSheetState();
}

class _ShareOrganizationBottomSheetState
    extends State<_ShareOrganizationBottomSheet> {
  bool _viewModeCard = true;
  bool _isDownloading = false;
  String? _downloadError;
  final GlobalKey _moreButtonKey = GlobalKey();

  String get _shareTitle => '${widget.organization.name} on DINQ';

  String get _shareDescription => widget.organization.description ?? '';

  String get _shareContent =>
      '$_shareTitle\n${widget.profileUrl}\n\n$_shareDescription';

  String get _shareContent2 => '$_shareTitle\n\n$_shareDescription\n';

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
    } catch (_) {}
  }

  void _shareWhatsApp() {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(_shareContent)}';
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

  Future<void> _showMoreMenu() async {
    final box = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final buttonRect = box.localToGlobal(Offset.zero) & box.size;
    const menuHeight = 96.0;
    const gapAboveButton = 8.0;
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
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isDownloading = false);
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
    final mediaSize = MediaQuery.of(context).size;
    final maxHeight = mediaSize.height * 0.9;
    final cardScale = (mediaSize.width - 48) / 600;
    final cardPreviewHeight = 315 * cardScale;

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
                    'Share Organization',
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  SizedBox(
                    height: _viewModeCard ? cardPreviewHeight : 330,
                    child: _viewModeCard
                        ? ExportOrganizationCardPreview(
                            org: widget.organization,
                            height: cardPreviewHeight,
                          )
                        : Container(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: ExportOrganizationQrCard(
                                org: widget.organization,
                                profileUrl: widget.profileUrl,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
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
