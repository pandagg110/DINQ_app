import 'package:flutter/foundation.dart';

import '../models/deep_search_enrich_models.dart';

/// 对齐 Web `deepSearchEnrichStore.ts`。
class DeepSearchEnrichStore extends ChangeNotifier {
  String? _selectedRowId;
  final Map<String, EnrichEntry> _cache = {};

  String? get selectedRowId => _selectedRowId;
  Map<String, EnrichEntry> get cache => Map.unmodifiable(_cache);

  EnrichEntry? entryFor(String? rowId) =>
      rowId == null ? null : _cache[rowId];

  EnrichEntry? get selectedEntry =>
      _selectedRowId == null ? null : _cache[_selectedRowId];

  final Map<String, int> _confidenceByRowId = {};

  int? confidenceFor(String? rowId) =>
      rowId == null ? null : _confidenceByRowId[rowId];

  void setRowConfidence(String rowId, int? confidencePct) {
    if (confidencePct == null) {
      _confidenceByRowId.remove(rowId);
    } else {
      _confidenceByRowId[rowId] = confidencePct;
    }
  }

  bool get isOpen => _selectedRowId != null;

  void selectRow(String rowId) {
    _selectedRowId = rowId;
    // 立即占位，避免面板打开到 resetEntry 之间 entry 为 null、骨架屏不渲染。
    _cache.putIfAbsent(
      rowId,
      () => EnrichEntry(status: EnrichStatus.streaming),
    );
    notifyListeners();
  }

  void closePanel() {
    _selectedRowId = null;
    notifyListeners();
  }

  void resetEntry(String rowId, EnrichStreamRequest? requestParams) {
    _cache[rowId] = EnrichEntry(
      status: EnrichStatus.streaming,
      requestParams: requestParams,
    );
    notifyListeners();
  }

  void setError(String rowId, String message) {
    final entry = _cache[rowId] ?? EnrichEntry();
    entry.status = EnrichStatus.error;
    entry.errorMessage = message;
    _cache[rowId] = entry;
    notifyListeners();
  }

  void startEmailReveal(String rowId) {
    final entry = _cache[rowId] ?? EnrichEntry();
    entry.emailRevealing = true;
    _cache[rowId] = entry;
    notifyListeners();
  }

  void completeEmailReveal(String rowId, String? email) {
    final entry = _cache[rowId] ?? EnrichEntry();
    entry.emailRevealing = false;
    entry.emailRevealAttempted = true;
    entry.revealedEmail = email;
    entry.emailRevealError = false;
    _cache[rowId] = entry;
    notifyListeners();
  }

  void failEmailReveal(String rowId) {
    final entry = _cache[rowId] ?? EnrichEntry();
    entry.emailRevealing = false;
    entry.emailRevealAttempted = true;
    entry.revealedEmail = null;
    entry.emailRevealError = true;
    _cache[rowId] = entry;
    notifyListeners();
  }

  void handleStreamEvent(String rowId, Map<String, dynamic> event) {
    final type = event['type']?.toString();
    switch (type) {
      case 'start':
        _cache[rowId] = EnrichEntry(
          status: EnrichStatus.streaming,
          toolLogs: [
            EnrichToolLog(
              tool: 'start',
              message: 'Enriching ${event['name'] ?? ''}',
              status: 'done',
              startedAt: DateTime.now().millisecondsSinceEpoch,
              endedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ],
          requestParams: _cache[rowId]?.requestParams,
        );
        break;

      case 'tool_start':
        {
          final entry = _cache[rowId] ?? EnrichEntry();
          entry.toolLogs = [
            ...entry.toolLogs,
            EnrichToolLog(
              tool: event['tool']?.toString() ?? '',
              message: event['message']?.toString() ?? '',
              status: 'running',
              startedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ];
          _cache[rowId] = entry;
        }
        break;

      case 'tool_end':
        {
          final entry = _cache[rowId] ?? EnrichEntry();
          final logs = [...entry.toolLogs];
          final idx = _lastRunningLogIndex(logs);
          if (idx >= 0) {
            logs[idx] = logs[idx].copyWith(
              status: 'done',
              endedAt: DateTime.now().millisecondsSinceEpoch,
            );
          }
          entry.toolLogs = logs;
          _cache[rowId] = entry;
        }
        break;

      case 'cache':
        {
          final entry = _cache[rowId] ?? EnrichEntry();
          final data = event['data'];
          if (data is Map) {
            final personData = data['data'];
            final email = data['email']?.toString();
            if (personData is Map) {
              final person = EnrichResultPerson.fromJson(
                Map<String, dynamic>.from(personData),
              );
              _mergePersonIntoEntry(entry, person);
              entry.fromCache = true;
              entry.savedAt = DateTime.now().millisecondsSinceEpoch;
              if (email != null && email.isNotEmpty) {
                entry.emailRevealing = false;
                entry.emailRevealAttempted = true;
                entry.revealedEmail = email;
                entry.emailRevealError = false;
              }
            }
          }
          _cache[rowId] = entry;
        }
        break;

      case 'person_update':
        {
          final entry = _cache[rowId] ?? EnrichEntry();
          final data = event['data'];
          if (data is Map) {
            final person = EnrichResultPerson.fromJson(
              Map<String, dynamic>.from(data),
            );
            _mergePersonIntoEntry(entry, person);
            entry.savedAt = DateTime.now().millisecondsSinceEpoch;
          }
          _cache[rowId] = entry;
        }
        break;

      case 'done':
        {
          final entry = _cache[rowId] ?? EnrichEntry();
          final data = event['data'];
          if (data is Map) {
            entry.person = EnrichResultPerson.fromJson(
              Map<String, dynamic>.from(data),
            );
          }
          entry.status = EnrichStatus.done;
          entry.toolLogs = entry.toolLogs
              .map(
                (l) => l.status == 'running'
                    ? l.copyWith(
                        status: 'done',
                        endedAt: DateTime.now().millisecondsSinceEpoch,
                      )
                    : l,
              )
              .toList();
          entry.savedAt = DateTime.now().millisecondsSinceEpoch;
          _cache[rowId] = entry;
        }
        break;

      case 'error':
        {
          final entry = _cache[rowId] ?? EnrichEntry();
          entry.status = EnrichStatus.error;
          entry.errorMessage = event['message']?.toString() ?? 'Enrich failed';
          _cache[rowId] = entry;
        }
        break;
    }
    notifyListeners();
  }

  int _lastRunningLogIndex(List<EnrichToolLog> logs) {
    for (var i = logs.length - 1; i >= 0; i--) {
      if (logs[i].status == 'running') return i;
    }
    return -1;
  }

  void _mergePersonIntoEntry(EnrichEntry entry, EnrichResultPerson person) {
    entry.person =
        entry.person == null ? person : entry.person!.merge(person);

    final allUrls = _extractUrls(entry.person!);
    final newSources =
        allUrls.where((s) => !entry.seenUrls.contains(s.url)).toList();
    for (final s in newSources) {
      entry.seenUrls.add(s.url);
    }

    if (newSources.isNotEmpty && entry.toolLogs.isNotEmpty) {
      final logs = [...entry.toolLogs];
      final lastIdx = logs.length - 1;
      logs[lastIdx] = logs[lastIdx].copyWith(
        sources: [...?logs[lastIdx].sources, ...newSources],
      );
      entry.toolLogs = logs;
    }
  }

  List<EnrichToolLogSource> _extractUrls(EnrichResultPerson person) {
    final sources = <EnrichToolLogSource>[];
    final seen = <String>{};

    void add(String title, String url) {
      if (seen.contains(url)) return;
      seen.add(url);
      sources.add(
        EnrichToolLogSource(
          title: title,
          url: url,
          domain: _domainFromUrl(url),
        ),
      );
    }

    final homepage = person.personalHomepage;
    if (homepage != null && homepage.isNotEmpty) {
      add('Homepage', homepage);
    }
    for (final link in person.socialLinks ?? const []) {
      add(link.type.replaceAll('_', ' '), link.url);
    }
    for (final pub in person.keyPublications ?? const []) {
      final url = pub.url;
      if (url != null && url.isNotEmpty) add(pub.title, url);
    }
    for (final item in person.news ?? const []) {
      final url = item.url;
      if (url == null || url.isEmpty) continue;
      final title = RegExp(r'^Source\s*\[\d+\]$', caseSensitive: false)
              .hasMatch(item.description)
          ? _domainFromUrl(url)
          : item.description;
      add(title, url);
    }
    return sources;
  }

  String _domainFromUrl(String url) {
    try {
      return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url;
    }
  }
}
