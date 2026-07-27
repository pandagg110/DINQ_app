import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/deep_search_enrich_models.dart';
import 'deep_search_enrich_persistence.dart';
import 'user_store.dart';

/// 对齐 Web `deepSearchEnrichStore.ts`。
class DeepSearchEnrichStore extends ChangeNotifier {
  DeepSearchEnrichStore() {
    UserStore.registerLogoutCleanup(clearForLogout);
  }

  String? _selectedRowId;
  final Map<String, EnrichEntry> _cache = {};
  String? _ownerId;
  String? _hydratedForOwnerId;
  int _persistGeneration = 0;

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

  Future<void> ensureHydrated(String? ownerId) async {
    _ownerId = ownerId;
    if (ownerId == null || ownerId.isEmpty) return;
    if (_hydratedForOwnerId == ownerId) return;
    _hydratedForOwnerId = ownerId;

    final loaded = await DeepSearchEnrichPersistence.load(ownerId);
    if (loaded.isEmpty) return;

    for (final entry in loaded.entries) {
      final current = _cache[entry.key];
      if (current == null) {
        _cache[entry.key] = entry.value;
        continue;
      }
      _mergePersistedEntry(current, entry.value);
    }
    notifyListeners();
  }

  void clearForLogout() {
    _cache.clear();
    _selectedRowId = null;
    _ownerId = null;
    _hydratedForOwnerId = null;
    _confidenceByRowId.clear();
    unawaited(DeepSearchEnrichPersistence.clear());
    notifyListeners();
  }

  void selectRow(String rowId) {
    _selectedRowId = rowId;
    // 立即占位，避免面板打开到 resetEntry 之间 entry 为 null、骨架屏不渲染。
    _cache.putIfAbsent(
      rowId,
      () => EnrichEntry(status: EnrichStatus.streaming),
    );
    final entry = _cache[rowId];
    if (entry != null &&
        entry.person != null &&
        entry.personJson.isEmpty) {
      entry.personJson = entry.person!.toJson();
    }
    notifyListeners();
  }

  void closePanel() {
    _selectedRowId = null;
    notifyListeners();
  }

  void resetEntry(String rowId, EnrichStreamRequest? requestParams) {
    final previous = _cache[rowId];
    final entry = EnrichEntry(
      status: EnrichStatus.streaming,
      personJson: {},
      requestParams: requestParams,
    );
    _preserveEmailRevealState(entry, previous);
    _cache[rowId] = entry;
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
    entry.savedAt = DateTime.now().millisecondsSinceEpoch;
    _cache[rowId] = entry;
    notifyListeners();
    _schedulePersist();
  }

  void failEmailReveal(String rowId) {
    final entry = _cache[rowId] ?? EnrichEntry();
    entry.emailRevealing = false;
    entry.emailRevealAttempted = true;
    entry.revealedEmail = null;
    entry.emailRevealError = true;
    entry.savedAt = DateTime.now().millisecondsSinceEpoch;
    _cache[rowId] = entry;
    notifyListeners();
    _schedulePersist();
  }

  void handleStreamEvent(String rowId, Map<String, dynamic> event) {
    final type = event['type']?.toString();
    var shouldPersist = false;
    switch (type) {
      case 'start':
        {
          final previous = _cache[rowId];
          final entry = EnrichEntry(
            status: EnrichStatus.streaming,
            personJson: {},
            toolLogs: [
              EnrichToolLog(
                tool: 'start',
                message: 'Enriching ${event['name'] ?? ''}',
                status: 'done',
                startedAt: DateTime.now().millisecondsSinceEpoch,
                endedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
            requestParams: previous?.requestParams,
          );
          _preserveEmailRevealState(entry, previous);
          _cache[rowId] = entry;
        }
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
            final email = _extractCacheEmail(Map<String, dynamic>.from(data));
            if (personData is Map) {
              _mergePersonIntoEntry(
                entry,
                Map<String, dynamic>.from(personData),
              );
              entry.fromCache = true;
              entry.savedAt = DateTime.now().millisecondsSinceEpoch;
              if (email != null && email.isNotEmpty) {
                entry.emailRevealing = false;
                entry.emailRevealAttempted = true;
                entry.revealedEmail = email;
                entry.emailRevealError = false;
                shouldPersist = true;
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
            _mergePersonIntoEntry(
              entry,
              Map<String, dynamic>.from(data),
            );
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
            final personMap = Map<String, dynamic>.from(data);
            entry.personJson = personMap;
            entry.person = EnrichResultPerson.fromJson(personMap);
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
          shouldPersist = true;
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
    if (shouldPersist) _schedulePersist();
  }

  int _lastRunningLogIndex(List<EnrichToolLog> logs) {
    for (var i = logs.length - 1; i >= 0; i--) {
      if (logs[i].status == 'running') return i;
    }
    return -1;
  }

  void _mergePersistedEntry(EnrichEntry target, EnrichEntry persisted) {
    _preserveEmailRevealState(target, persisted);

    if (persisted.person != null &&
        (target.person == null || target.status != EnrichStatus.done)) {
      target.person = persisted.person;
      target.personJson = persisted.personJson;
      target.status = persisted.status;
      target.fromCache = persisted.fromCache;
      target.savedAt = persisted.savedAt;
      target.requestParams ??= persisted.requestParams;
    }
  }

  void _preserveEmailRevealState(EnrichEntry target, EnrichEntry? source) {
    if (source == null) return;
    final revealedEmail = source.revealedEmail?.trim();
    if (source.emailRevealAttempted &&
        revealedEmail != null &&
        revealedEmail.isNotEmpty) {
      target.emailRevealAttempted = true;
      target.revealedEmail = revealedEmail;
      target.emailRevealError = false;
      target.savedAt ??= source.savedAt;
    } else if (source.emailRevealAttempted && source.emailRevealError) {
      target.emailRevealAttempted = true;
      target.emailRevealError = true;
      target.revealedEmail = null;
      target.savedAt ??= source.savedAt;
    } else if (source.emailRevealAttempted) {
      target.emailRevealAttempted = true;
      target.emailRevealError = false;
      target.revealedEmail = null;
      target.savedAt ??= source.savedAt;
    }
  }

  String? _extractCacheEmail(Map<String, dynamic> data) {
    final direct = data['email']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final emails = data['emails'];
    if (emails is List) {
      final parts = emails
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    if (emails is String && emails.trim().isNotEmpty) {
      return emails.trim();
    }
    return null;
  }

  void _schedulePersist() {
    final ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) return;
    final generation = ++_persistGeneration;
    Future<void>(() async {
      if (generation != _persistGeneration) return;
      await DeepSearchEnrichPersistence.save(ownerId, _cache);
    });
  }

  void _mergePersonIntoEntry(EnrichEntry entry, Map<String, dynamic> patch) {
    entry.personJson = mergePersonJson(entry.personJson, patch);
    entry.person = EnrichResultPerson.fromJson(entry.personJson);

    final person = entry.person!;
    final allUrls = _extractUrls(person);
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
