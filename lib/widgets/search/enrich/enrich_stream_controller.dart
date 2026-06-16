import 'package:dio/dio.dart';

import '../../../models/deep_search_enrich_models.dart';
import '../../../services/search_service.dart';
import '../../../stores/deep_search_enrich_store.dart';
import '../deep_search/deep_search_results_helpers.dart';

/// 对齐 Web `useEnrichStream.ts`。
class EnrichStreamController {
  EnrichStreamController({
    required DeepSearchEnrichStore enrichStore,
    required SearchService searchService,
    required String? Function() sessionIdProvider,
  })  : _enrichStore = enrichStore,
        _searchService = searchService,
        _sessionIdProvider = sessionIdProvider;

  final DeepSearchEnrichStore _enrichStore;
  final SearchService _searchService;
  final String? Function() _sessionIdProvider;

  CancelToken? _cancelToken;

  DeepSearchEnrichStore get enrichStore => _enrichStore;

  bool get isOpen => _enrichStore.isOpen;

  String? get selectedRowId => _enrichStore.selectedRowId;

  EnrichEntry? get entry => _enrichStore.selectedEntry;

  Future<void> openEnrich(Map<String, dynamic> row) async {
    final rowId = row['row_id']?.toString();
    if (rowId == null || rowId.isEmpty) return;

    final cached = _enrichStore.cache[rowId];
    if (cached?.status == EnrichStatus.done) {
      _enrichStore.selectRow(rowId);
      return;
    }

    final text = buildEnrichText(row);
    final name = row['name']?.toString() ?? '';
    final company = row['company']?.toString();
    _enrichStore.setRowConfidence(rowId, formatConfidence(row['confidence']));
    await _runEnrichFromData(
      rowId: rowId,
      name: name,
      text: text,
      company: company,
    );
  }

  Future<void> refreshEnrich() async {
    final rowId = _enrichStore.selectedRowId;
    if (rowId == null) return;
    final params = _enrichStore.cache[rowId]?.requestParams;
    if (params == null) return;
    await _runEnrichFromData(
      rowId: rowId,
      name: params.name,
      text: params.text,
      company: params.company,
      ignoreCacheEvent: true,
    );
  }

  void close() {
    _cancelToken?.cancel();
    _cancelToken = null;
    _enrichStore.closePanel();
  }

  Future<void> _runEnrichFromData({
    required String rowId,
    required String name,
    required String text,
    String? company,
    bool ignoreCacheEvent = false,
  }) async {
    _enrichStore.selectRow(rowId);

    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final sessionId = _sessionIdProvider() ?? '';
    final params = EnrichStreamRequest(
      name: name,
      text: text,
      sessionId: sessionId,
      company: company,
    );

    _enrichStore.resetEntry(rowId, params);

    try {
      await for (final event in _searchService.enrichStream(
        name: params.name,
        text: params.text,
        sessionId: params.sessionId,
        company: params.company,
        userLanguage: params.userLanguage,
        cancelToken: cancelToken,
      )) {
        if (ignoreCacheEvent && event['type'] == 'cache') continue;
        _enrichStore.handleStreamEvent(rowId, event);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _enrichStore.setError(rowId, e.message ?? 'Enrich failed');
    } catch (e) {
      _enrichStore.setError(rowId, e.toString());
    } finally {
      if (_cancelToken == cancelToken) {
        _cancelToken = null;
      }
    }
  }
}
