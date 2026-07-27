import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/deep_search_enrich_models.dart';

/// 对齐 Web `deepSearchEnrichStore` persist：缓存 enrich 结果与 email reveal 状态，
/// 避免已购买的 email 在重新进入详情时再次显示「Get email」。
class DeepSearchEnrichPersistence {
  DeepSearchEnrichPersistence._();

  static const _storageKey = 'dinq_deep_search_enrich_v2';
  static const enrichTtlMs = 7 * 24 * 60 * 60 * 1000;
  static const maxEntries = 100;

  static Future<Map<String, EnrichEntry>> load(String? ownerId) async {
    if (ownerId == null || ownerId.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      if (decoded['ownerId']?.toString() != ownerId) return {};

      final entries = decoded['cache'];
      if (entries is! Map) return {};

      final now = DateTime.now().millisecondsSinceEpoch;
      final loaded = <String, EnrichEntry>{};

      for (final entry in entries.entries) {
        final rowId = entry.key.toString();
        final value = entry.value;
        if (value is! Map) continue;
        final map = Map<String, dynamic>.from(value);

        final savedAt = map['savedAt'] as int?;
        if (savedAt == null || now - savedAt > enrichTtlMs) continue;

        final personJson = map['personJson'];
        final personMap = personJson is Map
            ? Map<String, dynamic>.from(personJson)
            : null;
        if (personMap == null || personMap.isEmpty) continue;

        final statusRaw = map['status']?.toString() ?? 'done';
        final status = EnrichStatus.values.firstWhere(
          (s) => s.name == statusRaw,
          orElse: () => EnrichStatus.done,
        );

        loaded[rowId] = EnrichEntry(
          person: EnrichResultPerson.fromJson(personMap),
          personJson: personMap,
          status: status,
          dinqCards: _decodeDinqCards(map['dinqCards']),
          fromCache: map['fromCache'] == true,
          emailRevealAttempted: map['emailRevealAttempted'] == true,
          revealedEmail: map['revealedEmail']?.toString(),
          emailRevealError: map['emailRevealError'] == true,
          savedAt: savedAt,
          requestParams: _decodeRequestParams(map['requestParams']),
        );
      }

      if (loaded.length <= maxEntries) return loaded;

      final sorted = loaded.entries.toList()
        ..sort((a, b) => (b.value.savedAt ?? 0).compareTo(a.value.savedAt ?? 0));
      return Map.fromEntries(sorted.take(maxEntries));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(
    String? ownerId,
    Map<String, EnrichEntry> cache,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (ownerId == null || ownerId.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final fresh = cache.entries.where((entry) {
      final e = entry.value;
      return e.person != null &&
          e.savedAt != null &&
          now - e.savedAt! <= enrichTtlMs;
    }).toList()
      ..sort((a, b) => (b.value.savedAt ?? 0).compareTo(a.value.savedAt ?? 0));

    final kept = fresh.take(maxEntries);
    final payload = <String, dynamic>{
      'ownerId': ownerId,
      'cache': {
        for (final entry in kept)
          entry.key: {
            'personJson': entry.value.personJson,
            'dinqCards': entry.value.dinqCards.map((c) => c.toJson()).toList(),
            'status': entry.value.status.name,
            'fromCache': entry.value.fromCache,
            'emailRevealAttempted': entry.value.emailRevealAttempted,
            'revealedEmail': entry.value.revealedEmail,
            'emailRevealError': entry.value.emailRevealError,
            'savedAt': entry.value.savedAt,
            if (entry.value.requestParams != null)
              'requestParams': entry.value.requestParams!.toJson(),
          },
      },
    };

    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static List<EnrichDinqCard> _decodeDinqCards(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => EnrichDinqCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static EnrichStreamRequest? _decodeRequestParams(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = map['name']?.toString();
    final text = map['text']?.toString();
    final sessionId =
        map['session_id']?.toString() ?? map['sessionId']?.toString();
    if (name == null || text == null || sessionId == null) return null;
    return EnrichStreamRequest(
      name: name,
      text: text,
      sessionId: sessionId,
      userLanguage: map['user_language']?.toString() ?? map['userLanguage']?.toString(),
      company: map['company']?.toString(),
    );
  }
}
