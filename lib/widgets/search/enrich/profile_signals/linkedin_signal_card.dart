import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/asset_icon.dart';
import 'linkedin_career_chart.dart';
import 'profile_signals_analysis_button.dart';

class LinkedInProfileSignalCard extends StatefulWidget {
  const LinkedInProfileSignalCard({
    super.key,
    required this.metadata,
    this.url,
  });

  final Map<String, dynamic> metadata;
  final String? url;

  @override
  State<LinkedInProfileSignalCard> createState() =>
      _LinkedInProfileSignalCardState();
}

class _LinkedInProfileSignalCardState extends State<LinkedInProfileSignalCard> {
  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showDetailsBottomSheet() {
    final careerJourney =
        (widget.metadata['careerJourney'] as List<dynamic>?) ?? [];
    final items = careerJourney.cast<Map<String, dynamic>>();
    final url = widget.url ?? widget.metadata['url']?.toString() ?? '';

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
        (widget.metadata['careerJourney'] as List<dynamic>?) ?? [];
    final items = careerJourney.cast<Map<String, dynamic>>();
    final analysisUrl = widget.url ?? widget.metadata['url']?.toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showDetailsBottomSheet,
            child: const AssetIcon(asset: 'icons/logo/LinkedIn.png', size: 40),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: LinkedInCareerChart(
              careerJourney: items,
              onNodeTap: _showDetailsBottomSheet,
            ),
          ),
          if (analysisUrl != null && analysisUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ProfileSignalAnalysisButton(
              platform: 'linkedin',
              url: analysisUrl,
            ),
          ],
        ],
      ),
    );
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
                  formatProfileSignalDuration(duration),
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
