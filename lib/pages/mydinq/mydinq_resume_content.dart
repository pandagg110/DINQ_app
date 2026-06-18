import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';

/// My DINQ Resume 标签页内容（无独立 AppBar，对齐 Web `/mydinq/resume`）。
class MyDinqResumeContent extends StatefulWidget {
  const MyDinqResumeContent({super.key});

  @override
  State<MyDinqResumeContent> createState() => _MyDinqResumeContentState();
}

class _MyDinqResumeContentState extends State<MyDinqResumeContent> {
  final _service = AccountService();
  List<dynamic> _resumes = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resumes = await _service.getResumes();
      if (!mounted) return;
      setState(() {
        _resumes = resumes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _upload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) return;
      final picked = result.files.single;
      final file = File(picked.path!);
      if (file.lengthSync() > 10 * 1024 * 1024) {
        _snack('File must be less than 10MB');
        return;
      }
      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final url = await _service.uploadFile(
        fileName: picked.name,
        fileSize: bytes.length,
        contentType: 'application/pdf',
        bytes: bytes,
      );
      final title =
          picked.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      await _service.createResume(
        title: title,
        sourceUrl: url,
        fileName: picked.name,
      );
      if (!mounted) return;
      _snack('Resume uploaded');
      await _load();
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _service.deleteResume(id);
      await _load();
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _body()),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: _uploading ? null : _upload,
            backgroundColor: ColorUtil.textColor,
            foregroundColor: Colors.white,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file_outlined, size: 20),
            label: Text(_uploading ? 'Uploading...' : 'Upload PDF'),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: DinqTokens.textTertiary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_resumes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 40, color: DinqTokens.textTertiary),
            SizedBox(height: 12),
            Text(
              'No resume yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DinqTokens.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Upload a PDF to power your DINQ Page.',
              style: TextStyle(fontSize: 13, color: DinqTokens.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (final r in _resumes) _resumeRow(Map<String, dynamic>.from(r as Map)),
      ],
    );
  }

  Widget _resumeRow(Map<String, dynamic> r) {
    final id = (r['id'] ?? '').toString();
    final title = (r['title'] ?? 'Resume').toString();
    final sourceUrl = (r['source_url'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              size: 26, color: Color(0xFFC27C5A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ColorUtil.textColor,
              ),
            ),
          ),
          if (sourceUrl.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => launchUrl(
                Uri.parse(sourceUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.open_in_new_rounded,
                    size: 20, color: DinqTokens.textSecondary),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _delete(id),
            child: const Icon(Icons.delete_outline,
                size: 20, color: Color(0xFFE24B3C)),
          ),
        ],
      ),
    );
  }
}
