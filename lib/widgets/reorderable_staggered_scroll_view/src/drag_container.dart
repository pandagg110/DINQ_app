import 'dart:async';

import 'package:flutter/material.dart';

import 'drag_item.dart';
import 'drag_notification.dart';
import 'render_box_size.dart';
import 'reorderable_staggered_scroll_view.dart';

typedef DraggableWidget = Widget Function(Widget child);
typedef DragTargetOn<T> = Widget Function(T? moveData, T data);

/// A widget that allows for drag-and-drop functionality within a list of items.
///
/// The [DragContainer] widget is designed to manage drag-and-drop interactions
/// between a list of items and provide callbacks for various drag-related events.
class DragContainer<T extends ReorderableStaggeredScrollViewListItem>
    extends StatefulWidget {
  final Widget Function(List<Widget> children) buildItems;
  final Widget Function(T data, DraggableWidget draggableWidget) items;
  final List<T> dataList;
  final Widget Function(T data, Widget child, Size size)? buildFeedback;
  final bool isLongPressDraggable;
  final Axis? axis;
  final void Function(T? moveData, T data, bool isFront)? onAccept;
  final bool Function(T? moveData, T data, bool isFront)? onWillAccept;
  final void Function(T? moveData, T data, bool isFront)? onLeave;
  final void Function(T data, DragTargetDetails<T> details, bool isFront)?
  onMove;
  final Axis scrollDirection;
  final HitTestBehavior hitTestBehavior;
  final void Function(T data)? onDragStarted;
  final void Function(DragUpdateDetails details, T data)? onDragUpdate;
  final void Function(Velocity velocity, Offset offset, T data)?
  onDraggableCanceled;
  final void Function(
    DraggableDetails details,
    T data,
    List<T> orderedDataList,
  )?
  onDragEnd;
  final void Function(T data)? onDragCompleted;
  final ScrollController? scrollController;
  final bool isDragNotification;
  final double draggingWidgetOpacity;
  final double edgeScroll;
  final int edgeScrollSpeedMilliseconds;
  final bool isDrag;
  final List<T>? isNotDragList;

  const DragContainer({
    required this.buildItems,
    required this.dataList,
    required this.items,
    this.isLongPressDraggable = true,
    this.buildFeedback,
    this.axis,
    this.onAccept,
    this.onWillAccept,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
    this.scrollDirection = Axis.vertical,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.scrollController,
    this.isDragNotification = false,
    this.draggingWidgetOpacity = 0.5,
    this.edgeScroll = 0.1,
    this.edgeScrollSpeedMilliseconds = 100,
    this.isDrag = true,
    this.isNotDragList,
    super.key,
  });

  @override
  State<DragContainer> createState() => _DragContainerState();
}

class _DragContainerState<T extends ReorderableStaggeredScrollViewListItem>
    extends State<DragContainer> {
  Timer? _timer;
  Timer? _scrollableTimer;
  ScrollableState? _scrollable;
  AnimationStatus status = AnimationStatus.completed;
  bool isDragStart = false;
  T? dragData;
  Map<T, Size> mapSize = <T, Size>{};

  void endWillAccept() {
    _timer?.cancel();
  }

  List<T> _getOrderedDataList() {
    return List<T>.from(widget.dataList);
  }

  void _debugPrintDataList(T draggedData) {
    final list = widget.dataList;
    final buf = StringBuffer(
      'onDragEnd dataList(dragged=${_keyValue(draggedData.key)}):\n',
    );
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final keyVal = _keyValue(item.key);
      final sizeStr = item is ReorderableStaggeredScrollViewGridCountItem
          ? '${item.mainAxisCellCount}x${item.crossAxisCellCount}'
          : (item is ReorderableStaggeredScrollViewGridExtentItem
                ? '${item.mainAxisExtent}x${item.crossAxisCellCount}'
                : '-');
      final dataStr = _formatData(item.data);
      buf.writeln('  [$i] key=$keyVal size=$sizeStr$dataStr');
    }
  }

  static String _formatData(Object? d) {
    if (d == null) return '';
    try {
      final dynamic obj = d;
      final id = obj.id;
      final type = obj.data?.type ?? obj.type;
      if (id != null) return ' data=id=$id type=$type';
    } catch (_) {}
    return ' data=$d';
  }

  static String _keyValue(Key key) {
    if (key is ValueKey<Object?>) return '${key.value}';
    return key.toString();
  }

  void setDragStart({bool isDragStart = true}) {
    if (this.isDragStart != isDragStart) {
      setState(() {
        this.isDragStart = isDragStart;
        if (!this.isDragStart) {
          dragData = null;
        } else {
          endWillAccept();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.dataList.map((e) => setDraggable(e as T)).toList();
    if (widget.isDragNotification) {
      return DragNotification(child: widget.buildItems(items));
    } else {
      return widget.buildItems(items);
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<T> delete = <T>[];
    mapSize.forEach((T key, Size value) {
      if (!widget.dataList.contains(key)) {
        delete.add(key);
      }
    });
    mapSize.removeWhere((T key, Size value) => delete.contains(key));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.scrollController == null) {
      try {
        _scrollable = Scrollable.of(context);
      } catch (e, s) {}
    }
  }

  void _reorderDataList(T moveData, T data, bool isFront) {
    if (moveData == data) return;
    final int index = widget.dataList.indexOf(data);
    if (index < 0) return;
    widget.dataList.remove(moveData);
    if (isFront) {
      widget.dataList.insert(index, moveData);
    } else {
      final insertIdx = index + 1 < widget.dataList.length ? index + 1 : index;
      widget.dataList.insert(insertIdx, moveData);
    }
  }

  void setWillAccept(T? moveData, T data, {bool isFront = true}) {
    if (moveData == data) {
      return;
    }
    if (status == AnimationStatus.completed) {
      endWillAccept();
      _timer = Timer(const Duration(milliseconds: 200), () {
        if (!DragNotification.isScroll) {
          if (widget.onWillAccept != null) {
            widget.onWillAccept?.call(moveData, data, isFront);
          } else if (moveData != null) {
            setState(() => _reorderDataList(moveData, data, isFront));
          }
        }
      });
    }
  }

  bool isContains(T data) {
    if (widget.isNotDragList?.toList() != null) {
      return widget.isNotDragList!.toList().contains(data);
    }
    return false;
  }

  Size getRenderBoxSize(T? date) {
    return mapSize[date] ?? Size.zero;
  }

  Widget getSizedBox(T data, Widget child) {
    final Size size = getRenderBoxSize(data);
    return SizedBox(
      width: size.width / (widget.scrollDirection == Axis.horizontal ? 2 : 1),
      height: size.height / (widget.scrollDirection == Axis.vertical ? 2 : 1),
      child: child,
    );
  }

  Widget setDragScope(T data, Widget child) {
    final Widget keyWidget = child;
    return DragItem(
      child: Stack(
        children: <Widget>[
          if (isDragStart &&
              dragData == data &&
              widget.draggingWidgetOpacity > 0)
            AnimatedOpacity(
              opacity: widget.draggingWidgetOpacity,
              duration: const Duration(milliseconds: 300),
              child: keyWidget,
            )
          else
            Visibility(
              maintainState: true,
              visible: dragData != data,
              child: keyWidget,
            ),
          if (isDragStart && !isContains(data))
            Flex(
              direction: widget.scrollDirection,
              children: <Widget>[
                getSizedBox(
                  data,
                  DragTarget<T>(
                    onWillAcceptWithDetails: (DragTargetDetails<T> details) {
                      setWillAccept(details.data, data);
                      return true;
                    },
                    onAcceptWithDetails: widget.onAccept == null
                        ? null
                        : (DragTargetDetails<T> details) {
                            _reorderDataList(details.data, data, true);
                            widget.onAccept?.call(details.data, data, true);
                          },
                    onLeave: widget.onLeave == null
                        ? null
                        : (T? moveData) =>
                              widget.onLeave?.call(moveData, data, true),
                    onMove: widget.onMove == null
                        ? null
                        : (DragTargetDetails<T> details) =>
                              widget.onMove?.call(data, details, true),
                    hitTestBehavior: widget.hitTestBehavior,
                    builder:
                        (
                          BuildContext context,
                          List<T?> candidateData,
                          List<dynamic> rejectedData,
                        ) {
                          return Container(color: Colors.transparent);
                        },
                  ),
                ),
                getSizedBox(
                  data,
                  DragTarget<T>(
                    onWillAcceptWithDetails: (DragTargetDetails<T> details) {
                      setWillAccept(details.data, data, isFront: false);
                      return true;
                    },
                    onAcceptWithDetails: widget.onAccept == null
                        ? null
                        : (DragTargetDetails<T> details) {
                            _reorderDataList(details.data, data, false);
                            widget.onAccept?.call(details.data, data, false);
                          },
                    onLeave: widget.onLeave == null
                        ? null
                        : (T? moveData) =>
                              widget.onLeave?.call(moveData, data, false),
                    onMove: widget.onMove == null
                        ? null
                        : (DragTargetDetails<T> details) =>
                              widget.onMove?.call(data, details, false),
                    hitTestBehavior: widget.hitTestBehavior,
                    builder:
                        (
                          BuildContext context,
                          List<T?> candidateData,
                          List<dynamic> rejectedData,
                        ) {
                          return Container(color: Colors.transparent);
                        },
                  ),
                ),
              ],
            ),
        ],
      ),
      onAnimationStatus: (AnimationStatus status) => this.status = status,
    );
  }

  Widget setDraggable(T data) {
    final Widget draggable = widget.items(data, (Widget father) {
      Widget child = setDragScope(data, father);
      if (widget.isDrag && !isContains(data)) {
        if (widget.isLongPressDraggable) {
          child = LongPressDraggable<T>(
            feedback: setFeedback(data, father),
            axis: widget.axis,
            data: data,
            onDragStarted: () {
              dragData = data;
              setDragStart();
              widget.onDragStarted?.call(data);
            },
            onDragUpdate: (DragUpdateDetails details) {
              _autoScrollIfNecessary(details.globalPosition, father);
              widget.onDragUpdate?.call(details, data);
            },
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              setDragStart(isDragStart: false);
              endAnimation();
              widget.onDraggableCanceled?.call(velocity, offset, data);
            },
            onDragEnd: (details) {
              setDragStart(isDragStart: false);
              _debugPrintDataList(data);
              widget.onDragEnd?.call(details, data, _getOrderedDataList());
            },
            onDragCompleted: () {
              setDragStart(isDragStart: false);
              endAnimation();
              widget.onDragCompleted?.call(data);
            },
            child: child,
          );
        } else {
          child = Draggable<T>(
            feedback: setFeedback(data, father),
            axis: widget.axis,
            data: data,
            onDragStarted: () {
              dragData = data;
              setDragStart();
              widget.onDragStarted?.call(data);
            },
            onDragUpdate: (DragUpdateDetails details) {
              _autoScrollIfNecessary(details.globalPosition, father);
              widget.onDragUpdate?.call(details, data);
            },
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              setDragStart(isDragStart: false);
              endAnimation();
              widget.onDraggableCanceled?.call(velocity, offset, data);
            },
            onDragEnd: (DraggableDetails details) {
              setDragStart(isDragStart: false);
              _debugPrintDataList(data);
              widget.onDragEnd?.call(details, data, _getOrderedDataList());
            },
            onDragCompleted: () {
              setDragStart(isDragStart: false);
              endAnimation();
              widget.onDragCompleted?.call(data);
            },
            child: child,
          );
        }
      }
      return child;
    });
    return RenderBoxSize(draggable, (Size size) {
      mapSize[data] = size;
      if (mapSize.length == widget.dataList.length) {
        setState(() {});
      }
    }, key: ValueKey<T>(data));
  }

  Widget setFeedback(T data, Widget e) {
    final Size size = getRenderBoxSize(data);
    final Widget child = SizedBox(
      width: size.width,
      height: size.height,
      child: e,
    );
    return widget.buildFeedback?.call(data, child, size) ?? child;
  }

  void _autoScrollIfNecessary(Offset details, Widget father) {
    if (status != AnimationStatus.completed) {
      return;
    }
    if (_scrollable == null && widget.scrollController == null) {
      return;
    }
    final RenderBox scrollRenderBox;
    if (_scrollable != null) {
      scrollRenderBox = _scrollable!.context.findRenderObject()! as RenderBox;
    } else {
      scrollRenderBox = context.findRenderObject()! as RenderBox;
    }
    final Offset scrollOrigin = scrollRenderBox.localToGlobal(Offset.zero);
    final double scrollStart = _offsetExtent(
      scrollOrigin,
      widget.scrollDirection,
    );
    final double scrollEnd =
        scrollStart + _sizeExtent(scrollRenderBox.size, widget.scrollDirection);
    final double currentOffset = _offsetExtent(details, widget.scrollDirection);
    final double mediaQuery =
        _sizeExtent(MediaQuery.of(context).size, widget.scrollDirection) *
        widget.edgeScroll;
    if (currentOffset < (scrollStart + mediaQuery)) {
      animateTo(mediaQuery, isNext: false);
    } else if (currentOffset > (scrollEnd - mediaQuery)) {
      animateTo(mediaQuery);
    } else {
      endAnimation();
    }
  }

  void animateTo(double mediaQuery, {bool isNext = true}) {
    final ScrollPosition position =
        _scrollable?.position ?? widget.scrollController!.position;
    endAnimation();
    if (isNext && position.pixels >= position.maxScrollExtent) {
      return;
    } else if (!isNext && position.pixels <= position.minScrollExtent) {
      return;
    }
    DragNotification.isScroll = true;
    _scrollableTimer = Timer.periodic(
      Duration(milliseconds: widget.edgeScrollSpeedMilliseconds),
      (Timer timer) {
        if (isNext && position.pixels >= position.maxScrollExtent) {
          endAnimation();
        } else if (!isNext && position.pixels <= position.minScrollExtent) {
          endAnimation();
        } else {
          endWillAccept();
          position.animateTo(
            position.pixels + (isNext ? mediaQuery : -mediaQuery),
            duration: Duration(
              milliseconds: widget.edgeScrollSpeedMilliseconds,
            ),
            curve: Curves.linear,
          );
        }
      },
    );
  }

  void endAnimation() {
    DragNotification.isScroll = false;
    _scrollableTimer?.cancel();
  }

  double _offsetExtent(Offset offset, Axis scrollDirection) {
    switch (scrollDirection) {
      case Axis.horizontal:
        return offset.dx;
      case Axis.vertical:
        return offset.dy;
    }
  }

  double _sizeExtent(Size size, Axis scrollDirection) {
    switch (scrollDirection) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  @override
  void dispose() {
    endWillAccept();
    endAnimation();
    super.dispose();
  }
}
