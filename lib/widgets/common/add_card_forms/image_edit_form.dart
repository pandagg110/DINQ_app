import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:croppy/croppy.dart';

import '../../../models/card_models.dart';
import '../../../services/upload_service.dart';
import '../../../stores/card_store.dart';
import '../read_bytes_from_path_stub.dart'
    if (dart.library.io) '../read_bytes_from_path_io.dart' as path_reader;

/// Image 编辑表单（含 save 逻辑），供 EditCardDialog 使用
class ImageEditFormWithSave extends StatefulWidget {
  const ImageEditFormWithSave({
    super.key,
    required this.card,
    required this.onSaveReady,
  });

  final CardItem card;
  final void Function(Future<void> Function() save) onSaveReady;

  @override
  State<ImageEditFormWithSave> createState() => _ImageEditFormWithSaveState();
}

class _ImageEditFormWithSaveState extends State<ImageEditFormWithSave> {
  late final TextEditingController _captionController;
  late final TextEditingController _linkController;
  final _uploadService = UploadService();
  
  String? _imageUrl;
  bool _isUploading = false;
  Uint8List? _localImageBytes;

  @override
  void initState() {
    super.initState();
    final metadata = widget.card.data.metadata;
    _imageUrl = metadata['url']?.toString();
    _captionController = TextEditingController(
      text: metadata['caption']?.toString() ?? '',
    );
    _linkController = TextEditingController(
      text: metadata['link']?.toString() ?? '',
    );
    widget.onSaveReady(_performSave);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _performSave() async {
    if (!mounted) return;
    final cardStore = context.read<CardStore>();
    final newMetadata = Map<String, dynamic>.from(widget.card.data.metadata);
    
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      newMetadata['url'] = _imageUrl;
    }
    newMetadata['caption'] = _captionController.text.trim();
    newMetadata['link'] = _linkController.text.trim();
    
    cardStore.updateCardData(
      widget.card.id,
      CardData(
        id: widget.card.data.id,
        type: widget.card.data.type,
        title: widget.card.data.title,
        description: widget.card.data.description,
        metadata: newMetadata,
        status: widget.card.data.status,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    
    final file = result.files.single;
    Uint8List? imageBytes = file.bytes;
    if (imageBytes == null && !kIsWeb && file.path != null && file.path!.isNotEmpty) {
      try {
        imageBytes = await path_reader.readBytesFromPath(file.path!);
      } catch (e) {
        if (mounted) {
          TopToastUtil.showError(context: context, title: '读取失败', description: e.toString());
        }
        return;
      }
    }
    if (imageBytes == null || !mounted) {
      if (mounted) {
        TopToastUtil.showError(context: context, title: '无法读取图片', description: '请重试');
      }
      return;
    }

    // 显示本地预览
    setState(() {
      _localImageBytes = imageBytes;
      _isUploading = true;
    });

    try {
      final contentType = _getContentType(file.extension ?? 'jpg');
      final fileUrl = await _uploadService.uploadFile(
        bytes: imageBytes,
        filename: file.name,
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = fileUrl;
        _localImageBytes = null;
        _isUploading = false;
      });
      TopToastUtil.showSuccess(context: context, title: '上传成功', description: '');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        TopToastUtil.showError(context: context, title: '上传失败', description: e.toString());
      }
    }
  }

  Future<void> _pickCropAndUploadImage() async {
    if (_isUploading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    
    final file = result.files.single;
    Uint8List? imageBytes = file.bytes;
    if (imageBytes == null && !kIsWeb && file.path != null && file.path!.isNotEmpty) {
      try {
        imageBytes = await path_reader.readBytesFromPath(file.path!);
      } catch (e) {
        if (mounted) {
          TopToastUtil.showError(context: context, title: '读取失败', description: e.toString());
        }
        return;
      }
    }
    if (imageBytes == null || !mounted) {
      if (mounted) {
        TopToastUtil.showError(context: context, title: '无法读取图片', description: '请重试');
      }
      return;
    }

    Uint8List? croppedBytes;
    try {
      final cropResult = await showMaterialImageCropper(
        context,
        imageProvider: MemoryImage(imageBytes),
        allowedAspectRatios: [
          const CropAspectRatio(width: 16, height: 9),
          const CropAspectRatio(width: 4, height: 3),
          const CropAspectRatio(width: 1, height: 1),
        ],
        enabledTransformations: [
          Transformation.panAndScale,
          Transformation.resize,
        ],
      );
      if (cropResult != null) {
        final byteData = await cropResult.uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          croppedBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (e) {
      if (mounted) {
        TopToastUtil.showError(context: context, title: '裁剪失败', description: e.toString());
      }
      return;
    }
    if (croppedBytes == null || !mounted) return;

    setState(() {
      _localImageBytes = croppedBytes;
      _isUploading = true;
    });

    try {
      final fileUrl = await _uploadService.uploadFile(
        bytes: croppedBytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
        contentType: 'image/png',
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = fileUrl;
        _localImageBytes = null;
        _isUploading = false;
      });
      TopToastUtil.showSuccess(context: context, title: '上传成功', description: '');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        TopToastUtil.showError(context: context, title: '上传失败', description: e.toString());
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview Section
          _buildPreviewSection(),
          const SizedBox(height: 24),
          
          // Upload and Crop Section
          _buildUploadSection(),
          const SizedBox(height: 24),
          
          // Caption Section
          _buildCaptionSection(),
          const SizedBox(height: 20),
          
          // Link URL Section
          _buildLinkSection(),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF3F4F6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImagePreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_localImageBytes != null) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _localImageBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 48, color: Color(0xFF9CA3AF)),
              );
            },
          ),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload, size: 20),
                label: const Text(
                  'Upload Image or Video',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              borderOnForeground: true,
              child: InkWell(
                onTap: _isUploading ? null : _pickCropAndUploadImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.crop,
                    size: 20,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Recommended size: 1200x630',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Caption',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          decoration: const InputDecoration(
            hintText: 'Enter Caption',
            hintStyle: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF171717), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Link URL',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _linkController,
          decoration: const InputDecoration(
            hintText: 'Enter a Link',
            hintStyle: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF171717), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        ),
      ],
    );
  }
}
