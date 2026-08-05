import 'dart:async';

import 'package:dinq_app/services/history_service.dart';
import 'package:dinq_app/stores/chat_history_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoryService extends HistoryService {
  _FakeHistoryService(this.responses);

  final List<Object> responses;
  final List<String> markReadIds = [];
  final List<({String type, Object id, String title})> renames = [];

  @override
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
    String? type,
  }) async {
    final response = responses.removeAt(0);
    if (response is Map<String, dynamic>) return response;
    throw response;
  }

  @override
  Future<void> markDiscoverSessionRead(Object id) async {
    markReadIds.add(id.toString());
  }

  @override
  Future<void> renameConversation(
    String type,
    Object id,
    String title,
  ) async {
    renames.add((type: type, id: id, title: title));
  }
}

class _CompleterHistoryService extends HistoryService {
  final Completer<Map<String, dynamic>> response = Completer();
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
    String? type,
  }) {
    calls += 1;
    return response.future;
  }
}

class _TwoCompleterHistoryService extends HistoryService {
  final List<Completer<Map<String, dynamic>>> requests = [];

  @override
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
    String? type,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    requests.add(completer);
    return completer.future;
  }
}

Map<String, dynamic> _conversationJson({
  required String id,
  String title = 'Search',
  bool isRunning = false,
  String? searchState,
  bool? isRead,
  bool hasUnseenCompletion = false,
}) {
  final json = <String, dynamic>{
    'id': id,
    'type': 'discover',
    'title': title,
    'record_count': 1,
    'created_at': '2026-08-05T08:00:00.000Z',
    'updated_at': '2026-08-05T08:01:00.000Z',
    'is_running': isRunning,
    'has_unseen_completion': hasUnseenCompletion,
  };
  if (searchState != null) json['search_state'] = searchState;
  if (isRead != null) json['is_read'] = isRead;
  return json;
}

ConversationItem _conversation({
  required String id,
  bool isRunning = false,
  String? searchState,
  bool isLocalPending = false,
}) {
  final now = DateTime.utc(2026, 8, 5, 8);
  return ConversationItem(
    id: id,
    title: 'Search',
    type: 'discover',
    recordCount: 1,
    createdAt: now,
    updatedAt: now,
    isRunning: isRunning,
    searchState: searchState,
    isLocalPending: isLocalPending,
  );
}

void main() {
  group('ConversationItem search state', () {
    test('local pending wins over server state', () {
      final item = _conversation(
        id: 'session-1',
        searchState: 'completed',
        isLocalPending: true,
      );

      expect(item.effectiveSearchState, 'running');
      expect(item.serverSearchState, 'completed');
    });

    test('search_state wins over legacy is_running', () {
      final item = ConversationItem.fromJson(
        _conversationJson(
          id: 'session-1',
          isRunning: true,
          searchState: 'completed',
        ),
      );

      expect(item.serverSearchState, 'completed');
      expect(item.effectiveSearchState, 'completed');
    });

    test('explicit null is_read remains unknown instead of unread', () {
      final item = ConversationItem.fromJson({
        ..._conversationJson(id: 'session-1', searchState: 'completed'),
        'is_read': null,
      });

      expect(item.isRead, isNull);
    });

    test('parses list status timestamps from /history payload', () {
      final item = ConversationItem.fromJson({
        ..._conversationJson(
          id: 'session-1',
          isRunning: false,
          searchState: 'completed',
          isRead: false,
          hasUnseenCompletion: true,
        ),
        'search_started_at': '2026-08-05T08:00:10.000Z',
        'search_finished_at': '2026-08-05T08:01:20.000Z',
      });

      expect(item.searchStartedAt, DateTime.parse('2026-08-05T08:00:10.000Z'));
      expect(item.searchFinishedAt, DateTime.parse('2026-08-05T08:01:20.000Z'));
      expect(item.isRead, isFalse);
      expect(item.hasUnseenCompletion, isTrue);
    });
  });

  group('ChatHistoryStore local settled', () {
    test('marks unread completion and clears on read', () async {
      final service = _FakeHistoryService([]);
      final store = ChatHistoryStore(historyService: service);
      addTearDown(store.dispose);
      store.conversations = [
        _conversation(id: 'session-1', searchState: 'completed'),
      ];

      store.markDiscoverSessionLocalSettled('session-1');

      expect(store.conversations.single.isRead, isFalse);
      expect(store.conversations.single.hasUnseenCompletion, isTrue);
      expect(store.conversations.single.isLocalPending, isFalse);
      expect(store.conversations.single.localStatusSettledAt, isNotNull);

      final ok = await store.markDiscoverSessionRead('session-1');

      expect(ok, isTrue);
      expect(store.conversations.single.isRead, isTrue);
      expect(store.conversations.single.hasUnseenCompletion, isFalse);
      expect(store.conversations.single.localStatusSettledAt, isNull);
      expect(service.markReadIds, ['session-1']);
    });

    test('rename uses historyApi path and accepts string session ids', () async {
      final service = _FakeHistoryService([]);
      final store = ChatHistoryStore(historyService: service);
      addTearDown(store.dispose);
      store.conversations = [
        _conversation(id: 'session-abc', searchState: 'completed'),
      ];

      final ok = await store.renameConversation('session-abc', 'New title');

      expect(ok, isTrue);
      expect(store.conversations.single.title, 'New title');
      expect(service.renames, hasLength(1));
      expect(service.renames.single.type, 'discover');
      expect(service.renames.single.id, 'session-abc');
      expect(service.renames.single.title, 'New title');
    });
  });

  group('ChatHistoryStore pending lifecycle', () {
    test('pure local pending is removed when settled', () {
      final store = ChatHistoryStore();
      addTearDown(store.dispose);

      store.upsertPendingDiscoverSession(
        sessionId: 'session-1',
        title: 'Find an engineer',
      );

      expect(store.conversations, hasLength(1));
      expect(store.conversations.single.isLocalPending, isTrue);
      expect(store.conversations.single.serverSearchState, isNull);
      expect(store.conversations.single.effectiveSearchState, 'running');
      expect(
        store.total,
        0,
        reason: 'local pending must not change backend total',
      );

      store.clearPendingDiscoverSession('session-1');

      expect(store.conversations, isEmpty);
      expect(store.backgroundDiscoverQuery('session-1'), 'Find an engineer');
    });

    test('settling an existing completed item restores completed state', () {
      final store = ChatHistoryStore();
      addTearDown(store.dispose);
      store.conversations = [
        _conversation(id: 'session-1', searchState: 'completed'),
      ];

      store.upsertPendingDiscoverSession(
        sessionId: 'session-1',
        title: 'Follow-up search',
      );
      expect(store.conversations.single.effectiveSearchState, 'running');
      expect(store.conversations.single.serverSearchState, 'completed');

      store.clearPendingDiscoverSession('session-1');

      expect(store.conversations, hasLength(1));
      expect(store.conversations.single.isLocalPending, isFalse);
      expect(store.conversations.single.effectiveSearchState, 'completed');
    });

    test('an older pending revision cannot clear a newer search round', () {
      final store = ChatHistoryStore();
      addTearDown(store.dispose);

      final firstRevision = store.upsertPendingDiscoverSession(
        sessionId: 'session-1',
        title: 'First round',
      );
      final secondRevision = store.upsertPendingDiscoverSession(
        sessionId: 'session-1',
        title: 'Second round',
      );

      store.clearPendingDiscoverSession(
        'session-1',
        expectedRevision: firstRevision,
      );

      expect(store.conversations, hasLength(1));
      expect(store.conversations.single.isLocalPending, isTrue);
      expect(store.pendingDiscoverRevision('session-1'), secondRevision);

      store.clearPendingDiscoverSession(
        'session-1',
        expectedRevision: secondRevision,
      );
      expect(store.conversations, isEmpty);
    });

    test(
      'an unchanged completed row cannot confirm a newer same-session round',
      () {
        final store = ChatHistoryStore();
        addTearDown(store.dispose);
        final completed = _conversation(
          id: 'session-1',
          searchState: 'completed',
        );
        store.conversations = [completed];

        final revision = store.upsertPendingDiscoverSession(
          sessionId: 'session-1',
          title: 'Follow-up search',
        );

        expect(
          store.serverItemConfirmsPendingDiscoverSession(
            completed,
            expectedRevision: revision,
          ),
          isFalse,
        );
        store.clearServerConfirmedPendingDiscoverSessions([completed]);
        expect(store.conversations.single.isLocalPending, isTrue);

        final running = _conversation(
          id: 'session-1',
          isRunning: true,
          searchState: 'running',
        );
        expect(
          store.serverItemConfirmsPendingDiscoverSession(
            running,
            expectedRevision: revision,
          ),
          isTrue,
        );
        store.clearServerConfirmedPendingDiscoverSessions([running]);
        expect(store.conversations.single.isLocalPending, isFalse);
      },
    );
  });

  group('ChatHistoryStore server refresh', () {
    test('running conversation becomes completed after refresh', () async {
      final service = _FakeHistoryService([
        {
          'conversations': [
            _conversationJson(
              id: 'session-1',
              isRunning: true,
              searchState: 'running',
            ),
          ],
          'total': 1,
        },
        {
          'conversations': [
            _conversationJson(
              id: 'session-1',
              searchState: 'completed',
              isRead: false,
              hasUnseenCompletion: true,
            ),
          ],
          'total': 1,
        },
      ]);
      final store = ChatHistoryStore(historyService: service);
      addTearDown(store.dispose);

      await store.loadConversations('');
      expect(store.discoverServerSearchState('session-1'), 'running');

      await store.refreshTopConversations();

      expect(store.discoverServerSearchState('session-1'), 'completed');
      expect(store.conversations.single.isRead, isFalse);
      expect(store.conversations.single.hasUnseenCompletion, isTrue);
    });

    test(
      'first-page reload keeps pending but drops stale non-pending rows',
      () async {
        final service = _FakeHistoryService([
          {
            'conversations': [_conversationJson(id: 'server-session')],
            'total': 1,
          },
        ]);
        final store = ChatHistoryStore(historyService: service);
        addTearDown(store.dispose);
        store.conversations = [_conversation(id: 'stale-session')];
        store.upsertPendingDiscoverSession(
          sessionId: 'pending-session',
          title: 'Pending search',
        );

        await store.loadConversations('');

        expect(store.conversations.map((item) => item.id), [
          'pending-session',
          'server-session',
        ]);
      },
    );

    test('failed reload preserves the existing history snapshot', () async {
      final service = _FakeHistoryService([
        {
          'conversations': [_conversationJson(id: 'session-1')],
          'total': 1,
        },
        StateError('offline'),
      ]);
      final store = ChatHistoryStore(historyService: service);
      addTearDown(store.dispose);

      await store.loadConversations('');
      await store.loadConversations('');

      expect(store.conversations.map((item) => item.id), ['session-1']);
      expect(store.error, 'Failed to load history');
      expect(store.error, isNot(contains('DioException')));
    });

    test('coalesces concurrent top status refreshes', () async {
      final service = _CompleterHistoryService();
      final store = ChatHistoryStore(historyService: service);
      addTearDown(store.dispose);

      final first = store.refreshTopConversations();
      final second = store.refreshTopConversations(rethrowErrors: true);

      expect(service.calls, 1);
      service.response.complete({
        'conversations': [_conversationJson(id: 'session-1')],
        'total': 1,
      });

      await Future.wait([first, second]);
      expect(service.calls, 1);
      expect(store.conversations.map((item) => item.id), ['session-1']);
    });

    test(
      'background top refresh cannot cancel an in-flight keyword load',
      () async {
        final service = _TwoCompleterHistoryService();
        final store = ChatHistoryStore(historyService: service);
        addTearDown(store.dispose);

        final keywordLoad = store.loadConversations('needle');
        expect(service.requests, hasLength(1));
        final topRefresh = store.refreshTopConversations();
        expect(service.requests, hasLength(2));

        service.requests[1].complete({
          'conversations': [
            _conversationJson(
              id: 'background-session',
              isRunning: true,
              searchState: 'running',
            ),
          ],
          'total': 1,
        });
        await topRefresh;

        service.requests[0].complete({
          'conversations': [
            _conversationJson(id: 'keyword-session', title: 'Needle result'),
          ],
          'total': 1,
        });
        await keywordLoad;

        expect(store.searchQuery, 'needle');
        expect(store.conversations.map((item) => item.id), ['keyword-session']);
        expect(store.latestTopConversations?.map((item) => item.id), [
          'background-session',
        ]);
      },
    );
  });
}
