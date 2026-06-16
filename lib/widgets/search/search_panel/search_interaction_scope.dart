import 'package:flutter/widgets.dart';

typedef QuickReplySelectCallback = void Function(String option, String blockId);
typedef ConfirmStartCallback = void Function(
  String query,
  String displayQuery,
  String blockId,
);

/// 与 Web `useDeepSearchStore.triggerSearch` 对齐，供 NarrationBlockView / QuickReplies 读取。
class SearchInteractionScope extends InheritedWidget {
  const SearchInteractionScope({
    super.key,
    required this.onQuickReplySelect,
    this.onConfirmStart,
    required super.child,
  });

  final QuickReplySelectCallback? onQuickReplySelect;
  final ConfirmStartCallback? onConfirmStart;

  static SearchInteractionScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SearchInteractionScope>();
  }

  @override
  bool updateShouldNotify(covariant SearchInteractionScope oldWidget) {
    return onQuickReplySelect != oldWidget.onQuickReplySelect ||
        onConfirmStart != oldWidget.onConfirmStart;
  }
}
