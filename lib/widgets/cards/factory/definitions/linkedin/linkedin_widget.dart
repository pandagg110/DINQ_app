import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/asset_icon.dart';
import 'linkedin_layouts.dart';
import 'linkedin_utils.dart';

class LinkedInWidget extends StatefulWidget {
  const LinkedInWidget({super.key, required this.card, required this.size});

  final dynamic card;
  final String size;

  @override
  State<LinkedInWidget> createState() => _LinkedInWidgetState();
}

class _LinkedInWidgetState extends State<LinkedInWidget> {
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

  @override
  Widget build(BuildContext context) {
    final careerJourney =
        (widget.card.data.metadata['careerJourney'] as List<dynamic>?) ?? [];
    final items = careerJourney.cast<Map<String, dynamic>>();
    final url = widget.card.data.metadata['url']?.toString() ?? '';

    late final Widget child;
    switch (widget.size) {
      case '2x2':
        child = LinkedInLayouts.build2x2Layout(
          careerJourney: items,
          onIconTap: _toggleDetails,
        );
        break;
      case '2x4':
        child = LinkedInLayouts.build2x4Layout(
          careerJourney: items,
          onIconTap: _toggleDetails,
        );
        break;
      case '4x2':
        child = LinkedInLayouts.build4x2Layout(
          careerJourney: items,
          onIconTap: _toggleDetails,
        );
        break;
      case '4x4':
        child = LinkedInLayouts.build4x4Layout(
          careerJourney: items,
          onIconTap: _toggleDetails,
        );
        break;
      default:
        child = LinkedInLayouts.build4x4Layout(
          careerJourney: items,
          onIconTap: _toggleDetails,
        );
    }

    final hasPortal = context.findAncestorWidgetOfExactType<Portal>() != null;
    if (!hasPortal) {
      return child;
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
              child: _LinkedInDetailCard(
                careerJourney: items,
                url: url,
                onOpen: () => _openUrl(url),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class _LinkedInDetailCard extends StatelessWidget {
  const _LinkedInDetailCard({
    required this.careerJourney,
    required this.url,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> careerJourney;
  final String url;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final visibleItems = careerJourney.reversed.take(5).toList();

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.all(14),
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
            const Row(
              children: [
                AssetIcon(asset: 'icons/logo/LinkedIn.png', size: 36),
                SizedBox(width: 10),
                Text(
                  'LinkedIn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (visibleItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No career data',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: visibleItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    final name = item['name']?.toString() ?? '';
                    final position = item['position']?.toString() ?? '';
                    final duration = item['duration']?.toString() ?? '';
                    final logo = item['logo']?.toString() ?? '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: logo.isNotEmpty
                                ? Image.network(
                                    logo,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => Image.asset(
                                          'assets/images/defaultCompany.png',
                                          fit: BoxFit.cover,
                                        ),
                                  )
                                : Image.asset(
                                    'assets/images/defaultCompany.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (position.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  position,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (duration.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  formatDuration(duration),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: url.isEmpty ? null : onOpen,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open LinkedIn'),
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
