import 'package:flutter/material.dart';

class RenderBoxSize extends StatefulWidget {
  const RenderBoxSize(this.child, this.onChangeSize, {super.key});

  final Widget child;
  final void Function(Size size) onChangeSize;

  @override
  State<StatefulWidget> createState() => RenderBoxSizeState();
}

class RenderBoxSizeState extends State<RenderBoxSize> {
  void onChangeSize() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widget.onChangeSize(renderBox.size);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      onChangeSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (SizeChangedLayoutNotification notification) {
          onChangeSize();
          return true;
        },
        child: widget.child);
  }
}
