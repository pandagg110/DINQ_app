import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/account_service.dart';
import '../../../stores/resume_store.dart';
import '../../../utils/top_toast_util.dart';
import 'resume_icons.dart';

/// 对齐 Web `CreateResumeModal.tsx`。
class CreateResumeModal extends StatefulWidget {
  const CreateResumeModal({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  final bool isOpen;
  final VoidCallback onClose;

  @override
  State<CreateResumeModal> createState() => _CreateResumeModalState();
}

class _CreateResumeModalState extends State<CreateResumeModal> {
  static const _maxFileSize = 10 * 1024 * 1024;
  static const _acceptedExtensions = ['pdf', 'doc', 'docx'];

  final _titleController = TextEditingController();
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  bool _isSubmitting = false;
  String? _error;

  @override
  void didUpdateWidget(covariant CreateResumeModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpen && oldWidget.isOpen) {
      _titleController.clear();
      setState(() {
        _filePath = null;
        _fileName = null;
        _fileSize = null;
        _isSubmitting = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _suggestedTitle {
    final t = _titleController.text.trim();
    if (t.isNotEmpty) return t;
    if (_fileName != null) {
      return _fileName!.replaceAll(RegExp(r'\.(pdf|docx?|doc)$', caseSensitive: false), '');
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
    final size = picked.size;
    if (size > _maxFileSize) {
      setState(() => _error = 'File size must be less than 10MB.');
      return;
    }
    setState(() {
      _filePath = picked.path;
      _fileName = picked.name;
      _fileSize = size;
      _error = null;
    });
  }

  Future<void> _create() async {
    if (_isSubmitting || _filePath == null) {
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
      widget.onClose();
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
    if (!widget.isOpen) return const SizedBox.shrink();
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black54,
          onDismiss: widget.onClose,
        ),
        Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Create Resume',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Use file name by default',
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
                    const Text(
                      'File',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
                            style: BorderStyle.solid,
                          ),
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
                                        : 'PDF, DOC, DOCX — Max 10MB',
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
                                child: ResumeSvgIcon(ResumeIcons.upload, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : widget.onClose,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: (_isSubmitting || _filePath == null) ? null : _create,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF171717),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(132, 40),
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
                              : const Text('Create'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
