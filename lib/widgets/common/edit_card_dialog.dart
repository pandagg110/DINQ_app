import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../cards/factory/card_registry.dart';
import 'add_card_forms/title_edit_form.dart';

/// 编辑卡片底部框：效果与添加弹框一致，先支持 TITLE 编辑；其他类型暂不操作。
class EditCardDialog {
  /// 以底部弹框形式弹出编辑表单。仅 TITLE 类型会打开弹框，其他类型直接返回。
  static Future<void> show({
    required BuildContext context,
    required CardItem card,
  }) {
    if (card.data.type.toUpperCase() != 'TITLE') return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _EditCardBottomSheet(card: card);
      },
    );
  }
}

class _EditCardBottomSheet extends StatefulWidget {
  const _EditCardBottomSheet({required this.card});

  final CardItem card;

  @override
  State<_EditCardBottomSheet> createState() => _EditCardBottomSheetState();
}

class _EditCardBottomSheetState extends State<_EditCardBottomSheet> {
  late final TextEditingController _controller;
  late final TitleEditForm _form;

  bool _shouldLiftForKeyboard = false;
  bool _keyboardAlreadyActive = false;
  double? _safeAreaBottom;
  double _lastKeyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.card.data.metadata['title']?.toString() ?? '';
    _controller = TextEditingController(text: initialTitle);
    _form = TitleEditForm(controller: _controller, currentData: widget.card.data);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measureAndUpdateLift() {
    if (!mounted) return;
    final mq = MediaQuery.of(context);
    if (mq.viewInsets.bottom == 0) return;
    final focusNode = FocusManager.instance.primaryFocus;
    bool shouldLift = false;
    if (focusNode != null && focusNode.context != null) {
      final box = focusNode.context!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final distanceToBottom = screenHeight - (pos.dy + box.size.height);
        shouldLift = distanceToBottom < 300;
      }
    }
    if (shouldLift != _shouldLiftForKeyboard) {
      setState(() => _shouldLiftForKeyboard = shouldLift);
    }
  }

  Future<void> _onSave() async {
    final formData = await _form.getFormData();
    if (formData == null || !mounted) return;
    final cardStore = context.read<CardStore>();
    cardStore.updateCardData(widget.card.id, CardData.fromJson(formData));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _safeAreaBottom ??= MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = _safeAreaBottom!;
    final mq = MediaQuery.of(context);
    final currentKeyboardHeight = mq.viewInsets.bottom;
    if (_lastKeyboardHeight > 0 && currentKeyboardHeight == 0) {
      _keyboardAlreadyActive = false;
      _shouldLiftForKeyboard = false;
    }
    _lastKeyboardHeight = currentKeyboardHeight;
    if (currentKeyboardHeight > 0 && !_keyboardAlreadyActive) {
      _keyboardAlreadyActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndUpdateLift());
    }
    final bottomInset = _shouldLiftForKeyboard ? mq.viewInsets.bottom : 0.0;

    final definition = CardRegistry().getDefinition('TITLE');
    if (definition == null) return const SizedBox.shrink();

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
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + safeAreaBottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Title Card',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _onSave,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Save',
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
              _form.build(context, definition),
            ],
          ),
        ),
      ),
    );
  }
}
