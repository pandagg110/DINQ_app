import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/asset_icon.dart';

class BilibiliLayouts {
  static const _padding = EdgeInsets.all(20);
  static const _textPrimary = Color(0xFF171717);
  static const _textMuted = Color(0xFF6B7280);
  static const _bioText = Color(0xFF4B5563);

  static Widget build2x2Layout({required int followers}) {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Align(alignment: Alignment.topLeft, child: _BilibiliIcon()),
          _MetricDisplay(label: 'Followers', value: followers),
        ],
      ),
    );
  }

  static Widget build2x4Layout({
    required int followers,
    required int archiveView,
    Map<String, dynamic>? firstWork,
  }) {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Align(alignment: Alignment.topLeft, child: _BilibiliIcon()),
          ),
          const Spacer(),
          AspectRatio(
            aspectRatio: 1,
            child: _VideoCover(
              work: firstWork,
              placeholderText: 'No video',
              showPlayBadge: true,
              titleFontSize: 12,
              titlePadding: 8,
            ),
          ),
          const SizedBox(height: 12),
          _MetricDisplay(label: 'Followers', value: followers),
          const SizedBox(height: 16),
          _MetricDisplay(label: 'Views', value: archiveView),
        ],
      ),
    );
  }

  static Widget build4x2Layout({
    required int followers,
    required int archiveView,
    required int likes,
  }) {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Align(alignment: Alignment.topLeft, child: _BilibiliIcon()),
          Row(
            children: [
              Expanded(
                child: _MetricDisplay(label: 'Followers', value: followers),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricDisplay(label: 'Views', value: archiveView),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricDisplay(label: 'Likes', value: likes),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget build4x4Layout({
    required int followers,
    required int archiveView,
    required String bio,
    Map<String, dynamic>? firstWork,
  }) {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Align(alignment: Alignment.topLeft, child: _BilibiliIcon()),
          ),
          Row(
            children: [
              Expanded(
                child: _MetricDisplay(label: 'Followers', value: followers),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _MetricDisplay(label: 'Views', value: archiveView),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _VideoCover(
              work: firstWork,
              placeholderText: 'No video configured',
              showPlayBadge: false,
              titleFontSize: 14,
              titlePadding: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bio.isNotEmpty ? bio : 'No description available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w400,
                color: _bioText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String formatCount(int value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _BilibiliIcon extends StatelessWidget {
  const _BilibiliIcon({this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AssetIcon(asset: 'icons/social-icons/Bilibili.svg', size: size);
  }
}

class _MetricDisplay extends StatelessWidget {
  const _MetricDisplay({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 16 / 14,
            fontWeight: FontWeight.w400,
            color: BilibiliLayouts._textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          BilibiliLayouts.formatCount(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w500,
            color: BilibiliLayouts._textPrimary,
          ),
        ),
      ],
    );
  }
}

class _VideoCover extends StatelessWidget {
  const _VideoCover({
    required this.work,
    required this.placeholderText,
    required this.showPlayBadge,
    required this.titleFontSize,
    required this.titlePadding,
  });

  final Map<String, dynamic>? work;
  final String placeholderText;
  final bool showPlayBadge;
  final double titleFontSize;
  final double titlePadding;

  @override
  Widget build(BuildContext context) {
    final work = this.work;
    if (work == null) {
      return _VideoPlaceholder(text: placeholderText);
    }

    final cover = work['cover']?.toString() ?? '';
    final title = work['title']?.toString() ?? '';
    final bvid = work['bvid']?.toString() ?? '';
    final play = (work['play'] as num?)?.toInt() ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: bvid.isEmpty ? null : () => _openBilibiliVideo(bvid),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _VideoPlaceholder(text: placeholderText),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(titlePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (showPlayBadge)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '▶ ${BilibiliLayouts.formatCount(play)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w400,
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

  Future<void> _openBilibiliVideo(String bvid) async {
    final uri = Uri.parse('https://www.bilibili.com/video/$bvid/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BilibiliIcon(size: 48),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w400,
              color: BilibiliLayouts._textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
