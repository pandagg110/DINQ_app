import 'package:dinq_app/stores/chat_history_store.dart';
import 'package:dinq_app/widgets/search/history/chat_history_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ConversationItem _item({
  bool isRunning = false,
  String? searchState,
  bool isLocalPending = false,
  bool? isRead,
  bool hasUnseenCompletion = false,
  String type = 'discover',
}) {
  final now = DateTime.utc(2026, 8, 5, 8);
  return ConversationItem(
    id: 'session-1',
    title: 'Find Flutter engineers',
    type: type,
    recordCount: 1,
    createdAt: now,
    updatedAt: now,
    isRunning: isRunning,
    searchState: searchState,
    isLocalPending: isLocalPending,
    isRead: isRead,
    hasUnseenCompletion: hasUnseenCompletion,
  );
}

Future<void> _pumpItem(
  WidgetTester tester, {
  required ConversationItem item,
  bool isActive = false,
  bool isCurrentLocalSearching = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatHistoryItemWidget(
          conversation: item,
          isActive: isActive,
          isCurrentLocalSearching: isCurrentLocalSearching,
          onClick: () {},
          onDelete: (_) async => true,
        ),
      ),
    ),
  );
}

void main() {
  const spinnerKey = ValueKey('search-history-running-spinner');
  const slotKey = ValueKey('search-history-status-slot');
  const unreadKey = ValueKey('search-history-unread-indicator');

  testWidgets('non-current running conversation shows the flower spinner', (
    tester,
  ) async {
    await _pumpItem(tester, item: _item(searchState: 'running'));

    expect(find.byKey(spinnerKey), findsOneWidget);
    expect(tester.getSize(find.byKey(spinnerKey)), const Size(14, 14));
    expect(tester.getSize(find.byKey(slotKey)), const Size(16, 16));
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('current local search still shows the spinner', (tester) async {
    await _pumpItem(
      tester,
      item: _item(isLocalPending: true),
      isActive: true,
      isCurrentLocalSearching: true,
    );

    expect(find.byKey(spinnerKey), findsOneWidget);
  });

  testWidgets('current background running hides spinner but reserves slot', (
    tester,
  ) async {
    await _pumpItem(
      tester,
      item: _item(searchState: 'running'),
      isActive: true,
    );

    expect(find.byKey(spinnerKey), findsNothing);
    expect(tester.getSize(find.byKey(slotKey)), const Size(16, 16));
  });

  testWidgets('local pending hides the more menu', (tester) async {
    await _pumpItem(tester, item: _item(isLocalPending: true));

    expect(find.byKey(spinnerKey), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  testWidgets('completed unread conversation shows the green unread dot', (
    tester,
  ) async {
    await _pumpItem(
      tester,
      item: _item(
        searchState: 'completed',
        isRead: false,
        hasUnseenCompletion: true,
      ),
    );

    expect(find.byKey(spinnerKey), findsNothing);
    expect(find.byKey(unreadKey), findsOneWidget);
    expect(tester.getSize(find.byKey(unreadKey)), const Size(7, 7));
  });

  testWidgets('non-discover conversation does not render search status', (
    tester,
  ) async {
    await _pumpItem(
      tester,
      item: _item(type: 'analysis', searchState: 'running', isRead: false),
    );

    expect(find.byKey(spinnerKey), findsNothing);
    expect(find.byKey(unreadKey), findsNothing);
    expect(tester.getSize(find.byKey(slotKey)), const Size(16, 16));
  });
}
