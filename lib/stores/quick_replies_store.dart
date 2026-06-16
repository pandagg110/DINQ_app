import 'package:flutter/foundation.dart';

/// 与 TSX `quickRepliesStore.ts` 对齐：记录已点击的 quick-reply blockId。
class QuickRepliesStore extends ChangeNotifier {
  final Set<String> _usedIds = {};

  Set<String> get usedIds => Set.unmodifiable(_usedIds);

  bool isUsed(String blockId) => _usedIds.contains(blockId);

  void markUsed(String blockId) {
    if (_usedIds.contains(blockId)) return;
    _usedIds.add(blockId);
    notifyListeners();
  }

  void markAllUsed(Iterable<String> blockIds) {
    var changed = false;
    for (final id in blockIds) {
      if (_usedIds.add(id)) changed = true;
    }
    if (changed) notifyListeners();
  }

  void clear() {
    if (_usedIds.isEmpty) return;
    _usedIds.clear();
    notifyListeners();
  }
}
