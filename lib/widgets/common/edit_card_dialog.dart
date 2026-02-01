import 'package:flutter/material.dart';
import '../../models/card_models.dart';
import 'add_card_forms/network_edit_form.dart';
import 'add_card_forms/note_edit_form.dart';
import 'add_card_forms/title_edit_form.dart';

/// 编辑卡片底部弹框：TITLE / ACHIEVEMENT_NETWORK 及后续扩展类型统一使用。
class EditCardDialog {
  static final _handlers = <String, CardEditHandler>{
    'NOTE': CardEditHandler(
      title: 'Edit Note',
      useScrollableLayout: true,
      buildContent: _buildNoteContent,
    ),
    'TITLE': CardEditHandler(
      title: 'Edit Title Card',
      useScrollableLayout: true,
      buildContent: _buildTitleContent,
    ),
    'ACHIEVEMENT_NETWORK': CardEditHandler(
      title: 'Edit Network',
      useScrollableLayout: false,
      buildContent: _buildNetworkContent,
    ),
    
  };

  /// 注册新的编辑类型，扩展时调用
  static void register(String type, CardEditHandler handler) {
    _handlers[type.toUpperCase()] = handler;
  }

  /// 是否支持该类型
  static bool supports(String type) {
    final key = type.trim().toUpperCase();
    return key.isNotEmpty && _handlers.containsKey(key);
  }

  /// 已注册的卡片类型（调试用）
  static Set<String> get supportedTypes => _handlers.keys.toSet();

  /// 根据卡片类型弹出对应编辑表单
  static Future<void> show({
    required BuildContext context,
    required CardItem card,
  }) {
    final type = card.data.type.trim().toUpperCase();
    final handler = _handlers[type];
    if (handler == null) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditCardBottomSheet(card: card, handler: handler),
    );
  }
}

/// 卡片编辑处理器，扩展新类型时实现此接口并 register
class CardEditHandler {
  const CardEditHandler({
    required this.title,
    required this.useScrollableLayout,
    required this.buildContent,
  });

  final String title;
  /// true: 简单表单，SingleChildScrollView 布局；false: 复杂表单，maxHeight + Flexible
  final bool useScrollableLayout;
  final Widget Function(
    BuildContext context,
    CardItem card,
    void Function(Future<void> Function() save) onSaveReady,
  ) buildContent;
}

Widget _buildTitleContent(
  BuildContext context,
  CardItem card,
  void Function(Future<void> Function() save) onSaveReady,
) {
  return TitleEditFormWithSave(card: card, onSaveReady: onSaveReady);
}

Widget _buildNetworkContent(
  BuildContext context,
  CardItem card,
  void Function(Future<void> Function() save) onSaveReady,
) {
  return NetworkEditFormWithSave(card: card, onSaveReady: onSaveReady);
}

Widget _buildNoteContent(
  BuildContext context,
  CardItem card,
  void Function(Future<void> Function() save) onSaveReady,
) {
  return NoteEditFormWithSave(card: card, onSaveReady: onSaveReady);
}

class _EditCardBottomSheet extends StatefulWidget {
  const _EditCardBottomSheet({
    required this.card,
    required this.handler,
  });

  final CardItem card;
  final CardEditHandler handler;

  @override
  State<_EditCardBottomSheet> createState() => _EditCardBottomSheetState();
}

class _EditCardBottomSheetState extends State<_EditCardBottomSheet> {
  Future<void> Function()? _saveFn;

  bool _shouldLiftForKeyboard = false;
  bool _keyboardAlreadyActive = false;
  double? _safeAreaBottom;
  double _lastKeyboardHeight = 0.0;

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

    final body = widget.handler.buildContent(
      context,
      widget.card,
      (save) => _saveFn = save,
    );

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
        constraints: widget.handler.useScrollableLayout
            ? null
            : BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: widget.handler.useScrollableLayout
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    body,
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Flexible(child: body),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.handler.title,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),
        TextButton(
          onPressed: () => _saveFn?.call(),
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
    );
  }
}
