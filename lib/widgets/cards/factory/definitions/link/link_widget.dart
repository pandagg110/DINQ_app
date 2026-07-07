import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'link_layouts.dart';

class LinkWidget extends StatefulWidget {
  const LinkWidget({
    super.key,
    required this.card,
    required this.sizez
    required this.editable,
    required this.isSelected,
    required this.onUpdate,
  });

  final dynamic card;
  final String size;
  final bool editable;
  final bool isSelected;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  @override
  State<LinkWidget> createState() => _LinkWidgetState();
}

class _LinkWidgetState extends State<LinkWidget> {
  bool _showDetails = false;

  void _toggleDetails() {
    setState(() => _showDetails = !_showDetails);
  }

  void _hideDetails() {
    if (_showDetails) {
      setState(() => _showDetails = false);
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _handlePreviewImageChange(String imageUrl) {
    final metadata = Map<String, dynamic>.from(widget.card.data.metadata);
    if (imageUrl.isEmpty) {
      metadata['og_image'] = '';
      metadata['screenshot_url'] = '';
    } else {
      metadata['og_image'] = imageUrl;
    }
    widget.onUpdate(metadata);
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.card.data.metadata;
    final url = (metadata['url'] as String?) ?? '';
    final title = (metadata['title'] as String?) ?? '';
    final favicon = (metadata['favicon'] as String?) ?? '';
    final rawOgImage = (metadata['og_image'] as String?) ?? '';
    final screenshotUrl = (metadata['screenshot_url'] as String?) ?? '';

    // Compute effective preview image: og_image -> screenshot_url
    final ogImage = rawOgImage.isNotEmpty ? rawOgImage : screenshotUrl;

    late final Widget child;
    switch (widget.size) {
      case '2x2':
        child = LinkLayouts.build2x2Layout(
          title: title,
          url: url,
          favicon: favicon,
        );
        break;
      case '2x4':
        child = LinkLayouts.build2x4Layout(
          title: title,
          url: url,
          favicon: favicon,
          ogImage: ogImage,
          editable: widget.editable && widget.isSelected,
          onImageChange: _handlePreviewImageChange,
        );
        break;
      case '4x2':
        child = LinkLayouts.build4x2Layout(
          title: title,
          url: url,
          favicon: favicon,
          ogImage: ogImage,
          editable: widget.editable && widget.isSelected,
          onImageChange: _handlePreviewImageChange,
        );
        break;
      case '4x4':
        child = LinkLayouts.build4x4Layout(
          title: title,
          url: url,
          favicon: favicon,
          ogImage: ogImage,
          editable: widget.editable && widget.isSelected,
          onImageChange: _handlePreviewImageChange,
        );
        break;
      default:
        child = const Center(child: Text('Unknown size'));
    }

    final tapTarget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.editable ? null : _toggleDetails,
      child: child,
    );

    final hasPortal = context.findAncestorWidgetOfExactType<Portal>() != null;
    if (!hasPortal) {
      return tapTarget;
    }

    return PortalTarget(
      visible: _showDetails,
      portalFollower: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideDetails,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, -12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: _LinkDetailCard(
                title: title,
                url: url,
                favicon: favicon,
                ogImage: ogImage,
                onOpen: () => _openUrl(url),
              ),
            ),
          ),
        ),
      ),
      child: tapTarget,
    );
  }
}

class _LinkDetailCard extends StatelessWidget {
  const _LinkDetailCard({
    required this.title,
    required this.url,
    required this.favicon,
    required this.ogImage,
    required this.onOpen,
  });

  final String title;
  final String url;
  final String favicon;
  final String ogImage;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isNotEmpty ? title : LinkLayouts.cleanUrl(url);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ogImage.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.9,
                  child: Image.network(
                    ogImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Icon(Icons.image, color: Color(0xFF9CA3AF)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinkLayouts.buildLinkIcon(
                  favicon: favicon,
                  url: url,
                  dimension: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (url.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          LinkLayouts.cleanUrl(url),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: url.isEmpty ? null : onOpen,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open link'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E5E5),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
