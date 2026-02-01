import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/card_store.dart';
import '../cards/factory/card_definition.dart';
import 'add_card_forms/form_factory.dart';
import 'add_card_forms/card_form_base.dart';
import 'form_builder_widget.dart';

/// 添加卡片底部框：底部弹出，标题 + Add 按钮，输入行（图标 + URL/用户名输入框）。
class AddCardDialog {
  /// 以底部弹框形式弹出 Add Card。
  /// [definition] 卡片定义，含 type、name、icon 等。
  /// 返回 [true] 表示用户点击 Add，[false] 或 [null] 表示关闭。
  static Future<bool?> show({
    required BuildContext context,
    required CardDefinition definition,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _AddCardBottomSheet(definition: definition);
      },
    );
  }
}

class _AddCardBottomSheet extends StatefulWidget {
  const _AddCardBottomSheet({required this.definition});

  final CardDefinition definition;

  @override
  State<_AddCardBottomSheet> createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<_AddCardBottomSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final GlobalKey<State<FormBuilderWidget>> _markdownFormKey = GlobalKey<State<FormBuilderWidget>>();
  late final CardFormBase _form;
  
  /// 键盘是否遮挡当前输入框；为 true 时顶起整个弹框，否则不顶起、让键盘覆盖下方内容
  /// 默认 false：键盘刚弹出时先不顶起，等测量完成后再决定，避免“先顶起再回滚”的闪烁
  bool _shouldLiftForKeyboard = false;
  /// 键盘是否已处于激活状态（仅在其刚弹出时判断一次，避免重复判断导致闪烁）
  bool _keyboardAlreadyActive = false;
  /// 安全区域底部高度，仅在第一次初始化时设置
  double? _safeAreaBottom;
  /// 上一次的键盘高度，用于检测键盘关闭事件
  double _lastKeyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _form = CardFormFactory.createForm(
      type: widget.definition.type,
      controller: _controller,
      focusNode: _focusNode,
      markdownFormKey: _markdownFormKey,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _measureAndUpdateLift() {
    if (!mounted) return;
    final mq = MediaQuery.of(context);
    if (mq.viewInsets.bottom == 0) {
      // 键盘已关闭，状态已在 build 中重置，这里直接返回
      return;
    }
    final focusNode = FocusManager.instance.primaryFocus;
    bool shouldLift = false; // 默认不顶起，仅当输入框距底部 < 300 时才顶起
    if (focusNode != null && focusNode.context != null) {
      final box = focusNode.context!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        // 计算输入框底部距离屏幕底部的距离
        final distanceToBottom = screenHeight - (pos.dy + box.size.height);
        // 如果距离底部小于300，则顶起弹框
        shouldLift = distanceToBottom < 300;
      }
    }
    if (shouldLift != _shouldLiftForKeyboard) {
      setState(() => _shouldLiftForKeyboard = shouldLift);
    }
  }

  Future<void> _onAdd() async {
    final formData = await _form.getFormData();
    if (formData == null || !mounted) return;
    final cardStore = context.read<CardStore>();
    await cardStore.addCard(
      type: widget.definition.type,
      metadata: formData,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final mq = MediaQuery.of(context);
    // 仅在第一次初始化时设置 safeAreaBottom
    _safeAreaBottom ??= mq.padding.bottom;
    final safeAreaBottom = _safeAreaBottom!;
    
    // 检测键盘关闭事件：从 > 0 变为 0
    final currentKeyboardHeight = mq.viewInsets.bottom;
    if (_lastKeyboardHeight > 0 && currentKeyboardHeight == 0) {
      // 键盘刚刚关闭，重置状态
      _keyboardAlreadyActive = false;
      _shouldLiftForKeyboard = false;
    }
    _lastKeyboardHeight = currentKeyboardHeight;
    
    if (currentKeyboardHeight > 0) {
      if (!_keyboardAlreadyActive) {
        _keyboardAlreadyActive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndUpdateLift());
      }
    }
    // 仅用 padding 控制是否顶起，不移除 viewInsets，否则子树会认为键盘已关闭导致键盘被收起
    final bottomInset = _shouldLiftForKeyboard ? mq.viewInsets.bottom : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + safeAreaBottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${def.name} Card',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _onAdd,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _form.build(context, def),
            ],
          ),
        ),
      ),
    );
  }
}
