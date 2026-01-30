import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'read_bytes_from_path_stub.dart' if (dart.library.io) 'read_bytes_from_path_io.dart' as path_reader;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/upload_service.dart';
import '../../utils/toast_util.dart';

/// 表单字段类型
enum FormFieldType {
  input,
  texture,
  image,
  custom,
}

/// 表单字段配置
class FormFieldConfig {
  final String name;
  final String label;
  final FormFieldType type;
  final dynamic initialValue;
  final bool required;
  final List<FormFieldValidator>? validators;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final ImageUploadConfig? imageConfig;
  final Widget Function(FormFieldState<dynamic>)? customBuilder;
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
  final List<String> allowedExtensions;
  final int? maxFileSize;
  final bool showPreview;
  final double previewSize;
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
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, dynamic>)? onSubmit;
  final String submitButtonText;
  final ButtonStyle? submitButtonStyle;
  final double spacing;
  final bool showSubmitButton;
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
    for (final field in widget.fields) {
      if (field.type == FormFieldType.image && field.initialValue != null) {
        _imageUrls[field.name] = field.initialValue as String?;
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = Map<String, dynamic>.from(_formKey.currentState!.value);
      _imageUrls.forEach((key, value) {
        if (value != null) formData[key] = value;
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

  /// 选择图片后直接使用 getUploadUrl 上传，表单显示上传后的 URL
  Future<void> _handleImageUpload(String fieldName, ImageUploadConfig config) async {
    debugPrint('[FormBuilder] _handleImageUpload 开始 fieldName=$fieldName');
    if (_uploadingStates[fieldName] == true) {
      debugPrint('[FormBuilder] 正在上传中，忽略');
      return;
    }
    try {
      debugPrint('[FormBuilder] 打开文件选择器 allowedExtensions=${config.allowedExtensions}');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: config.allowedExtensions,
      );
      debugPrint('[FormBuilder] pickFiles 返回 result=$result, filesCount=${result?.files.length ?? 0}');
      if (result == null || result.files.isEmpty) {
        debugPrint('[FormBuilder] 未选择文件或结果为空');
        return;
      }
      final file = result.files.first;
      debugPrint('[FormBuilder] 第一个文件 name=${file.name}, path=${file.path}, bytes=${file.bytes != null ? file.bytes!.length : null}, size=${file.size}');

      // 手机端常只返回 path，bytes 为 null，需从路径读取
      Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
        debugPrint('[FormBuilder] 使用 file.bytes 长度=${bytes.length}');
      } else if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
        try {
          bytes = await path_reader.readBytesFromPath(file.path!);
          debugPrint('[FormBuilder] 从 path 读取成功 长度=${bytes.length}');
        } catch (e) {
          debugPrint('[FormBuilder] 从 path 读取失败: $e');
          if (mounted) {
            ToastUtil.showError(
              context: context,
              title: '读取文件失败',
              description: e.toString(),
            );
          }
          return;
        }
      } else {
        debugPrint('[FormBuilder] file.bytes 与 path 均不可用，无法上传');
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: '无法读取图片',
            description: '请重试或换一张图片',
          );
        }
        return;
      }

      if (config.maxFileSize != null && bytes.length > config.maxFileSize!) {
        debugPrint('[FormBuilder] 文件过大 ${bytes.length} > ${config.maxFileSize}');
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: '上传失败',
            description: '文件大小超过限制',
          );
        }
        return;
      }

      setState(() => _uploadingStates[fieldName] = true);
      debugPrint('[FormBuilder] 开始上传 bytes.length=${bytes.length}');

      try {
        final contentType = _getContentType(file.extension ?? 'jpg');

        debugPrint('[FormBuilder] 调用 getUploadUrl fileName=${file.name} fileSize=${bytes.length} contentType=$contentType');
        final uploadToken = await _uploadService.getUploadUrl(
          fileName: file.name,
          fileSize: bytes.length,
          contentType: contentType,
        );
        final uploadUrl = uploadToken['upload_url'] as String;
        final fileUrl = uploadToken['file_url'] as String;
        debugPrint('[FormBuilder] getUploadUrl 成功 fileUrl=$fileUrl');

        debugPrint('[FormBuilder] 开始 PUT 到 OSS');
        final dio = Dio();
        await dio.put(
          uploadUrl,
          data: bytes,
          options: Options(
            headers: {'Content-Type': contentType},
          ),
        );
        debugPrint('[FormBuilder] OSS 上传成功');

        setState(() {
          _imageUrls[fieldName] = fileUrl;
          _uploadingStates[fieldName] = false;
        });
        _formKey.currentState?.fields[fieldName]?.didChange(fileUrl);
        if (mounted) {
          ToastUtil.showSuccess(
            context: context,
            title: '上传成功',
            description: '图片已上传',
          );
        }
      } catch (e, st) {
        debugPrint('[FormBuilder] 上传异常: $e');
        debugPrint('[FormBuilder] stackTrace: $st');
        setState(() => _uploadingStates[fieldName] = false);
        if (mounted) {
          ToastUtil.showError(
            context: context,
            title: '上传失败',
            description: e.toString(),
          );
        }
      }
    } catch (e, st) {
      debugPrint('[FormBuilder] _handleImageUpload 外层异常: $e');
      debugPrint('[FormBuilder] stackTrace: $st');
      if (mounted) {
        ToastUtil.showError(
          context: context,
          title: '选择文件失败',
          description: e.toString(),
        );
      }
    }
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
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

  static InputDecoration _baseDecoration(FormFieldConfig config) {
    return InputDecoration(
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
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF171717),
        ),
      ),
    );
  }

  Widget? _buildErrorText(String? errorText) {
    if (errorText == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        errorText,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildField(FormFieldConfig config) {
    final validators = <FormFieldValidator>[];
    if (config.required) {
      validators.add(FormBuilderValidators.required(errorText: '${config.label}不能为空'));
    }
    if (config.validators != null) validators.addAll(config.validators!);
    final decoration = config.decoration ?? _baseDecoration(config);
    final decorationNoLabel = config.decoration != null
        ? config.decoration!.copyWith(labelText: null)
        : decoration.copyWith(labelText: null);

    switch (config.type) {
      case FormFieldType.input:
        return FormBuilderField<String>(
          name: config.name,
          initialValue: config.initialValue?.toString(),
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(config.label),
                TextFormField(
                  initialValue: config.initialValue?.toString(),
                  decoration: decorationNoLabel.copyWith(errorText: field.errorText),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0xFF171717),
                  ),
                  onChanged: (v) => field.didChange(v),
                ),
                if (field.errorText != null) _buildErrorText(field.errorText)!,
              ],
            );
          },
        );

      case FormFieldType.texture:
        return FormBuilderField<String>(
          name: config.name,
          initialValue: config.initialValue?.toString(),
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(config.label),
                TextFormField(
                  initialValue: config.initialValue?.toString(),
                  decoration: decorationNoLabel.copyWith(errorText: field.errorText),
                  maxLines: config.maxLines,
                  minLines: config.minLines ?? 3,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0xFF171717),
                  ),
                  onChanged: (v) => field.didChange(v),
                ),
                if (field.errorText != null) _buildErrorText(field.errorText)!,
              ],
            );
          },
        );

      case FormFieldType.image:
        final imageConfig = config.imageConfig ?? const ImageUploadConfig();
        return FormBuilderField<String>(
          name: config.name,
          initialValue: config.initialValue?.toString(),
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          builder: (field) {
            final isUploading = _uploadingStates[config.name] == true;
            final imageUrl = _imageUrls[config.name] ?? field.value ?? config.initialValue?.toString();
            final hasImage = imageUrl != null && imageUrl.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(config.label),
                GestureDetector(
                  onTap: isUploading ? null : () => _handleImageUpload(config.name, imageConfig),
                  child: Container(
                    width: imageConfig.previewSize,
                    height: imageConfig.previewSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        if (!hasImage || !imageConfig.showPreview)
                          CustomPaint(
                            painter: _DashedBorderPainter(
                              color: const Color(0xFFD1D5DB),
                              strokeWidth: 1.5,
                              borderRadius: 8,
                            ),
                            child: Container(),
                          ),
                        if (hasImage && imageConfig.showPreview)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: imageConfig.previewSize,
                                  height: imageConfig.previewSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: imageConfig.previewSize,
                                    height: imageConfig.previewSize,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              if (isUploading)
                                Container(
                                  width: imageConfig.previewSize,
                                  height: imageConfig.previewSize,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              if (!isUploading)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _imageUrls[config.name] = null);
                                        field.didChange(null);
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
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 32, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: SelectableText(
                      imageUrl,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
                if (field.errorText != null) _buildErrorText(field.errorText)!,
                if (imageConfig.uploadHint != null && !hasImage) ...[
                  const SizedBox(height: 8),
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
          },
        );

      case FormFieldType.custom:
        if (config.customBuilder == null) return const SizedBox.shrink();
        return FormBuilderField<dynamic>(
          name: config.name,
          initialValue: config.initialValue,
          validator: validators.isEmpty ? null : FormBuilderValidators.compose(validators),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(config.label),
                config.customBuilder!(field),
                if (field.errorText != null) _buildErrorText(field.errorText)!,
              ],
            );
          },
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance);
        final end = metric.getTangentForOffset((distance + dashWidth).clamp(0.0, metric.length));
        if (start != null && end != null) canvas.drawLine(start.position, end.position, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.borderRadius != borderRadius;
}
