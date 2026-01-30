import 'package:flutter/material.dart';
import '../cards/factory/card_definition.dart';
import 'asset_icon.dart';
import '../../utils/icon_mapping.dart' as icon_mapping;
import 'form_builder_widget.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

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
  final GlobalKey<FormBuilderState> _markdownFormKey = GlobalKey<FormBuilderState>();

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
    final typeUpper = widget.definition.type.toUpperCase();
    
    // 如果是 MARKDOWN 类型，使用表单数据
    if (typeUpper == 'MARKDOWN') {
      if (_markdownFormKey.currentState?.saveAndValidate() ?? false) {
        final formData = _markdownFormKey.currentState!.value;
        debugPrint('AddCardDialog Add: ${widget.definition.type} -> $formData');
        Navigator.of(context).pop(true);
      }
    } else {
      // 其他类型使用简单的文本输入
      final value = _controller.text.trim();
      debugPrint('AddCardDialog Add: ${widget.definition.type} -> $value');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final type = def.type;
    final mq = MediaQuery.of(context);
    final typeUpper = type.toUpperCase();
    
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
            // 根据类型渲染不同的表单
            if (typeUpper == 'LINK')
              _buildLinkForm(def)
            else if (typeUpper == 'MARKDOWN')
              _buildMarkdownForm(def)
            else
              _buildNonLinkForm(def),
          ],
        ),
      ),
    );
  }

  /// 构建 Link 类型的表单（简单 URL 输入）
  Widget _buildLinkForm(CardDefinition def) {
    return Row(
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
    );
  }

  /// 构建 Markdown 类型的表单（使用 FormBuilderWidget）
  Widget _buildMarkdownForm(CardDefinition def) {
    return FormBuilderWidget(
      formKey: _markdownFormKey,
      fields: [
        // Type 字段（只读显示）
        FormFieldConfig(
          name: 'type',
          label: 'Type',
          type: FormFieldType.custom,
          initialValue: 'paper',
          customBuilder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
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
                errorText: field.errorText,
              ),
              child: Text(
                field.value?.toString() ?? 'paper',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: Color(0xFF171717),
                ),
              ),
            );
          },
        ),
        // Conference/Label 字段
        const FormFieldConfig(
          name: 'tag',
          label: 'Conference/Label',
          type: FormFieldType.input,
          hintText: 'Conference / Tag',
        ),
        // Content (Markdown) 字段
        const FormFieldConfig(
          name: 'content',
          label: 'Content (Markdown)',
          type: FormFieldType.texture,
          hintText: 'Enter content in Markdown format',
          minLines: 5,
          maxLines: 10,
        ),
        // Link URL 字段
        const FormFieldConfig(
          name: 'url',
          label: 'Link URL',
          type: FormFieldType.input,
          hintText: 'https://example.com',
        ),
        // Upload image 字段
        FormFieldConfig(
          name: 'image',
          label: 'Upload image',
          type: FormFieldType.image,
          imageConfig: const ImageUploadConfig(
            allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
            maxFileSize: 10 * 1024 * 1024, // 10MB
            showPreview: true,
            previewSize: 120,
            uploadHint: '支持 JPG、PNG、GIF、WEBP 格式，最大 10MB',
          ),
        ),
      ],
      showSubmitButton: false, // 隐藏提交按钮，使用外部的 Add 按钮
      spacing: 16,
    );
  }

  /// 构建非 Link 类型的表单（可以使用更复杂的表单组件）
  Widget _buildNonLinkForm(CardDefinition def) {
    // 非 Link 类型暂时使用类似的简单输入框
    // 后续可以根据具体类型使用 FormBuilderWidget 或其他复杂表单
    return Row(
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
