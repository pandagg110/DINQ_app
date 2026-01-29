import 'package:flutter/material.dart';
import '../cards/factory/card_definition.dart';
import 'asset_icon.dart';
import '../../utils/icon_mapping.dart' as icon_mapping;

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _placeholder {
    final n = widget.definition.name;
    final t = widget.definition.type.toUpperCase();
    if (t == 'LINKEDIN') return 'linkedin.com/in/username';
    return 'Input URL for $n';
  }

  void _onAdd() {
    final value = _controller.text.trim();
    // TODO: 校验、调用 addCard(type, { url: value }) 等；当前仅关闭并返回 true
    debugPrint('AddCardDialog Add: ${widget.definition.type} -> $value');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
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
          20 + mq.padding.bottom,
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题行：左侧标题，右侧 Add 按钮
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
          // 输入行：图标 + 输入框
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIcon(def),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _placeholder,
                    hintStyle: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildIcon(CardDefinition def) {
    final icon = def.icon;
    if (icon.startsWith('i-lucide-') || icon.startsWith('i-mdi:')) {
      return _iconFallback(def.type);
    }
    final asset = icon.startsWith('/') ? icon.substring(1) : icon;
    String finalAsset = asset;
    if (asset.contains('icons/social-icons/')) {
      finalAsset = icon_mapping.mapSvgToPng(asset);
    }
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AssetIcon(asset: finalAsset, size: 28),
    );
  }

  Widget _iconFallback(String type) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.link, size: 24, color: Colors.grey.shade700),
    );
  }
}
