import 'package:flutter/material.dart';
import '../../cards/factory/card_definition.dart';
import '../form_builder_widget.dart';
import 'card_form_base.dart';

// 导入 FormBuilderWidget 以便使用其 State 类型

/// Markdown 类型的表单（使用 FormBuilderWidget）
class MarkdownForm extends CardFormBase {
  final GlobalKey<State<FormBuilderWidget>> _formKey;

  MarkdownForm({required GlobalKey<State<FormBuilderWidget>> formKey}) : _formKey = formKey;

  @override
  Widget build(BuildContext context, CardDefinition definition) {
    return FormBuilderWidget(
      key: _formKey,
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

  @override
  Future<Map<String, dynamic>?> getFormData() async {
    final state = _formKey.currentState;
    if (state == null) return null;
    // 通过 dynamic 调用私有方法（因为 _FormBuilderWidgetState 是私有的）
    return await (state as dynamic).uploadPendingImagesAndGetValues();
  }
}
