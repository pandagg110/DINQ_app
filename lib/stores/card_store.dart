import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card_models.dart';
import '../services/card_service.dart';
import '../services/datasource_service.dart';
import '../widgets/cards/factory/card_registry.dart';
import '../widgets/cards/factory/definitions/index.dart' show isAICard;

class CardStore extends ChangeNotifier {
  CardStore() {
    _cardService = CardService();
    _datasourceService = DatasourceService();
    _registry = CardRegistry();
  }

  late final CardService _cardService;
  late final DatasourceService _datasourceService;
  late final CardRegistry _registry;

  ViewMode viewMode = ViewMode.desktop;
  List<CardItem> cards = [];
  Map<String, CardState> cardStates = {};
  Set<String> dirtyCardIds = {};
  Set<String> selectedCardIds = {}; // 选中的卡片 ID
  bool isInitialized = false;
  bool isAdding = false;
  bool isSaving = false;

  Timer? _saveTimer;
  Timer? _pollingTimer;
  String? _currentUsername;

  static const Duration _saveDelay = Duration(milliseconds: 1000);
  static const Duration _pollingInterval = Duration(seconds: 3);

  Future<void> loadCards(String username) async {
    _currentUsername = username;

    // If we have cached cards, mark as initialized immediately (no blocking)
    if (cards.isNotEmpty) {
      isInitialized = true;
      notifyListeners();
    }

    try {
      // Fetch latest data in background
      final result = await _cardService.getCardBoard(username);

      // Smart merge: keep cached cards with data, use server data for others
      final cachedCardsMap = <String, CardItem>{};
      for (final card in cards) {
        cachedCardsMap[card.id] = card;
      }

      final mergedCards = <CardItem>[];
      for (final serverCard in result) {
        final cachedCard = cachedCardsMap[serverCard.id];
        if (cachedCard != null &&
            isAICard(cachedCard.data.type) &&
            cachedCard.data.status == 'COMPLETED') {
          // Keep cached card if it's a completed AI card
          mergedCards.add(cachedCard);
        } else {
          // Adapt server card to ensure layout data is valid
          CardItem adaptedCard = serverCard;
          // debugPrint('serverCard: ${serverCard.toJson().toString()}');
          if (_registry.isRegistered(serverCard.data.type)) {
            adaptedCard = _registry.adapt(serverCard, ViewMode.desktop);
            adaptedCard = _registry.adapt(adaptedCard, ViewMode.mobile);
          }
          mergedCards.add(adaptedCard);
        }
      }

      cards = mergedCards;
      isInitialized = true;
      notifyListeners();

      // Start polling immediately
      _startPolling();
    } catch (e) {
      debugPrint('CardStore: Error loading cards: $e');
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<CardItem?> addCard({
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    isAdding = true;
    notifyListeners();

    try {
      // Create mock card using CardRegistry
      final mockCard = await _registry.create(type, metadata ?? {}, cards);
      final adaptedCard = _registry.adapt(mockCard, viewMode);

      // Add mock card to UI immediately
      cards.add(adaptedCard);
      cardStates[adaptedCard.id] = CardState(
        loading: isAICard(type),
        isNew: true,
      );
      notifyListeners();

      // Remove isNew flag after animation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (cardStates.containsKey(adaptedCard.id)) {
          final state = cardStates[adaptedCard.id]!;
          cardStates[adaptedCard.id] = CardState(
            loading: state.loading,
            isNew: false,
          );
          notifyListeners();
        }
      });

      // Async call to create real card
      final finalMetadata = Map<String, dynamic>.from(
        adaptedCard.data.metadata,
      );
      final created = await _cardService.addCardToBoard(
        type: type,
        metadata: finalMetadata,
      );

      // Update card info but preserve layout
      final index = cards.indexWhere((c) => c.id == adaptedCard.id);
      if (index >= 0) {
        final realCard = _registry.isRegistered(created.data.type)
            ? _registry.adapt(created, viewMode)
            : created;

        cards[index] = CardItem(
          id: realCard.id,
          data: realCard.data,
          layout: adaptedCard.layout, // Preserve layout
        );

        cardStates.remove(adaptedCard.id);
        cardStates[realCard.id] = CardState(loading: isAICard(type));

        // Save current layout info to server
        dirtyCardIds.add(realCard.id);
        _scheduleSave();

        // If AI card, generate it
        if (isAICard(type)) {
          await _cardService.generateCard(
            datasourceId: realCard.data.id,
            type: type,
            extraMetadata: metadata,
          );
          _startPolling();
        }

        isAdding = false;
        notifyListeners();
        return cards[index];
      }

      isAdding = false;
      notifyListeners();
      return adaptedCard;
    } catch (e) {
      debugPrint('CardStore: Error adding card: $e');
      isAdding = false;
      notifyListeners();
      rethrow;
    }
  }

  void removeCard(String cardId) {
    cards.removeWhere((card) => card.id == cardId);
    cardStates.remove(cardId);
    notifyListeners();
    _cardService.deleteCard(cardId);
  }

  void clearCards() {
    cards = [];
    cardStates = {};
    notifyListeners();
  }

  void updateCardData(String cardId, CardData data) {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index >= 0) {
      cards[index] = CardItem(
        id: cards[index].id,
        data: data,
        layout: cards[index].layout,
      );
      dirtyCardIds.add(cardId);
      _scheduleSave();
      notifyListeners();
    }
  }

  void updateCardLayout(String cardId, CardLayout layout) {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index >= 0) {
      cards[index] = CardItem(
        id: cards[index].id,
        data: cards[index].data,
        layout: layout,
      );
      dirtyCardIds.add(cardId);
      _scheduleSave();
      notifyListeners();
    }
  }

  void setViewMode(ViewMode mode) {
    viewMode = mode;
    notifyListeners();
  }

  void setCardState(String cardId, CardState state) {
    cardStates[cardId] = state;
    notifyListeners();
  }

  /// 切换卡片选中状态（单选模式：只能同时选中一个）
  void toggleCardSelection(String cardId) {
    if (selectedCardIds.contains(cardId)) {
      // 如果已经选中，则取消选中
      selectedCardIds.remove(cardId);
    } else {
      // 如果未选中，先清除所有选中状态，然后选中当前卡片
      selectedCardIds.clear();
      selectedCardIds.add(cardId);
    }
    notifyListeners();
  }

  /// 清除所有选中状态
  void clearSelection() {
    selectedCardIds.clear();
    notifyListeners();
  }

  /// 检查卡片是否被选中
  bool isCardSelected(String cardId) {
    return selectedCardIds.contains(cardId);
  }

  Future<void> regenerateCard({String? cardId}) async {
    try {
      Map<String, dynamic> response;
      List<dynamic> results = [];

      if (cardId == null) {
        // Regenerate all cards
        response = await _datasourceService.regenerateAllCards();
        results = (response['results'] as List<dynamic>?) ?? [];
        if (results.isEmpty) {
          return;
        }
      } else {
        // Regenerate single card
        final card = cards.firstWhere(
          (c) => c.id == cardId,
          orElse: () => throw Exception('Card not found'),
        );

        response = await _datasourceService.regenerateCard(
          datasourceId: card.data.id,
        );
        final result = response['result'];
        if (result != null) {
          results = [result];
        }
      }

      // Handle results
      bool hasStarted = false;
      for (final result in results) {
        final resultMap = Map<String, dynamic>.from(result as Map);
        final status = resultMap['status']?.toString() ?? '';
        if (status == 'started') {
          hasStarted = true;
          final datasourceId = resultMap['datasource_id']?.toString() ?? '';

          // Find and update card
          final cardIndex = cards.indexWhere((c) => c.data.id == datasourceId);
          if (cardIndex >= 0) {
            final card = cards[cardIndex];
            cards[cardIndex] = CardItem(
              id: card.id,
              data: CardData(
                id: card.data.id,
                type: card.data.type,
                title: card.data.title,
                description: card.data.description,
                metadata: card.data.metadata,
                status: 'PROCESSING',
              ),
              layout: card.layout,
            );
            cardStates[card.id] = CardState(loading: true);
          }
        }
      }

      if (hasStarted) {
        _startPolling();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('CardStore: Failed to regenerate card: $e');
      rethrow;
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () async {
      await _saveDirtyCards();
    });
  }

  Future<void> _saveDirtyCards() async {
    // Don't save when isAdding
    if (isAdding || dirtyCardIds.isEmpty) return;

    isSaving = true;
    notifyListeners();

    try {
      final dirty = cards
          .where((card) => dirtyCardIds.contains(card.id))
          .toList();

      // Convert AI card types to "datasource" when saving
      final cardsToSave = dirty.map((card) {
        if (isAICard(card.data.type)) {
          return CardItem(
            id: card.id,
            data: CardData(
              id: card.data.id,
              type: 'datasource',
              title: card.data.title,
              description: card.data.description,
              metadata: card.data.metadata,
              status: card.data.status,
            ),
            layout: card.layout,
          );
        }
        return card;
      }).toList();

      await _cardService.updateCardBoard(cardsToSave);
      dirtyCardIds.clear();
    } catch (e) {
      debugPrint('CardStore: Failed to save cards: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Analyze datasource status and update cards
  Future<bool> _analyzeDatasource() async {
    if (_currentUsername == null) return false;
    // Collect data_source_ids from existing cards
    debugPrint('CardStore: _analyzeDatasource: ${cards.length}');
    final dataSourceIds = cards
        .where(
          (card) =>
              isAICard(card.data.type) && card.data.status == 'PROCESSING',
        )
        .map((card) => card.data.id)
        .toList();

    // if (dataSourceIds.isEmpty) return false;

    bool hasPending = false;

    try {
      final response = await _datasourceService.getDatasources(
        _currentUsername!,
        dataSourceIds: dataSourceIds,
      );
      final datasources = (response['data_sources'] as List<dynamic>?) ?? [];

      for (final datasourceData in datasources) {
        final datasource = Map<String, dynamic>.from(datasourceData as Map);
        final datasourceId = datasource['id']?.toString() ?? '';

        final cardIndex = cards.indexWhere(
          (card) => card.data.id == datasourceId,
        );
        if (cardIndex < 0) continue;

        final card = cards[cardIndex];
        final status = datasource['status']?.toString() ?? '';

        if (status == 'PROCESSING') {
          hasPending = true;
        }

        // Update card state
        if (!cardStates.containsKey(card.id)) {
          cardStates[card.id] = CardState();
        }
        final state = cardStates[card.id]!;
        cardStates[card.id] = CardState(
          loading: status == 'PROCESSING',
          isNew: state.isNew,
        );

        // Update card data
        Map<String, dynamic> finalMetadata;
        if (status == 'COMPLETED') {
          // Preserve user settings (like displayMode) - only for object metadata, not arrays
          // This is necessary because getDatasources returns raw_metadata which doesn't include
          // user settings like displayMode, but getCardBoard does include them.
          final prevDisplayMode = card.data.metadata['displayMode'];

          // Update card with raw_metadata from datasource
          final rawMetadata = datasource['raw_metadata'];
          if (rawMetadata is Map<String, dynamic>) {
            // For object metadata, preserve displayMode if it exists
            finalMetadata = prevDisplayMode != null
                ? {...rawMetadata, 'displayMode': prevDisplayMode}
                : rawMetadata;
          } else {
            // For array metadata (like career_trajectory) or other types,
            // use raw_metadata directly - the adapt method will handle conversion
            // We need to wrap it in a Map to satisfy the type system
            // The adapt method will extract and process it correctly
            finalMetadata = rawMetadata is List
                ? {'_raw_array': rawMetadata}
                : (rawMetadata as dynamic ?? card.data.metadata);
          }
        } else {
          // For non-COMPLETED status, keep existing metadata
          finalMetadata = card.data.metadata;
        }

        // Update card with new data
        CardItem updatedCard = CardItem(
          id: card.id,
          data: CardData(
            id: card.data.id,
            type: (datasource['type']?.toString() ?? card.data.type).toUpperCase(),
            title: card.data.title,
            description: card.data.description,
            metadata: finalMetadata,
            status: status,
          ),
          layout: card.layout,
        );

        // For COMPLETED status, handle array raw_metadata specially
        debugPrint('CardStore: status: ${status}');
        if (status == 'COMPLETED') {
          final rawMetadata = datasource['raw_metadata'];
          if (rawMetadata is List) {
            // For array metadata, we need to pass it directly to adapt
            // Create a temporary card with the array as metadata (using dynamic cast)
            // The adapt method will handle the conversion from array to Map
            final definition = _registry.getDefinition(updatedCard.data.type);
            if (definition != null) {
              // Call adapt directly with the array - it can handle List internally
              debugPrint('CardStore: rawMetadata: ${rawMetadata.toString()}');
              final adaptedMetadata = definition.adapt(rawMetadata);
              debugPrint('CardStore: adaptedMetadata: ${adaptedMetadata.toString()}');
              if (adaptedMetadata != null) {
                updatedCard = CardItem(
                  id: updatedCard.id,
                  data: CardData(
                    id: updatedCard.data.id,
                    type: updatedCard.data.type,
                    title: updatedCard.data.title,
                    description: updatedCard.data.description,
                    metadata: adaptedMetadata,
                    status: updatedCard.data.status,
                  ),
                  layout: updatedCard.layout,
                );
              }
            }
          } else {
            // For Map metadata, adapt normally through CardRegistry
            if (_registry.isRegistered(updatedCard.data.type)) {
              updatedCard = _registry.adapt(updatedCard, viewMode);
            }
          }
        } else {
          // For non-COMPLETED status, adapt normally
          if (_registry.isRegistered(updatedCard.data.type)) {
            updatedCard = _registry.adapt(updatedCard, viewMode);
          }
        }

        cards[cardIndex] = updatedCard;
      }

      // Filter out datasource type cards
      cards.removeWhere((card) => card.data.type.toLowerCase() == 'datasource');

      notifyListeners();
    } catch (e) {
      debugPrint('CardStore: Error analyzing datasource: $e');
    }

    return hasPending;
  }

  /// Start polling for datasource status
  void _startPolling() {
    // If already polling, stop first
    _pollingTimer?.cancel();
    _pollingTimer = null;

    // Start polling
    _pollingTimer = Timer(_pollingInterval, () async {
      final hasPending = await _analyzeDatasource();
      if (hasPending) {
        _startPolling(); // Continue polling
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
