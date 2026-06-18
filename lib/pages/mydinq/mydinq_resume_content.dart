import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/resume_models.dart';
import '../../services/account_service.dart';
import '../../stores/resume_store.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/mydinq/resume/create_resume_modal.dart';
import '../../widgets/mydinq/resume/resume_list.dart';
import '../../widgets/mydinq/resume/resume_preview.dart';
import '../../widgets/mydinq/resume/resume_uploading_card.dart';

const _maxFileSize = 10 * 1024 * 1024;
const _acceptedExtensions = ['pdf', 'doc', 'docx'];
const _uploadAnimationMs = 10000;
const _statusPollIntervalMs = 2000;
const _statusPollMaxAttempts = 60;

/// 对齐 Web `/mydinq/resume/page.tsx`。
class MyDinqResumeContent extends StatefulWidget {
  const MyDinqResumeContent({super.key});

  @override
  State<MyDinqResumeContent> createState() => _MyDinqResumeContentState();
}

class _UploadSession {
  _UploadSession({
    required this.fileName,
    required this.previousSelectedId,
    required this.cancelToken,
  });

  final String fileName;
  final String? previousSelectedId;
  final CancelToken cancelToken;
  UploadPhase phase = UploadPhase.uploading;
  int progress = 0;
  int secondsLeft = _uploadAnimationMs ~/ 1000;
  String? createdResumeId;
}

class _MyDinqResumeContentState extends State<MyDinqResumeContent> {
  final _accountService = AccountService();
  bool _isResumeListOpen = false;
  bool _isCreateOpen = false;
  bool _resumeSheetOpen = false;
  _UploadSession? _uploadSession;
  bool _hasResolvedInitialLoad = false;
  Timer? _progressTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final store = context.read<ResumeStore>();
    _hasResolvedInitialLoad =
        store.resumes.isNotEmpty || store.selectedResume != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initResumes());
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pollTimer?.cancel();
    _uploadSession?.cancelToken.cancel();
    super.dispose();
  }

  Future<void> _initResumes() async {
    final store = context.read<ResumeStore>();
    await store.loadResumes();
    if (!mounted) return;
    if (store.selectedResume == null && store.resumes.isNotEmpty) {
      try {
        await store.selectResume(store.resumes.first.id);
      } catch (_) {}
    }
    if (mounted) setState(() => _hasResolvedInitialLoad = true);
  }

  void _onUploadSessionChanged() {
    _progressTimer?.cancel();
    _pollTimer?.cancel();
    final session = _uploadSession;
    if (session == null) return;

    final startedAt = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _uploadSession != session) return;
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      final pct = ((elapsed / _uploadAnimationMs) * 100).floor().clamp(0, 95);
      final sLeft = ((_uploadAnimationMs - elapsed) / 1000).ceil().clamp(0, 9999);
      setState(() {
        session.progress = pct;
        session.secondsLeft = sLeft == 0 ? 1 : sLeft;
      });
    });

    if (session.phase == UploadPhase.processing && session.createdResumeId != null) {
      _startProcessingPoll(session);
    }
  }

  void _startProcessingPoll(_UploadSession session) {
    var attempts = 0;
    final resumeId = session.createdResumeId!;
    Future<void> tick() async {
      if (!mounted || _uploadSession != session || session.cancelToken.isCancelled) {
        return;
      }
      attempts++;
      try {
        final store = context.read<ResumeStore>();
        final refreshed = await store.selectResume(
          resumeId,
          force: true,
          silent: true,
        );
        if (!mounted || _uploadSession != session) return;
        if (refreshed?.status == ResumeStatus.ready) {
          setState(() {
            session.progress = 100;
            session.secondsLeft = 0;
          });
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          setState(() => _uploadSession = null);
          TopToastUtil.showSuccess(context: context, title: 'Resume uploaded');
          return;
        }
      } catch (_) {}
      if (attempts >= _statusPollMaxAttempts && mounted && _uploadSession == session) {
        setState(() => _uploadSession = null);
        TopToastUtil.showSuccess(
          context: context,
          title: "Still processing — we'll keep checking in the background.",
        );
      }
    }

    tick();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: _statusPollIntervalMs),
      (_) => tick(),
    );
  }

  String? _ambientPollResumeId;

  void _syncAmbientProcessingPoll(ResumeStore store) {
    if (_uploadSession != null) {
      _ambientPollResumeId = null;
      return;
    }
    final resume = store.selectedResume;
    if (resume == null || resume.status != ResumeStatus.processing) {
      _ambientPollResumeId = null;
      return;
    }
    if (_ambientPollResumeId == resume.id && _pollTimer?.isActive == true) {
      return;
    }
    _ambientPollResumeId = resume.id;
    _startAmbientProcessingPoll(resume.id);
  }

  void _startAmbientProcessingPoll(String resumeId) {
    var attempts = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_uploadSession != null || !mounted) return;
      if (++attempts > 40) {
        _pollTimer?.cancel();
        return;
      }
      try {
        await context.read<ResumeStore>().selectResume(
              resumeId,
              force: true,
              silent: true,
            );
      } catch (_) {}
    });
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

  Future<void> _handleUploadRequest() async {
    if (_uploadSession != null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _acceptedExtensions,
    );
    if (result == null || result.files.single.path == null) return;
    await _handleFileSelected(result.files.single);
  }

  Future<void> _handleFileSelected(PlatformFile picked) async {
    final path = picked.path;
    if (path == null) return;
    final file = File(path);
    if (picked.size > _maxFileSize) {
      TopToastUtil.showError(
        context: context,
        title: 'File size must be less than 10MB.',
      );
      return;
    }

    final store = context.read<ResumeStore>();
    final previousSelectedId = store.selectedResume?.id;
    final token = CancelToken();
    final session = _UploadSession(
      fileName: picked.name,
      previousSelectedId: previousSelectedId,
      cancelToken: token,
    );
    setState(() {
      _uploadSession = session;
      _isResumeListOpen = false;
    });
    _onUploadSessionChanged();

    try {
      final bytes = await file.readAsBytes();
      if (token.isCancelled || _uploadSession != session) return;
      final sourceUrl = await _accountService.uploadFile(
        fileName: picked.name,
        fileSize: bytes.length,
        contentType: _contentType(picked.name),
        bytes: bytes,
        cancelToken: token,
      );
      if (token.isCancelled || _uploadSession != session) return;

      final rawTitle = picked.name.replaceAll(
        RegExp(r'\.(pdf|docx?|doc)$', caseSensitive: false),
        '',
      );
      final fallbackTitle = rawTitle.isEmpty ? 'Untitled' : rawTitle;
      final created = await store.createResume(
        title: fallbackTitle,
        sourceUrl: sourceUrl,
        fileName: picked.name,
        select: false,
      );
      if (token.isCancelled || _uploadSession != session) {
        await store.deleteResume(created.id);
        return;
      }
      session.phase = UploadPhase.processing;
      session.createdResumeId = created.id;
      _onUploadSessionChanged();
    } catch (e) {
      if (token.isCancelled || _uploadSession != session) return;
      if (!mounted) return;
      setState(() => _uploadSession = null);
      TopToastUtil.showError(
        context: context,
        title: e is DioException ? (e.message ?? 'Upload failed') : '$e',
      );
    }
  }

  Future<void> _handleCancelUpload() async {
    final session = _uploadSession;
    if (session == null) return;
    session.cancelToken.cancel();
    setState(() => _uploadSession = null);
    _progressTimer?.cancel();
    _pollTimer?.cancel();

    if (session.createdResumeId != null) {
      final store = context.read<ResumeStore>();
      try {
        await store.deleteResume(session.createdResumeId!);
      } catch (_) {}
      final currentId = store.selectedResume?.id;
      if (session.previousSelectedId != null &&
          currentId != session.previousSelectedId) {
        try {
          await store.selectResume(session.previousSelectedId!);
        } catch (_) {}
      }
    }
    if (!mounted) return;
    TopToastUtil.showSuccess(context: context, title: 'Upload cancelled');
  }

  Future<void> _showResumeListSheet() async {
    if (_resumeSheetOpen || !mounted || _uploadSession != null) return;
    _resumeSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scroll) => ResumeListMobileSheet(
          scrollController: scroll,
          onClose: () => Navigator.of(ctx).pop(),
          onCreateOpen: () {
            Navigator.of(ctx).pop();
            if (mounted) setState(() => _isCreateOpen = true);
          },
        ),
      ),
    );
    _resumeSheetOpen = false;
  }

  void _toggleResumeList() {
    if (_uploadSession != null) return;
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (isMobile) {
      _showResumeListSheet();
      return;
    }
    setState(() => _isResumeListOpen = !_isResumeListOpen);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    _syncAmbientProcessingPoll(store);

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    final uploadPreview = _uploadSession == null
        ? null
        : ResumeUploadPreviewState(
            fileName: _uploadSession!.fileName,
            progress: _uploadSession!.progress,
            secondsLeft: _uploadSession!.secondsLeft,
            phase: _uploadSession!.phase,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Stack(
        children: [
          ResumePreview(
            resume: store.selectedResume,
            isLoading: store.isLoadingDetail || !_hasResolvedInitialLoad,
            onResumeListToggle: _toggleResumeList,
            onCreateOpen: _handleUploadRequest,
            upload: uploadPreview,
            onCancelUpload: _handleCancelUpload,
            resumeListSlot: isMobile
                ? null
                : ResumeList(
                    isOpen: _isResumeListOpen && _uploadSession == null,
                    onClose: () => setState(() => _isResumeListOpen = false),
                    onCreateOpen: () => setState(() => _isCreateOpen = true),
                  ),
          ),
          CreateResumeModal(
            isOpen: _isCreateOpen,
            onClose: () => setState(() => _isCreateOpen = false),
          ),
        ],
      ),
    );
  }
}
