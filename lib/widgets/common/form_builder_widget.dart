import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/upload_service.dart';
import '../../utils/toast_util.dart';

/// 表单字段类型
enum FormFieldType {
  /// 文本输入框
  input,
  /// 多行文本输入框
  texture,
  /// 图片上传
  image,
  /// 自定义类型
  custom,
}

/// 表单字段配置
class FormFieldConfig {
  /// 字段名称（用于 form key）
  final String name;
  
  /// 字段标签
  final String label;
  
  /// 字段类型
  final FormFieldType type;
  
  /// 初始值
  final dynamic initialValue;
  
  /// 是否必填
  final bool required;
  
  /// 验证器列表
  final List<FormFieldValidator>? validators;
  
  /// 占位符文本
  final String? hintText;
  
  /// 最大行数（用于 texture 类型）
  final int? maxLines;
  
  /// 最小行数（用于 texture 类型）
  final int? minLines;
  
  /// 图片上传配置
  final ImageUploadConfig? imageConfig;
  
  /// 自定义字段构建器（用于 custom 类型）
  final Widget Function(FormFieldState<dynamic>)? customBuilder;
  
  /// 输入框装饰配置
  final InputDecoration? decoration;

  const FormFieldConfig({
    required this.name,
    required this.label,
    required this.type,
    this.initialValue,
    this.required = false,
    this.validators,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.imageConfig,
    this.customBuilder,
    this.decoration,
  });
}

/// 图片上传配置
class ImageUploadConfig {
  /// 允许的文件扩展名
  final List<String> allowedExtensions;
  
  /// 最大文件大小（字节）
  final int? maxFileSize;
  
  /// 是否显示预览
  final bool showPreview;
  
  /// 预览图片尺寸
  final double previewSize;
  
  /// 上传提示文本
  final String? uploadHint;

  const ImageUploadConfig({
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    this.maxFileSize,
    this.showPreview = true,
    this.previewSize = 120,
    this.uploadHint,
  });
}

/// 通用表单组件
class FormBuilderWidget extends StatefulWidget {
  /// 表单字段配置列表
  final List<FormFieldConfig> fields;
  
  /// 表单提交回调
  final Future<void> Function(Map<String, dynamic>)? onSubmit;
  
  /// 提交按钮文本
  final String submitButtonText;
  
  /// 提交按钮样式
  final ButtonStyle? submitButtonStyle;
  
  /// 表单间距
  final double spacing;
  
  /// 是否显示提交按钮
  final bool showSubmitButton;
  
  /// 表单键（用于外部访问表单状态）
  final GlobalKey<FormBuilderState>? formKey;

  const FormBuilderWidget({
    super.key,
    required this.fields,
    this.onSubmit,
    this.submitButtonText = '提交',
    this.submitButtonStyle,
    this.spacing = 16,
    this.showSubmitButton = true,
    this.formKey,
  });

  @override
  State<FormBuilderWidget> createState() => _FormBuilderWidgetState();
}

class _FormBuilderWidgetState extends State<FormBuilderWidget> {
  late final GlobalKey<FormBuilderState> _formKey;
  final UploadService _uploadService = UploadService();
  final Map<String, bool> _uploadingStates = {};
  final Map<String, String?> _imageUrls = {};

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormBuilderState>();
    
    // 初始化图片字段的 URL
    for (final field in widget.fields) {
      if (field.type == FormFieldType.image && field.initialValue != null) {
        _imageUrls[field.name] = field.initialValue as String?;
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      // 合并图片 URL 到表单数据
      _imageUrls.forEach((key, value) {
        if (value != null) {
          formData[key] = value;
        }
      });
      
      if (widget.onSubmit != null) {
        try {
          await widget.onSubmit!(formData);
        } catch (e) {
          if (mounted) {
            ToastUtil.showError(
              context: context,
              title: '提交失败',
              description: e.toString(),
            );
          }
        }
      }
    }
  }

  Future<void> _handleImageUpload(String fieldName, ImageUploadConfig config) async {
    if (_uploadingStates[fieldName] == true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: config.allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      // 检查文件大小
      if (config.maxFileSize != null && file.bytes!.length > config.maxFileSize!) {
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: '上传失败',
            description: '文件大小超过限制',
          );
        }
        return;
      }

      setState(() {
        _uploadingStates[fieldName] = true;
      });

      try {
        final contentType = _getContentType(file.extension ?? 'jpg');
        final uploadedUrl = await _uploadService.uploadFile(
          bytes: file.bytes!,
          filename: file.name,
          contentType: contentType,
        );

        setState(() {
          _imageUrls[fieldName] = uploadedUrl;
          _uploadingStates[fieldName] = false;
        });

        // 更新表单值
        _formKey.currentState?.fields[fieldName]?.didChange(uploadedUrl);

        if (mounted) {
          ToastUtil.showSuccess(
            context: context,
            title: '上传成功',
            description: '图片已上传',
          );
        }
      } catch (e) {
        setState(() {
          _uploadingStates[fieldName] = false;
        });
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: '上传失败',
            description: e.toString(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(
          context: context,
          title: '选择文件失败',
          description: e.toString(),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Widget _buildField(FormFieldConfig config) {
    // 构建验证器列表
    final validators = <FormFieldValidator>[];
    if (config.required) {
      validators.add(FormBuilderValidators.required(
        errorText: '${config.label}不能为空',
      ));
    }
    if (config.validators != null) {
      validators.addAll(config.validators!);
    }

    // 构建装饰
    final decoration = config.decoration ??
        InputDecoration(
          labelText: config.label,
          hintText: config.hintText,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        );

    switch (config.type) {
      case FormFieldType.input:
        return FormBuilderTextField(
          name: config.name,
          initialValue: config.initialValue,
          decoration: decoration,
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        );

      case FormFieldType.texture:
        return FormBuilderTextField(
          name: config.name,
          initialValue: config.initialValue,
          decoration: decoration,
          maxLines: config.maxLines,
          minLines: config.minLines ?? 3,
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        );

      case FormFieldType.image:
        final imageConfig = config.imageConfig ?? const ImageUploadConfig();
        final isUploading = _uploadingStates[config.name] == true;
        final imageUrl = _imageUrls[config.name] ?? config.initialValue;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormBuilderTextField(
              name: config.name,
              initialValue: imageUrl,
              decoration: decoration.copyWith(
                suffixIcon: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.upload_file),
                        onPressed: () => _handleImageUpload(config.name, imageConfig),
                      ),
              ),
              readOnly: true,
              validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Color(0xFF171717),
              ),
            ),
            if (imageConfig.showPreview && imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: imageConfig.previewSize,
                      height: imageConfig.previewSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: imageConfig.previewSize,
                          height: imageConfig.previewSize,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _imageUrls[config.name] = null;
                            _formKey.currentState?.fields[config.name]?.didChange(null);
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (imageConfig.uploadHint != null) ...[
              const SizedBox(height: 4),
              Text(
                imageConfig.uploadHint!,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        );

      case FormFieldType.custom:
        if (config.customBuilder == null) {
          return const SizedBox.shrink();
        }
        return FormBuilderField<dynamic>(
          name: config.name,
          initialValue: config.initialValue,
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          builder: config.customBuilder!,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.fields.map((field) => Padding(
                padding: EdgeInsets.only(bottom: widget.spacing),
                child: _buildField(field),
              )),
          if (widget.showSubmitButton) ...[
            SizedBox(height: widget.spacing),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: widget.submitButtonStyle ??
                  ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              child: Text(widget.submitButtonText),
            ),
          ],
        ],
      ),
    );
  }
}
