import '../models/card_models.dart';
import 'card_store.dart';

/// 用于「看别人的」Profile 的卡片 Store，与 [CardStore] 数据隔离。
/// 仅支持只读：loadCards、选中状态、轮询状态；所有写操作（增删改布局/保存）为 no-op。
class ViewerCardStore extends CardStore {
  @override
  Future<CardItem?> addCard({
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    return null;
  }
}
