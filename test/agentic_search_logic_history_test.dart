import 'dart:async';

import 'package:dinq_app/services/history_service.dart';
import 'package:dinq_app/services/search_service.dart';
import 'package:dinq_app/stores/chat_history_store.dart';
import 'package:dinq_app/stores/search_store.dart';
import 'package:dinq_app/widgets/search/agentic_search_logic.dart';
import 'package:dinq_app/widgets/search/deep_search/deep_search_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControlledSearchService extends SearchService {
  final StreamController<Map<String, dynamic>> controller =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> chatStream({
    String? query,
    String mode = 'research',
    int? conversationId,
    String? sessionId,
    String? claudeSessionId,
    String? userId,
    String? attachment,
    String modelProvider = 'anthropic-hao',
  }) {
    return controller.stream;
  }
}

class _EmptyHistoryService extends HistoryService {
  @override
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
    String? type,
  }) async {
    return {'conversations': <Map<String, dynamic>>[], 'total': 0};
  }
}

({
  AgenticSearchLogic logic,
  _ControlledSearchService searchService,
  SearchStore searchStore,
  ChatHistoryStore historyStore,
})
_buildLogic() {
  final searchService = _ControlledSearchService();
  final searchStore = SearchStore();
  final historyStore = ChatHistoryStore(historyService: _EmptyHistoryService());
  final logic = AgenticSearchLogic(
    searchService: searchService,
    searchStore: searchStore,
    chatHistoryStore: historyStore,
  );
  logic.bindSessionId('session-1');
  return (
    logic: logic,
    searchService: searchService,
    searchStore: searchStore,
    historyStore: historyStore,
  );
}

void main() {
  test('discover running state follows Web search_state precedence', () {
    expect(
      AgenticSearchLogic.isDiscoverConversationRunning({
        'search_state': 'running',
        'is_running': false,
      }),
      isTrue,
    );
    expect(
      AgenticSearchLogic.isDiscoverConversationRunning({
        'search_state': 'completed',
        'is_running': true,
      }),
      isFalse,
    );
    expect(
      AgenticSearchLogic.isDiscoverConversationRunning({
        'search_state': 'empty',
        'is_running': true,
      }),
      isFalse,
    );
    expect(
      AgenticSearchLogic.isDiscoverConversationRunning({'is_running': true}),
      isTrue,
    );
  });

  test('detached placeholder renders searching without a local stream', () {
    final harness = _buildLogic();
    addTearDown(() async {
      harness.logic.dispose();
      harness.searchStore.dispose();
      harness.historyStore.dispose();
      if (!harness.searchService.controller.isClosed) {
        await harness.searchService.controller.close();
      }
    });

    harness.logic.seedSearchingPlaceholder(
      query: '  Find Flutter engineers  ',
      sessionId: 'background-session',
    );

    expect(harness.logic.activeSessionId, 'background-session');
    expect(harness.logic.hasActiveLocalStream, isFalse);
    expect(harness.logic.loading, isFalse);
    expect(harness.searchStore.isSearching, isFalse);
    expect(harness.logic.messageGroups, hasLength(1));
    expect(
      harness.logic.messageGroups.single.roundStatus,
      DeepSearchRoundStatus.searching,
    );
    expect(
      harness.logic.messageGroups.single.displayQuery,
      'Find Flutter engineers',
    );

    harness.logic.seedSearchingPlaceholder(
      query: 'Must not add a second placeholder',
      sessionId: 'background-session',
    );
    expect(harness.logic.messageGroups, hasLength(1));
  });

  test(
    'empty running detail clears stale rounds before placeholder seeding',
    () {
      final harness = _buildLogic();
      addTearDown(() async {
        harness.logic.dispose();
        harness.searchStore.dispose();
        harness.historyStore.dispose();
        if (!harness.searchService.controller.isClosed) {
          await harness.searchService.controller.close();
        }
      });

      harness.logic.seedSearchingPlaceholder(
        query: 'Old session',
        sessionId: 'old-session',
      );
      expect(harness.logic.messageGroups, isNotEmpty);

      harness.logic.loadFromConversation({
        'id': 'background-session',
        'type': 'discover',
        'title': 'Background search',
        'records': <Map<String, dynamic>>[],
        'search_state': 'running',
      });

      expect(harness.logic.activeSessionId, 'background-session');
      expect(harness.logic.messageGroups, isEmpty);
      expect(harness.logic.loading, isFalse);
      expect(harness.searchStore.isSearching, isFalse);
    },
  );

  test('SSE onDone clears hasActiveLocalStream', () async {
    final harness = _buildLogic();
    addTearDown(() async {
      harness.logic.dispose();
      harness.searchStore.dispose();
      harness.historyStore.dispose();
      if (!harness.searchService.controller.isClosed) {
        await harness.searchService.controller.close();
      }
    });

    harness.logic.handleSearch(
      query: 'Find Flutter engineers',
      submissionId: 'history-on-done',
    );
    expect(harness.logic.hasActiveLocalStream, isTrue);

    await harness.searchService.controller.close();
    await pumpEventQueue();

    expect(harness.logic.hasActiveLocalStream, isFalse);
  });

  test('SSE onError clears hasActiveLocalStream', () async {
    final harness = _buildLogic();
    addTearDown(() async {
      harness.logic.dispose();
      harness.searchStore.dispose();
      harness.historyStore.dispose();
      if (!harness.searchService.controller.isClosed) {
        await harness.searchService.controller.close();
      }
    });

    harness.logic.handleSearch(
      query: 'Find Flutter engineers',
      submissionId: 'history-on-error',
    );
    expect(harness.logic.hasActiveLocalStream, isTrue);

    harness.searchService.controller.addError(StateError('stream failed'));
    await pumpEventQueue();

    expect(harness.logic.hasActiveLocalStream, isFalse);
  });

  test(
    'local detach keeps pending history until server confirmation',
    () async {
      final harness = _buildLogic();
      addTearDown(() async {
        harness.logic.dispose();
        harness.searchStore.dispose();
        harness.historyStore.dispose();
        if (!harness.searchService.controller.isClosed) {
          await harness.searchService.controller.close();
        }
      });

      harness.logic.handleSearch(
        query: 'Find Flutter engineers',
        submissionId: 'history-detach',
      );
      expect(harness.historyStore.conversations, hasLength(1));
      expect(harness.historyStore.conversations.single.isLocalPending, isTrue);

      harness.logic.abortLocalStream(clearPending: false);
      await pumpEventQueue();

      expect(harness.logic.hasActiveLocalStream, isFalse);
      expect(harness.historyStore.conversations, hasLength(1));
      expect(harness.historyStore.conversations.single.isLocalPending, isTrue);
    },
  );

  test(
    'disposing an active local stream preserves its pending history row',
    () async {
      final harness = _buildLogic();
      addTearDown(() async {
        harness.searchStore.dispose();
        harness.historyStore.dispose();
        if (!harness.searchService.controller.isClosed) {
          await harness.searchService.controller.close();
        }
      });

      harness.logic.handleSearch(
        query: 'Find Flutter engineers',
        submissionId: 'history-dispose',
      );
      expect(harness.historyStore.conversations.single.isLocalPending, isTrue);

      harness.logic.dispose();
      await pumpEventQueue();

      expect(harness.searchStore.isSearching, isFalse);
      expect(harness.historyStore.conversations, hasLength(1));
      expect(harness.historyStore.conversations.single.isLocalPending, isTrue);
    },
  );

  test('disposing an old logic cannot clear a newer stream owner', () async {
    final searchStore = SearchStore();
    final historyStore = ChatHistoryStore(
      historyService: _EmptyHistoryService(),
    );
    final firstService = _ControlledSearchService();
    final secondService = _ControlledSearchService();
    final firstLogic = AgenticSearchLogic(
      searchService: firstService,
      searchStore: searchStore,
      chatHistoryStore: historyStore,
    )..bindSessionId('session-1');
    final secondLogic = AgenticSearchLogic(
      searchService: secondService,
      searchStore: searchStore,
      chatHistoryStore: historyStore,
    )..bindSessionId('session-2');
    addTearDown(() async {
      secondLogic.dispose();
      searchStore.dispose();
      historyStore.dispose();
      if (!firstService.controller.isClosed) {
        await firstService.controller.close();
      }
      if (!secondService.controller.isClosed) {
        await secondService.controller.close();
      }
    });

    firstLogic.handleSearch(query: 'First search', submissionId: 'first-owner');
    secondLogic.handleSearch(
      query: 'Second search',
      submissionId: 'second-owner',
    );
    expect(searchStore.isSearching, isTrue);

    firstLogic.dispose();
    await pumpEventQueue();

    expect(searchStore.isSearching, isTrue);
    expect(secondLogic.hasActiveLocalStream, isTrue);
  });
}
