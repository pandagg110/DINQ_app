import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'form_builder_widget.dart';

/// 表单组件使用示例
class FormBuilderExample extends StatelessWidget {
  const FormBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表单组件示例'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilderWidget(
          fields: [
            // 文本输入框示例
            FormFieldConfig(
              name: 'username',
              label: '用户名',
              type: FormFieldType.input,
              required: true,
              hintText: '请输入用户名',
              validators: [
                FormBuilderValidators.minLength(3, errorText: '用户名至少3个字符'),
              ],
            ),

            // 邮箱输入框示例
            FormFieldConfig(
              name: 'email',
              label: '邮箱',
              type: FormFieldType.input,
              required: true,
              hintText: '请输入邮箱地址',
              validators: [
                FormBuilderValidators.email(errorText: '请输入有效的邮箱地址'),
              ],
            ),

            // 多行文本输入框（texture）示例
            const FormFieldConfig(
              name: 'description',
              label: '描述',
              type: FormFieldType.texture,
              required: false,
              hintText: '请输入描述信息',
              minLines: 3,
              maxLines: 5,
            ),

            // 图片上传示例
            FormFieldConfig(
              name: 'avatar',
              label: '头像',
              type: FormFieldType.image,
              required: false,
              imageConfig: const ImageUploadConfig(
                allowedExtensions: ['jpg', 'jpeg', 'png'],
                maxFileSize: 5 * 1024 * 1024, // 5MB
                showPreview: true,
                previewSize: 120,
                uploadHint: '支持 JPG、PNG 格式，最大 5MB',
              ),
            ),

            // 自定义字段示例 - 日期选择器
            FormFieldConfig(
              name: 'birthday',
              label: '生日',
              type: FormFieldType.custom,
              required: false,
              customBuilder: (field) {
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: '生日',
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
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: field.context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        field.didChange(date.toIso8601String());
                      }
                    },
                    child: Text(
                      field.value != null
                          ? DateTime.parse(field.value as String)
                              .toString()
                              .split(' ')[0]
                          : '请选择日期',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: field.value != null
                            ? const Color(0xFF171717)
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 自定义字段示例 - 下拉选择框
            FormFieldConfig(
              name: 'country',
              label: '国家',
              type: FormFieldType.custom,
              required: true,
              customBuilder: (field) {
                return DropdownButtonFormField<String>(
                  value: field.value as String?,
                  decoration: InputDecoration(
                    labelText: '国家',
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
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CN', child: Text('中国')),
                    DropdownMenuItem(value: 'US', child: Text('美国')),
                    DropdownMenuItem(value: 'JP', child: Text('日本')),
                    DropdownMenuItem(value: 'KR', child: Text('韩国')),
                  ],
                  onChanged: (value) {
                    field.didChange(value);
                  },
                  validator: field.errorText != null
                      ? (_) => field.errorText
                      : null,
                );
              },
            ),
          ],
          onSubmit: (formData) async {
            // 处理表单提交
            debugPrint('表单数据: $formData');
            
            // 这里可以调用 API 提交数据
            // await apiService.submitForm(formData);
            
            // 显示成功消息
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('表单提交成功！'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          submitButtonText: '提交表单',
        ),
      ),
    );
  }
}
