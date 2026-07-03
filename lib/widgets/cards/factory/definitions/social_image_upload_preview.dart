import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../services/upload_service.dart';
import '../../../../utils/top_toast_util.dart';

class SocialImageUploadPreview extends StatefulWidget {
  const SocialImageUploadPreview({
    super.key,
    required this.imageUrl,
    required this.editable,
    required this.altText,
    required this.onImageChange,
    this.objectFit = BoxFit.cover,
  });

  final String imageUrl;
  final bool editable;
  final String altText;
  final ValueChanged<String> onImageChange;
  final BoxFit objectFit;

  @override
  State<SocialImageUploadPreview> createState() =>
      _SocialImageUploadPreviewState();
}

class _SocialImageUploadPreviewState extends State<SocialImageUploadPreview> {
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  bool _isUploading = false;
  bool _isImageMode = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.imageUrl;
  }

  @override
  void didUpdateWidget(SocialImageUploadPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl && !_isImageMode) {
      _urlController.text = widget.imageUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!widget.editable || _isUploading) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();

      final extension = _extensionFromName(image.name);
      final isImage = const {
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
      }.contains(extension);
      if (!isImage) {
        _showUploadError('Please upload an image file');
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        _showUploadError('File size should be less than 10MB');
        return;
      }

      setState(() => _isUploading = true);
      final uploadedUrl = await _uploadService.uploadFile(
        bytes: Uint8List.fromList(bytes),
        filename: image.name,
        contentType: image.mimeType ?? _contentTypeForExtension(extension),
      );
      widget.onImageChange(uploadedUrl);
      setState(() {
        _isImageMode = false;
        _urlController.text = uploadedUrl;
      });
    } catch (e) {
      _showUploadError('Failed to upload. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _extensionFromName(String name) {
    final index = name.lastIndexOf('.');
    if (index < 0 || index == name.length - 1) return 'jpg';
    return name.substring(index + 1).toLowerCase();
  }

  String _contentTypeForExtension(String extension) {
    if (extension == 'jpg') return 'image/jpeg';
    return 'image/$extension';
  }

  void _showUploadError(String description) {
    if (!mounted) return;
    TopToastUtil.showError(
      context: context,
      title: 'Upload Failed',
      description: description,
    );
  }

  void _openUrlInput() {
    if (!widget.editable || _isUploading) return;
    setState(() {
      _isImageMode = true;
      _urlController.text = widget.imageUrl;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _urlFocusNode.requestFocus();
    });
  }

  void _saveImageUrl() {
    final value = _urlController.text.trim();
    if (value != widget.imageUrl) {
      widget.onImageChange(value);
    }
    if (mounted) {
      setState(() => _isImageMode = false);
    }
  }

  void _deleteImage() {
    if (!widget.editable || _isUploading) return;
    _urlController.clear();
    widget.onImageChange('');
    setState(() => _isImageMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl.isNotEmpty;
    if (!hasImage && !widget.editable) {
      return const SizedBox.shrink();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasImage || _isImageMode || _isUploading
                ? null
                : _handleUpload,
            child: Container(
              decoration: BoxDecoration(
                color: hasImage ? Colors.transparent : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      widget.imageUrl,
                      fit: widget.objectFit,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildNoPreview(),
                    )
                  else if (!_isImageMode && !_isUploading)
                    _buildNoPreview(),
                  if (!hasImage)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: const Color(0xFFD1D5DB),
                          radius: 8,
                        ),
                      ),
                    ),
                  if (_isUploading) _buildLoadingOverlay(hasImage),
                  if (_isImageMode) _buildUrlInputOverlay(hasImage),
                ],
              ),
            ),
          ),
        ),
        if (widget.editable && !_isUploading) _buildActionBar(hasImage),
      ],
    );
  }

  Widget _buildNoPreview() {
    return const Center(
      child: Text(
        'No preview available.',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool hasImage) {
    return Container(
      color: hasImage
          ? Colors.black.withValues(alpha: 0.5)
          : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: hasImage ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uploading...',
            style: TextStyle(
              color: hasImage ? Colors.white : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool hasImage) {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbarButton(
              tooltip: 'Upload image',
              onTap: _handleUpload,
              child: const Icon(
                Icons.image_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            _buildToolbarButton(
              tooltip: 'Paste URL',
              onTap: _openUrlInput,
              child: SvgPicture.asset(
                'assets/icons/link-image.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 4),
              _buildToolbarButton(
                tooltip: 'Delete image',
                onTap: _deleteImage,
                danger: true,
                child: SvgPicture.asset(
                  'assets/icons/lucide/trash-2.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
    bool danger = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          splashColor: (danger ? Colors.red : Colors.white).withValues(
            alpha: 0.18,
          ),
          hoverColor: (danger ? Colors.red : Colors.white).withValues(
            alpha: 0.14,
          ),
          child: SizedBox(width: 28, height: 28, child: Center(child: child)),
        ),
      ),
    );
  }

  Widget _buildUrlInputOverlay(bool hasImage) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: hasImage
          ? Colors.black.withValues(alpha: 0.5)
          : Colors.transparent,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: TextField(
          controller: _urlController,
          focusNode: _urlFocusNode,
          autofocus: true,
          onSubmitted: (_) => _saveImageUrl(),
          onEditingComplete: _saveImageUrl,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111827),
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Paste URL',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF111827)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 4.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
