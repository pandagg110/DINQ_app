import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/account_service.dart';
import '../../../stores/resume_store.dart';
import '../../../utils/top_toast_util.dart';
import 'resume_icons.dart';

/// 瀵归綈 Web `CreateResumeModal.tsx` + `AdaptiveModal.tsx`銆?
class CreateResumeModal {
  CreateResumeModal._();

  static Future<void> show({required BuildContext context}) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: _CreateResumeSheet(onClose: () => Navigator.of(ctx).pop()),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            child: _CreateResumeDialog(onClose: () => Navigator.of(ctx).pop()),
          ),
        ),
      ),
    );
  }
}

class _CreateResumeDialog extends StatelessWidget {
  const _CreateResumeDialog({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CreateResumeHeader(title: 'Create Resume', onClose: onClose),
        const Divider(height: 1, thickness: 1, color: Color(0xFFECE9E2)),
        Flexible(
          child: SingleChildScrollView(
            child: _CreateResumeForm(onSuccess: onClose),
          ),
        ),
      ],
    );
  }
}

class _CreateResumeSheet extends StatelessWidget {
  const _CreateResumeSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CreateResumeHeader(title: 'Create Resume', onClose: onClose),
          const Divider(height: 1, thickness: 1, color: Color(0xFFECE9E2)),
          _CreateResumeForm(onSuccess: onClose),
        ],
      ),
    );
  }
}

class _CreateResumeHeader extends StatelessWidget {
  const _CreateResumeHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(8),
              hoverColor: const Color(0xFFF6F4F0),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.close, size: 18, color: Color(0xFF8A8880)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateResumeForm extends StatefulWidget {
  const _CreateResumeForm({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_CreateResumeForm> createState() => _CreateResumeFormState();
}

class _CreateResumeFormState extends State<_CreateResumeForm> {
  static const _maxFileSize = 10 * 1024 * 1024;
  static const _acceptedExtensions = ['pdf', 'doc', 'docx'];

  final _titleController = TextEditingController();
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _suggestedTitle {
    final t = _titleController.text.trim();
    if (t.isNotEmpty) return t;
    if (_fileName != null) {
      return _fileName!.replaceAll(
        RegExp(r'\.(pdf|docx?|doc)$', caseSensitive: false),
        '',
      );
    }
    return 'Untitled';
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _acceptedExtensions,
    );
    if (result == null || result.files.single.path == null) return;
    final picked = result.files.single;
    if (picked.size > _maxFileSize) {
      setState(() => _error = 'File size must be less than 10MB.');
      return;
    }
    setState(() {
      _filePath = picked.path;
      _fileName = picked.name;
      _fileSize = picked.size;
      _error = null;
    });
  }

  Future<void> _create() async {
    if (_isSubmitting) return;
    if (_filePath == null) {
      setState(() => _error = 'Choose a file first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final service = AccountService();
      final file = File(_filePath!);
      final bytes = await file.readAsBytes();
      final url = await service.uploadFile(
        fileName: _fileName!,
        fileSize: bytes.length,
        contentType: _contentType(_fileName!),
        bytes: bytes,
      );
      if (!mounted) return;
      final store = context.read<ResumeStore>();
      final resume = await store.createResume(
        title: _suggestedTitle,
        sourceUrl: url,
        fileName: _fileName!,
      );
      if (!mounted) return;
      TopToastUtil.showSuccess(context: context, title: 'Resume created');
      widget.onSuccess();
      await store.selectResume(resume.id);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Title'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 14, color: Color(0xFF171717)),
            decoration: InputDecoration(
              hintText: 'Use file name by default',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF171717)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('File'),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              hoverColor: const Color(0xFFF5F5F5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  foregroundPainter: _DashedBorderPainter(
                    color: const Color(0xFFD1D5DB),
                    radius: 12,
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? 'Choose a resume file',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fileSize != null
                                      ? '${(_fileSize! / 1024 / 1024).toStringAsFixed(1)} MB'
                                      : 'PDF, DOC, DOCX - Max 10MB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: ResumeSvgIcon(
                                ResumeIcons.upload,
                                size: 16,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : widget.onSuccess,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF171717),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: (_isSubmitting || _filePath == null)
                    ? null
                    : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF171717),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  elevation: 0,
                  minimumSize: const Size(132, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF171717),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.0;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
