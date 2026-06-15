import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/search_service.dart';
import 'citation_enrich_row.dart';
import 'citation_theme.dart';

/// 与 TSX `CitationResults.tsx` / `CitationResultsView` 对齐。
class CitationResultsView extends StatelessWidget {
  const CitationResultsView({
    super.key,
    required this.data,
    this.onEnrich,
  });

  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic> row)? onEnrich;

  @override
  Widget build(BuildContext context) {
    final queryType = data['query_type']?.toString() ?? 'paper';
    final isPerson = queryType == 'person';
    final citers = _citers(data);
    final totalCitingWorks = _readNum(data['total_citing_works']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPerson) CitationHeaderCard(data: data, onEnrich: onEnrich),
        if (citers.isNotEmpty)
          _CitersSection(
            citers: citers,
            totalCitingWorks: totalCitingWorks,
            onEnrich: onEnrich,
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  'No citing authors found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                SizedBox(height: 4),
                Text(
                  'Try checking the spelling or using the full name / paper title.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        if (isPerson && (data['name']?.toString().isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          CitationMorePapersSection(scholarName: data['name'].toString()),
        ],
      ],
    );
  }

  static List<Map<String, dynamic>> _citers(Map<String, dynamic> data) {
    final raw = data['citers'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CitationHeaderCard extends StatelessWidget {
  const CitationHeaderCard({
    super.key,
    required this.data,
    this.onEnrich,
  });

  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic> row)? onEnrich;

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString();
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    final interests = _stringList(data['interests']);
    final topPaper = data['top_paper'] is Map
        ? Map<String, dynamic>.from(data['top_paper'] as Map)
        : null;

    VoidCallback? onTap;
    if (onEnrich != null) {
      onTap = () => onEnrich!(
            citationCiterToRow(
              name: name,
              affiliation: data['affiliation']?.toString(),
              scholarId: data['scholar_id']?.toString(),
              interests: interests,
            ),
          );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CitationTheme.cardBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: onTap != null ? const Color(0xFFF9FAFB) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: CitationTheme.headerGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CitationAvatar(
                            url: data['avatar_url']?.toString(),
                            size: 60,
                            ring: true,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                if (data['affiliation'] != null &&
                                    data['affiliation'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          CitationTheme.iconBuilding,
                                          width: 14,
                                          height: 14,
                                          colorFilter: const ColorFilter.mode(
                                            CitationTheme.iconNordic,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            data['affiliation'].toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4B5563),
                                            ),
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
                      if (_hasHeaderMetrics(data)) ...[
                        const SizedBox(height: 10),
                        _MetricsBar(
                          hIndex: data['h_index'],
                          citations: data['total_citations'],
                          citingWorks: data['total_citing_works'],
                          background: CitationTheme.metricsBgStrong,
                        ),
                      ],
                      if (interests.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (var i = 0; i < interests.length; i++)
                              _TopicTag(text: interests[i], index: i),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (topPaper != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: CitationTheme.borderLight)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOP CITED PAPER',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                          color: CitationTheme.paperAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ScholarPaperSummary(paper: topPaper, iconSize: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasHeaderMetrics(Map<String, dynamic> data) {
    return data['h_index'] != null ||
        data['total_citations'] != null ||
        (_readNum(data['total_citing_works']) > 0);
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _stringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}

class _CitersSection extends StatelessWidget {
  const _CitersSection({
    required this.citers,
    required this.totalCitingWorks,
    this.onEnrich,
  });

  final List<Map<String, dynamic>> citers;
  final num totalCitingWorks;
  final void Function(Map<String, dynamic> row)? onEnrich;

  @override
  Widget build(BuildContext context) {
    final summary = totalCitingWorks > 0
        ? '${_formatNumber(totalCitingWorks)} total citing works · showing top ${citers.length} authors'
        : '${citers.length} ${citers.length == 1 ? 'author' : 'authors'} cited this paper';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < citers.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          CitationCiterCard(
            citer: citers[i],
            rank: i + 1,
            onTap: onEnrich == null ? null : () => _handleTap(citers[i]),
          ),
        ],
      ],
    );
  }

  void _handleTap(Map<String, dynamic> citer) {
    final author = citer['author'] is Map
        ? Map<String, dynamic>.from(citer['author'] as Map)
        : <String, dynamic>{};
    final institutions = author['last_known_institutions'];
    final topics = author['topics'];
    onEnrich!(
      citationCiterToRow(
        name: author['display_name']?.toString() ?? '',
        affiliation: institutions is List && institutions.isNotEmpty
            ? institutions.first.toString()
            : author['affiliation_string']?.toString(),
        scholarId: author['author_id']?.toString(),
        interests: topics is List ? topics.map((e) => e.toString()).toList() : null,
      ),
    );
  }
}

class CitationCiterCard extends StatelessWidget {
  const CitationCiterCard({
    super.key,
    required this.citer,
    required this.rank,
    this.onTap,
  });

  final Map<String, dynamic> citer;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final author = citer['author'] is Map
        ? Map<String, dynamic>.from(citer['author'] as Map)
        : <String, dynamic>{};
    final papers = citer['citing_papers'] is List
        ? (citer['citing_papers'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final displayName = author['display_name']?.toString() ?? 'Author';
    final orcid = author['orcid']?.toString();
    final orcidId = orcid?.replaceFirst('https://orcid.org/', '');
    final avatarUrl = author['avatar_url']?.toString() ??
        ((orcidId != null && orcidId.isNotEmpty)
            ? 'https://pub.orcid.org/v3.0/$orcidId/person/photo'
            : null);
    final institutions = author['last_known_institutions'];
    final affiliation = author['affiliation_string']?.toString() ??
        (institutions is List && institutions.isNotEmpty
            ? institutions.join(', ')
            : '');
    final topics = author['topics'] is List
        ? (author['topics'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CitationTheme.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: onTap != null ? const Color(0xFFF9FAFB) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CitationAvatar(url: avatarUrl, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (orcid != null && orcid.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _openUrl(orcid),
                                    child: Image.network(
                                      CitationTheme.orcidIcon,
                                      width: 14,
                                      height: 14,
                                      errorBuilder: (_, e, s) =>
                                          const SizedBox(width: 14, height: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (author['title'] != null &&
                                author['title'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      CitationTheme.iconAward,
                                      width: 12,
                                      height: 12,
                                      colorFilter: const ColorFilter.mode(
                                        CitationTheme.iconNordic,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        author['title'].toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: CitationTheme.titleAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (affiliation.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      CitationTheme.iconBuilding,
                                      width: 12,
                                      height: 12,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF9CA3AF),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        affiliation,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: CitationTheme.rankColor,
                        ),
                      ),
                    ],
                  ),
                  if (author['h_index'] != null ||
                      author['cited_by_count'] != null ||
                      author['works_count'] != null) ...[
                    const SizedBox(height: 8),
                    _MetricsBar(
                      hIndex: author['h_index'],
                      citations: author['cited_by_count'],
                      works: author['works_count'],
                      background: CitationTheme.metricsBg,
                    ),
                  ],
                  if (topics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < topics.length && i < 3; i++)
                          _TopicTag(text: topics[i], index: i, compact: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (papers.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: CitationTheme.borderLight)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < papers.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _CitingPaperItem(paper: papers[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CitingPaperItem extends StatelessWidget {
  const _CitingPaperItem({required this.paper});

  final Map<String, dynamic> paper;

  @override
  Widget build(BuildContext context) {
    final year = _readNum(paper['year']);
    final title = paper['title']?.toString() ?? '';
    final titleText = year > 0 ? '$title ($year)' : title;
    final doi = paper['doi']?.toString();
    final citedBy = _readNum(paper['cited_by_count']);

    final titleWidget = doi != null && doi.isNotEmpty
        ? InkWell(
            onTap: () => _openDoi(doi),
            child: Text(
              titleText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          )
        : Text(
            titleText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SvgPicture.asset(
            CitationTheme.iconFileText,
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(
              CitationTheme.paperAccent,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              if (citedBy > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        CitationTheme.iconQuote,
                        width: 12,
                        height: 12,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF9CA3AF),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'citations: ${_formatNumber(citedBy)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _openDoi(String doi) async {
    final href = doi.startsWith('http') ? doi : 'https://doi.org/$doi';
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ScholarPaperSummary extends StatelessWidget {
  const _ScholarPaperSummary({required this.paper, this.iconSize = 14});

  final Map<String, dynamic> paper;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final year = _readNum(paper['year']);
    final title = paper['title']?.toString() ?? '';
    final authors = paper['authors'] is List
        ? (paper['authors'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final citations = _readNum(paper['citations']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SvgPicture.asset(
            CitationTheme.iconFileText,
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(
              CitationTheme.paperAccent,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year > 0 ? '$title ($year)' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (paper['venue'] != null && paper['venue'].toString().isNotEmpty)
                    Flexible(
                      child: Text(
                        paper['venue'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                  if (citations > 0) ...[
                    if (paper['venue'] != null) const SizedBox(width: 12),
                    SvgPicture.asset(
                      CitationTheme.iconQuote,
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF6B7280),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'citations: ${_formatNumber(citations)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ],
              ),
              if (authors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _authorLine(authors),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _authorLine(List<String> authors) {
    if (authors.length <= 5) return authors.join(', ');
    return '${authors.take(5).join(', ')} +${authors.length - 5}';
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _MetricsBar extends StatelessWidget {
  const _MetricsBar({
    this.hIndex,
    this.citations,
    this.citingWorks,
    this.works,
    required this.background,
  });

  final dynamic hIndex;
  final dynamic citations;
  final dynamic citingWorks;
  final dynamic works;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (hIndex != null) {
      items.add(_metricSvg(CitationTheme.iconHash, 'h-index: $hIndex'));
    }
    if (citations != null) {
      items.add(_metricSvg(CitationTheme.iconQuote, 'citations: ${_formatNumber(citations)}'));
    }
    if (citingWorks != null && _readNum(citingWorks) > 0) {
      items.add(Text(
        'citing works: ${_formatNumber(citingWorks)}',
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ));
    }
    if (works != null) {
      items.add(Text(
        'works: ${_formatNumber(works)}',
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: items,
      ),
    );
  }

  Widget _metricSvg(String asset, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          width: 12,
          height: 12,
          colorFilter: const ColorFilter.mode(Color(0xFF6B7280), BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      ],
    );
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _TopicTag extends StatelessWidget {
  const _TopicTag({
    required this.text,
    required this.index,
    this.compact = false,
  });

  final String text;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = CitationTheme.tagBackgrounds[index % CitationTheme.tagBackgrounds.length];
    final fg = CitationTheme.tagForegrounds[index % CitationTheme.tagForegrounds.length];
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _CitationAvatar extends StatelessWidget {
  const _CitationAvatar({
    required this.url,
    required this.size,
    this.ring = false,
  });

  final String? url;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFEEEEEE),
      backgroundImage: hasUrl ? NetworkImage(url!) : null,
      child: hasUrl
          ? null
          : ClipOval(
              child: Image.asset(
                CitationTheme.avatarScholar,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
    );

    if (ring) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: avatar,
      );
    }
    return avatar;
  }
}

String _formatNumber(dynamic value) {
  final num n;
  if (value is num) {
    n = value;
  } else {
    n = num.tryParse(value?.toString() ?? '') ?? 0;
  }
  return NumberFormat.decimalPattern().format(n);
}

/// 与 TSX `MorePapersSection` + `ScholarPaperCard` 对齐。
class CitationMorePapersSection extends StatefulWidget {
  const CitationMorePapersSection({super.key, required this.scholarName});

  final String scholarName;

  @override
  State<CitationMorePapersSection> createState() => _CitationMorePapersSectionState();
}

class _CitationMorePapersSectionState extends State<CitationMorePapersSection> {
  final _service = SearchService();
  bool _triggered = false;
  bool _loading = false;
  Map<String, dynamic>? _profile;

  Future<void> _load() async {
    setState(() {
      _triggered = true;
      _loading = true;
    });
    try {
      final data = await _service.getScholarProfile(authorName: widget.scholarName);
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_triggered) {
      return OutlinedButton(
        onPressed: _load,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6B7280),
          side: const BorderSide(color: Color(0xFFD1D5DB), style: BorderStyle.solid),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              CitationTheme.iconGraduation,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(Color(0xFF6B7280), BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text('View More Papers by ${widget.scholarName}'),
          ],
        ),
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading papers...', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    final papers = _profile?['papers'] is List
        ? (_profile!['papers'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final name = _profile?['name']?.toString() ?? widget.scholarName;

    if (papers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No additional papers found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Papers by $name (${papers.length})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < papers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ScholarPaperExpandCard(paper: papers[i]),
        ],
      ],
    );
  }
}

class _ScholarPaperExpandCard extends StatefulWidget {
  const _ScholarPaperExpandCard({required this.paper});

  final Map<String, dynamic> paper;

  @override
  State<_ScholarPaperExpandCard> createState() => _ScholarPaperExpandCardState();
}

class _ScholarPaperExpandCardState extends State<_ScholarPaperExpandCard> {
  final _service = SearchService();
  bool _expanded = false;
  bool _loading = false;
  Map<String, dynamic>? _citersData;

  Future<void> _toggle() async {
    final next = !_expanded;
    setState(() => _expanded = next);
    if (next && _citersData == null) {
      setState(() => _loading = true);
      try {
        final title = widget.paper['title']?.toString() ?? '';
        final data = await _service.getPaperCiters(paperIdentifier: title);
        if (!mounted) return;
        setState(() {
          _citersData = data;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ScholarPaperSummary(paper: widget.paper)),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: SvgPicture.asset(
                          CitationTheme.iconChevron,
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF9CA3AF),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0x4DF9FAFB),
                  border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: _buildExpandedBody(),
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Loading citers...', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    final citers = _citersData?['citers'] is List
        ? (_citersData!['citers'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    if (_citersData != null && citers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No citer data available for this paper.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      );
    }

    if (citers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _CitersSection(
        citers: citers,
        totalCitingWorks: _readNum(_citersData?['total_citing_works']),
      ),
    );
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}
