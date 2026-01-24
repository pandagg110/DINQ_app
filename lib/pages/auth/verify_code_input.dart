import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerificationCodeInputController extends ChangeNotifier {
  late final TextEditingController tfController = TextEditingController();
  late final FocusNode focusNode = FocusNode();

  String _code = "";

  String get code => _code;

  set code(String value) {
    _code = value;
    notifyListeners();
  }

  void clear() {
    tfController.clear();
    code = "";
  }

  void requestFocus() {
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    tfController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}

class VerificationCodeInput extends StatefulWidget {
  final VerificationCodeInputController controller;
  final int maxLength;
  final ValueChanged<String> valueChanged;

  const VerificationCodeInput({
    super.key,
    required this.controller,
    this.maxLength = 6,
    required this.valueChanged,
  });

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  @override
  void initState() {
    super.initState();

    // 初始化时请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 监听 controller 变化
      widget.controller.addListener(_onControllerChanged);
      // 监听焦点变化，用于更新光标显示
      widget.controller.focusNode.addListener(_onFocusChanged);
      widget.controller.requestFocus();
    });
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: 0,
          height: 0,
          child: Visibility(
            visible: false,
            child: TextField(
              controller: widget.controller.tfController,
              focusNode: widget.controller.focusNode,
              maxLength: widget.maxLength,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                counterText: "",
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onChanged: (text) {
                widget.controller.code = text;
                widget.valueChanged(widget.controller.code);
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.maxLength, (i) => _buildInputBox(i)),
        ),
      ],
    );
  }

  Widget _buildInputBox(int index) {
    final controller = widget.controller;
    return GestureDetector(
      onTap: () {
        controller.focusNode.requestFocus();
        controller.tfController.value = TextEditingValue(
          text: controller.code,
          selection: TextSelection.collapsed(offset: controller.code.length),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 50, maxHeight: 50),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: controller.code.length == index ? ColorUtil.mainColor : Color(0xFFD8D8D8),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: Colors.white,
                cursorColor: ColorUtil.textColor,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  index < controller.code.length ? controller.code[index] : "",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                  ),
                ),
                if (index == controller.code.length && controller.focusNode.hasFocus)
                  Container(width: 2, height: 20, color: ColorUtil.mainColor)
                      .animate(onPlay: (c) => c.repeat())
                      .fade(delay: 500.ms, duration: const Duration(milliseconds: 150))
                      .then(delay: 500.ms)
                      .fadeOut(duration: const Duration(milliseconds: 150)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
