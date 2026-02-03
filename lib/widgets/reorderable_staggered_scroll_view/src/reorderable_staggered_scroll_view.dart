import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'drag_container.dart';
import 'drag_notification.dart';

/// Represents an item in a [ReorderableStaggeredScrollView].
class ReorderableStaggeredScrollViewListItem {
  final Key key;
  final Widget widget;

  /// 可选业务数据，便于在回调中映射回 CardItem 等
  final Object? data;

  const ReorderableStaggeredScrollViewListItem({
    required this.key,
    required this.widget,
    this.data,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReorderableStaggeredScrollViewListItem &&
        key == other.key &&
        widget == other.widget;
  }

  @override
  int get hashCode => key.hashCode ^ widget.hashCode;
}

/// Represents an item in a grid layout within a [ReorderableStaggeredScrollView].
abstract class ReorderableStaggeredScrollViewGridItem
    extends ReorderableStaggeredScrollViewListItem {
  const ReorderableStaggeredScrollViewGridItem({
    required super.key,
    required super.widget,
    super.data,
  });

  num get mainAxisSize;
  int get crossAxisSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReorderableStaggeredScrollViewGridItem &&
        key == other.key &&
        mainAxisSize == other.mainAxisSize &&
        crossAxisSize == other.crossAxisSize &&
        widget == other.widget;
  }

  @override
  int get hashCode =>
      super.hashCode ^ mainAxisSize.hashCode ^ crossAxisSize.hashCode;
}

/// Represents an item in a grid layout within a [ReorderableStaggeredScrollView].
class ReorderableStaggeredScrollViewGridCountItem
    extends ReorderableStaggeredScrollViewGridItem {
  final int mainAxisCellCount;
  final int crossAxisCellCount;

  const ReorderableStaggeredScrollViewGridCountItem({
    required super.key,
    required this.mainAxisCellCount,
    required this.crossAxisCellCount,
    required super.widget,
    super.data,
  });

  @override
  int get crossAxisSize => crossAxisCellCount;

  @override
  int get mainAxisSize => mainAxisCellCount;
}

/// Represents an item in a grid layout within a [ReorderableStaggeredScrollView].
class ReorderableStaggeredScrollViewGridExtentItem
    extends ReorderableStaggeredScrollViewGridItem {
  final double mainAxisExtent;
  final int crossAxisCellCount;

  const ReorderableStaggeredScrollViewGridExtentItem({
    required super.key,
    required this.mainAxisExtent,
    required this.crossAxisCellCount,
    required super.widget,
    super.data,
  });

  @override
  int get crossAxisSize => crossAxisCellCount;

  @override
  double get mainAxisSize => mainAxisExtent;
}

/// A scrollable list or grid with reordering and drag-and-drop support.
///
/// 如需获取当前 dataList 顺序，可使用 GlobalKey:
/// ```dart
/// final _gridKey = GlobalKey<ReorderableStaggeredScrollViewState>();
/// 
/// ReorderableStaggeredScrollView.grid(
///   key: _gridKey,
///   ...
/// )
/// 
/// // 获取当前顺序
/// final dataList = _gridKey.currentState?.getCurrentDataList();
/// ```
class ReorderableStaggeredScrollView extends StatefulWidget {
  final bool enable;
  final bool isList;
  final List<ReorderableStaggeredScrollViewListItem> children;
  final bool isLongPressDraggable;
  final Widget Function(ReorderableStaggeredScrollViewListItem, Widget, Size)?
      buildFeedback;
  final Axis? axis;
  final void Function(ReorderableStaggeredScrollViewListItem?,
      ReorderableStaggeredScrollViewListItem, bool)? onAccept;
  final bool Function(ReorderableStaggeredScrollViewListItem?,
      ReorderableStaggeredScrollViewListItem, bool)? onWillAccept;
  final void Function(ReorderableStaggeredScrollViewListItem?,
      ReorderableStaggeredScrollViewListItem, bool)? onLeave;
  final void Function(ReorderableStaggeredScrollViewListItem,
      DragTargetDetails<ReorderableStaggeredScrollViewListItem>, bool)? onMove;
  final HitTestBehavior hitTestBehavior;
  final void Function(ReorderableStaggeredScrollViewListItem)? onDragStarted;
  final void Function(
      DragUpdateDetails, ReorderableStaggeredScrollViewListItem)? onDragUpdate;
  final void Function(Velocity, Offset, ReorderableStaggeredScrollViewListItem)?
      onDraggableCanceled;
  final void Function(
      DraggableDetails,
      ReorderableStaggeredScrollViewListItem,
      List<ReorderableStaggeredScrollViewListItem> orderedDataList)? onDragEnd;
  final void Function(ReorderableStaggeredScrollViewListItem)? onDragCompleted;
  /// 初始化完成时回调（首帧渲染后），参数为当前 dataList 顺序
  final void Function(
      List<ReorderableStaggeredScrollViewListItem> dataListOrder)? onCompleted;
  final ScrollController? scrollController;
  final bool isDragNotification;
  final double draggingWidgetOpacity;
  final double edgeScroll;
  final int edgeScrollSpeedMilliseconds;
  final List<ReorderableStaggeredScrollViewListItem>? isNotDragList;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final bool shrinkWrap;
  final int crossAxisCount;
  final AxisDirection? axisDirection;

  const ReorderableStaggeredScrollView.list({
    super.key,
    this.enable = true,
    required this.children,
    this.isLongPressDraggable = true,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.shrinkWrap = false,
    this.reverse = false,
    this.primary,
    this.physics,
    this.padding,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.buildFeedback,
    this.axis,
    this.onAccept,
    this.onWillAccept,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.onCompleted,
    this.scrollController,
    this.isDragNotification = false,
    this.draggingWidgetOpacity = 0.5,
    this.edgeScroll = 0.1,
    this.edgeScrollSpeedMilliseconds = 100,
    this.isNotDragList,
  })  : axisDirection = null,
        isList = true,
        crossAxisCount = 1;

  ReorderableStaggeredScrollView.grid({
    super.key,
    this.enable = true,
    required List<ReorderableStaggeredScrollViewGridItem> this.children,
    this.isLongPressDraggable = true,
    required this.crossAxisCount,
    this.axisDirection,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.padding,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.axis,
    this.hitTestBehavior = HitTestBehavior.translucent,
    Widget Function(ReorderableStaggeredScrollViewGridItem, Widget, Size)?
        buildFeedback,
    void Function(ReorderableStaggeredScrollViewGridItem?,
            ReorderableStaggeredScrollViewGridItem, bool)?
        onAccept,
    bool Function(ReorderableStaggeredScrollViewGridItem?,
            ReorderableStaggeredScrollViewGridItem, bool)?
        onWillAccept,
    void Function(ReorderableStaggeredScrollViewGridItem?,
            ReorderableStaggeredScrollViewGridItem, bool)?
        onLeave,
    void Function(ReorderableStaggeredScrollViewGridItem,
            DragTargetDetails<ReorderableStaggeredScrollViewGridItem>, bool)?
        onMove,
    void Function(ReorderableStaggeredScrollViewGridItem)? onDragStarted,
    void Function(DragUpdateDetails, ReorderableStaggeredScrollViewGridItem)?
        onDragUpdate,
    void Function(Velocity, Offset, ReorderableStaggeredScrollViewGridItem)?
        onDraggableCanceled,
    void Function(
            DraggableDetails,
            ReorderableStaggeredScrollViewGridItem,
            List<ReorderableStaggeredScrollViewListItem> orderedDataList)?
        onDragEnd,
    void Function(ReorderableStaggeredScrollViewGridItem)? onDragCompleted,
    void Function(
            List<ReorderableStaggeredScrollViewListItem> dataListOrder)?
        onCompleted,
    this.scrollController,
    this.isDragNotification = false,
    this.draggingWidgetOpacity = 0.5,
    this.edgeScroll = 0.1,
    this.edgeScrollSpeedMilliseconds = 100,
    List<ReorderableStaggeredScrollViewGridItem>? this.isNotDragList,
  })  : isList = false,
        onCompleted = onCompleted,
        shrinkWrap = false,
        buildFeedback = (buildFeedback == null
            ? null
            : (ReorderableStaggeredScrollViewListItem item, Widget widget,
                    Size size) =>
                buildFeedback(
                  item as ReorderableStaggeredScrollViewGridItem,
                  widget,
                  size,
                )),
        onAccept = (onAccept == null
            ? null
            : (ReorderableStaggeredScrollViewListItem? item1,
                    ReorderableStaggeredScrollViewListItem? item2,
                    bool value) =>
                onAccept(
                  item1 as ReorderableStaggeredScrollViewGridItem?,
                  item2 as ReorderableStaggeredScrollViewGridItem,
                  value,
                )),
        onLeave = (onLeave == null
            ? null
            : (ReorderableStaggeredScrollViewListItem? item1,
                    ReorderableStaggeredScrollViewListItem? item2,
                    bool value) =>
                onLeave(
                  item1 as ReorderableStaggeredScrollViewGridItem?,
                  item2 as ReorderableStaggeredScrollViewGridItem,
                  value,
                )),
        onWillAccept = (onWillAccept == null
            ? null
            : (ReorderableStaggeredScrollViewListItem? item1,
                    ReorderableStaggeredScrollViewListItem? item2,
                    bool value) =>
                onWillAccept(
                  item1 as ReorderableStaggeredScrollViewGridItem?,
                  item2 as ReorderableStaggeredScrollViewGridItem,
                  value,
                )),
        onMove = (onMove == null
            ? null
            : (ReorderableStaggeredScrollViewListItem item,
                    DragTargetDetails<ReorderableStaggeredScrollViewListItem>
                        details,
                    bool value) =>
                onMove(
                  item as ReorderableStaggeredScrollViewGridItem,
                  DragTargetDetails<ReorderableStaggeredScrollViewGridItem>(
                    data:
                        details.data as ReorderableStaggeredScrollViewGridItem,
                    offset: details.offset,
                  ),
                  value,
                )),
        onDragStarted = (onDragStarted == null
            ? null
            : (ReorderableStaggeredScrollViewListItem item) =>
                onDragStarted(item as ReorderableStaggeredScrollViewGridItem)),
        onDragUpdate = (onDragUpdate == null
            ? null
            : (DragUpdateDetails details,
                    ReorderableStaggeredScrollViewListItem item) =>
                onDragUpdate(
                  details,
                  item as ReorderableStaggeredScrollViewGridItem,
                )),
        onDraggableCanceled = (onDraggableCanceled == null
            ? null
            : (Velocity velocity, Offset offset,
                    ReorderableStaggeredScrollViewListItem item) =>
                onDraggableCanceled(
                  velocity,
                  offset,
                  item as ReorderableStaggeredScrollViewGridItem,
                )),
        onDragEnd = (onDragEnd == null
            ? null
            : (DraggableDetails details,
                    ReorderableStaggeredScrollViewListItem item,
                    List<ReorderableStaggeredScrollViewListItem> orderedDataList) =>
                onDragEnd(details, item as ReorderableStaggeredScrollViewGridItem,
                    orderedDataList)),
        onDragCompleted = (onDragCompleted == null
            ? null
            : (ReorderableStaggeredScrollViewListItem item) => onDragCompleted(
                item as ReorderableStaggeredScrollViewGridItem));

  @override
  State<ReorderableStaggeredScrollView> createState() =>
      _ReorderableStaggeredScrollViewState();
}

class _ReorderableStaggeredScrollViewState
    extends State<ReorderableStaggeredScrollView> {
  List<ReorderableStaggeredScrollViewListItem> _children = const [];

  @override
  void initState() {
    super.initState();
    _children = widget.children;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCompleted?.call(getCurrentDataList());
    });
  }

  /// 获取当前 dataList 的顺序（可能已被拖拽重排）
  List<ReorderableStaggeredScrollViewListItem> getCurrentDataList() {
    return List<ReorderableStaggeredScrollViewListItem>.from(_children);
  }

  Widget buildContainer({
    required Widget Function(List<Widget>) buildItems,
  }) {
    return DragContainer(
      isDrag: widget.enable,
      scrollDirection: widget.scrollDirection,
      isLongPressDraggable: widget.isLongPressDraggable,
      buildItems: buildItems,
      buildFeedback: widget.buildFeedback,
      axis: widget.axis,
      onAccept: widget.onAccept,
      onWillAccept: widget.onWillAccept,
      onLeave: widget.onLeave,
      onMove: widget.onMove,
      hitTestBehavior: widget.hitTestBehavior,
      onDragStarted: widget.onDragStarted,
      onDragUpdate: widget.onDragUpdate,
      onDraggableCanceled: widget.onDraggableCanceled,
      onDragEnd: widget.onDragEnd,
      onDragCompleted: widget.onDragCompleted,
      scrollController: widget.scrollController,
      isDragNotification: widget.isDragNotification,
      draggingWidgetOpacity: widget.draggingWidgetOpacity,
      edgeScroll: widget.edgeScroll,
      edgeScrollSpeedMilliseconds: widget.edgeScrollSpeedMilliseconds,
      isNotDragList: widget.isNotDragList,
      items: (ReorderableStaggeredScrollViewListItem element,
          DraggableWidget draggableWidget) {
        if (widget.isList) {
          return Container(
            key: ValueKey(element.key.toString()),
            child: draggableWidget(element.widget),
          );
        }

        if (element is ReorderableStaggeredScrollViewGridCountItem) {
          return StaggeredGridTile.count(
            key: ValueKey(element.key.toString()),
            mainAxisCellCount: element.mainAxisCellCount,
            crossAxisCellCount: element.crossAxisCellCount,
            child: draggableWidget(element.widget),
          );
        } else if (element is ReorderableStaggeredScrollViewGridExtentItem) {
          return StaggeredGridTile.extent(
            key: ValueKey(element.key.toString()),
            mainAxisExtent: element.mainAxisExtent,
            crossAxisCellCount: element.crossAxisCellCount,
            child: draggableWidget(element.widget),
          );
        } else {
          throw FlutterError(
            "Item should be one of ReorderableStaggeredScrollViewGridItem or ReorderableStaggeredScrollViewGridExtentItem but it was ${element.runtimeType}",
          );
        }
      },
      dataList: _children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragNotification(
      child: (widget.isList
          ? SingleChildScrollView(
              scrollDirection: widget.scrollDirection,
              physics: widget.physics,
              child: buildContainer(
                buildItems: (List<Widget> children) {
                  return ListView(
                    scrollDirection: widget.scrollDirection,
                    reverse: widget.reverse,
                    controller: widget.controller,
                    primary: widget.primary,
                    physics: widget.physics,
                    shrinkWrap: widget.shrinkWrap,
                    padding: widget.padding,
                    dragStartBehavior: widget.dragStartBehavior,
                    keyboardDismissBehavior: widget.keyboardDismissBehavior,
                    restorationId: widget.restorationId,
                    clipBehavior: widget.clipBehavior,
                    children: children,
                  );
                },
              ),
            )
          : SingleChildScrollView(
              scrollDirection: widget.scrollDirection,
              reverse: widget.reverse,
              controller: widget.controller,
              primary: widget.primary,
              physics: widget.physics,
              padding: widget.padding,
              dragStartBehavior: widget.dragStartBehavior,
              keyboardDismissBehavior: widget.keyboardDismissBehavior,
              restorationId: widget.restorationId,
              clipBehavior: widget.clipBehavior,
              child: buildContainer(
                buildItems: (List<Widget> children) {
                  return StaggeredGrid.count(
                    crossAxisCount: widget.crossAxisCount,
                    axisDirection: widget.axisDirection,
                    children: children,
                  );
                },
              ),
            )),
    );
  }
}
