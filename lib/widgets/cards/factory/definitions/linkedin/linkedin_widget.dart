import 'package:flutter/material.dart';
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
  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showDetailsBottomSheet() {
    final careerJourney =
        (widget.card.data.metadata['careerJourney'] as List<dynamic>?) ?? [];
    final items = careerJourney.cast<Map<String, dynamic>>();
    final url = widget.card.data.metadata['url']?.toString() ?? '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LinkedInDetailBottomSheet(
        careerJourney: items,
        url: url,
        onOpen: () => _openUrl(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final careerJourney =
        (widget.card.data.metadata['careerJourney'] as List<dynamic>?) ?? [];
    final items = careerJourney.cast<Map<String, dynamic>>();

    switch (widget.size) {
      case '2x2':
        return LinkedInLayouts.build2x2Layout(
          careerJourney: items,
          onIconTap: _showDetailsBottomSheet,
        );
      case '2x4':
        return LinkedInLayouts.build2x4Layout(
          careerJourney: items,
          onIconTap: _showDetailsBottomSheet,
        );
      case '4x2':
        return LinkedInLayouts.build4x2Layout(
          careerJourney: items,
          onIconTap: _showDetailsBottomSheet,
        );
      case '4x4':
        return LinkedInLayouts.build4x4Layout(
          careerJourney: items,
          onIconTap: _showDetailsBottomSheet,
        );
      default:
        return LinkedInLayouts.build4x4Layout(
          careerJourney: items,
          onIconTap: _showDetailsBottomSheet,
        );
    }
  }
}

class _LinkedInDetailBottomSheet extends StatelessWidget {
  const _LinkedInDetailBottomSheet({
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
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
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
                      const SizedBox(height: 16),
                      if (visibleItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No career data',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        ...List.generate(visibleItems.length, (index) {
                          if (index > 0) const SizedBox(height: 12);
                          return _CareerItem(item: visibleItems[index]);
                        }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareerItem extends StatelessWidget {
  const _CareerItem({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
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
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/defaultCompany.png',
                        fit: BoxFit.cover,
                      );
                    },
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
  }
}
