import '../../../../stores/chat_history_store.dart';

/// Mock data for Basic users to show blurred preview of premium feature (sync with TSX MOCK_HISTORY_ITEMS).
List<ConversationItem> get mockHistoryItems => [
      ConversationItem(
        id: -1,
        title: 'Machine learning research trends',
        type: 'discover',
        recordCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ConversationItem(
        id: -2,
        title: 'Best universities for PhD',
        type: 'discover',
        recordCount: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ConversationItem(
        id: -3,
        title: 'Find collaborators in NLP',
        type: 'discover',
        recordCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
