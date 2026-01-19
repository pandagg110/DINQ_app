import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/card_models.dart';
import '../services/card_service.dart';
import '../services/datasource_service.dart';

class CardStore extends ChangeNotifier {
  CardStore() {
    _cardService = CardService();
    _datasourceService = DatasourceService();
  }

  late final CardService _cardService;
  late final DatasourceService _datasourceService;

  ViewMode viewMode = ViewMode.desktop;
  List<CardItem> cards = [];
  Map<String, CardState> cardStates = {};
  Set<String> dirtyCardIds = {};
  bool isInitialized = false;
  bool isAdding = false;
  bool isSaving = false;

  Timer? _saveTimer;

  Future<void> loadCards(String username) async {
    try {
      final result = await _cardService.getCardBoard(username);
      cards = result;
      isInitialized = true;
      notifyListeners();
    } catch (_) {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<CardItem?> addCard({required String type, Map<String, dynamic>? metadata}) async {
    isAdding = true;
    notifyListeners();

    final id = const Uuid().v4();
    final mockCard = CardItem(
      id: id,
      data: CardData(
        id: id,
        type: type,
        title: metadata?['title']?.toString() ?? '',
        description: metadata?['description']?.toString() ?? '',
        metadata: metadata ?? {},
        status: 'PROCESSING',
      ),
      layout: CardLayout(
        desktop: CardLayoutState(
          size: '2x2',
          position: CardPosition(x: 0, y: 0, w: 2, h: 2),
        ),
        mobile: CardLayoutState(
          size: '2x2',
          position: CardPosition(x: 0, y: 0, w: 2, h: 2),
        ),
      ),
    );

    cards.add(mockCard);
    cardStates[id] = CardState(loading: true, isNew: true);
    notifyListeners();

    try {
      final created = await _cardService.addCardToBoard(type: type, metadata: metadata);
      _replaceCard(id, created);
      return created;
    } catch (_) {
      return mockCard;
    } finally {
      isAdding = false;
      notifyListeners();
    }
  }

  void _replaceCard(String tempId, CardItem created) {
    final index = cards.indexWhere((card) => card.id == tempId);
    if (index >= 0) {
      cards[index] = created;
      cardStates.remove(tempId);
      cardStates[created.id] = CardState(loading: false);
      dirtyCardIds.add(created.id);
      _scheduleSave();
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
      cards[index] = CardItem(id: cards[index].id, data: data, layout: cards[index].layout);
      dirtyCardIds.add(cardId);
      _scheduleSave();
      notifyListeners();
    }
  }

  void updateCardLayout(String cardId, CardLayout layout) {
    final index = cards.indexWhere((card) => card.id == cardId);
    if (index >= 0) {
      cards[index] = CardItem(id: cards[index].id, data: cards[index].data, layout: layout);
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

  Future<void> regenerateCard({String? cardId}) async {
    if (cardId == null) {
      await _datasourceService.regenerateAllCards();
      return;
    }
    await _datasourceService.regenerateCard(datasourceId: cardId);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1000), () async {
      await _saveDirtyCards();
    });
  }

  Future<void> _saveDirtyCards() async {
    if (dirtyCardIds.isEmpty) return;
    isSaving = true;
    notifyListeners();
    try {
      final dirty = cards.where((card) => dirtyCardIds.contains(card.id)).toList();
      await _cardService.updateCardBoard(dirty);
      dirtyCardIds.clear();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}


