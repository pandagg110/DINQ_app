import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/resume_models.dart';
import '../../../stores/resume_store.dart';
import '../../../theme/dinq_tokens.dart';
import '../../search/message_group/dinq_logo.dart';
import 'pdf_pages.dart';
import 'pdf_preview_skeleton.dart';
import 'resume_icons.dart';
import 'resume_pdf_web_fallback.dart';
import 'resume_uploading_card.dart';

class ResumeUploadPreviewState {
  const ResumeUploadPreviewState({
    required this.fileName,
    required this.progress,
    required this.secondsLeft,
    required this.phase,
  });

  final String fileName;
  final int progress;
  final int secondsLeft;
  final UploadPhase phase;
}

/// 对齐 Web `ResumePreview.tsx`。
class ResumePreview extends StatefulWidget {
  const ResumePreview({
    super.key,
    this.resume,
    this.isLoading = false,
    this.resumeListSlot,
    this.onResumeListToggle,
    this.onCreateOpen,
    this.upload,
    this.onCancelUpload,
  });

  final ResumeItem? resume;
  final bool isLoading;
  final Widget? resumeListSlot;
  final VoidCallback? onResumeListToggle;
  final VoidCallback? onCreateOpen;
  final ResumeUploadPreviewState? upload;
  final VoidCallback? onCancelUpload;

  @override
  State<ResumePreview> createState() => _ResumePreviewState();
}

class _ResumePreviewState extends State<ResumePreview>
    with SingleTickerProviderStateMixin {
  Uint8List? _pdfData;
  bool _isPdfLoading = false;
  bool _pdfLoadFailed = false;
  double _zoom = 1;
  bool _isSidebarOpen = true;
  int _pdfPageCount = 0;
  CancelToken? _pdfCancel;
  bool _useWebFallback = false;

  late final AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPdfIfNeeded());
  }

  @override
  void dispose() {
    _pdfCancel?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResumePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resume?.id != widget.resume?.id) {
      _pdfPageCount = 0;
      _pdfData = null;
      _pdfLoadFailed = false;
      _useWebFallback = false;
      _loadPdfIfNeeded();
    } else if (oldWidget.resume?.updatedAt != widget.resume?.updatedAt ||
        oldWidget.resume?.status != widget.resume?.status) {
      _loadPdfIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pdfData == null && !_isPdfLoading && !_pdfLoadFailed) {
      _loadPdfIfNeeded();
    }
  }

  Future<void> _loadPdfIfNeeded() async {
    final resume = widget.resume;
    _pdfCancel?.cancel();
    if (resume?.sourceUrl == null ||
        resume!.sourceUrl!.isEmpty ||
        resume.status != ResumeStatus.ready) {
      return;
    }
    final cancel = CancelToken();
    _pdfCancel = cancel;
    setState(() {
      _isPdfLoading = true;
      _pdfLoadFailed = false;
    });
    try {
      final dio = Dio();
      final resp = await dio.get<List<int>>(
        resume.sourceUrl!,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
        cancelToken: cancel,
      );
      if (!mounted || cancel.isCancelled) return;
      final bytes = Uint8List.fromList(resp.data ?? []);
      if (bytes.length < 4 ||
          String.fromCharCodes(bytes.sublist(0, 4)) != '%PDF') {
        throw Exception('Invalid PDF response');
      }
      setState(() {
        _pdfData = bytes;
        _isPdfLoading = false;
        _useWebFallback = false;
      });
    } catch (e) {
      if (cancel.isCancelled) return;
      debugPrint('PDF download failed: $e');
      if (!mounted) return;
      setState(() {
        _pdfData = null;
        _pdfLoadFailed = true;
        _isPdfLoading = false;
      });
    }
  }

  void _handleDownload() {
    final url = widget.resume?.sourceUrl;
    if (url == null || url.isEmpty) return;
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _zoomIn() => setState(() => _zoom = (_zoom + 0.25).clamp(0.5, 3));
  void _zoomOut() => setState(() => _zoom = (_zoom - 0.25).clamp(0.5, 3));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    final hasAnyResume = store.resumes.isNotEmpty;
    final isUploading = widget.upload != null;
    final showThumbSidebarControls = _pdfData != null && _pdfPageCount > 1;
    final showHeader =
        (widget.resume != null || hasAnyResume) && !(widget.isLoading && widget.resume == null);

    final canDownload = widget.resume?.sourceUrl != null &&
        widget.resume!.sourceUrl!.isNotEmpty &&
        widget.resume!.status == ResumeStatus.ready &&
        !isUploading;

    final showPdfSkeleton = widget.resume?.status == ResumeStatus.ready &&
        widget.resume?.sourceUrl != null &&
        _pdfData == null &&
        !_pdfLoadFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) _buildHeader(showThumbSidebarControls, isUploading, canDownload),
        Expanded(child: _buildBody(showPdfSkeleton, isUploading)),
      ],
    );
  }

  Widget _buildHeader(bool showThumbSidebarControls, bool isUploading, bool canDownload) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              SizedBox(
                width: showThumbSidebarControls ? 140 : 0,
                child: showThumbSidebarControls && !isUploading
                    ? Center(
                        child: _iconBorderButton(
                          onTap: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                          child: ResumeSvgIcon(
                            _isSidebarOpen
                                ? ResumeIcons.panelLeftClose
                                : ResumeIcons.panelLeftOpen,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : null,
              ),
              const Spacer(),
              _downloadButton(canDownload),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _resumeSelector(isUploading),
          ),
          if (widget.resumeListSlot != null)
            Positioned(
              top: 44,
              left: 0,
              right: 0,
              child: Center(child: widget.resumeListSlot!),
            ),
        ],
      ),
    );
  }

  Widget _resumeSelector(bool isUploading) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 400),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isUploading ? null : widget.onResumeListToggle,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBEAE5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.resume?.title ?? 'Select Resume',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isUploading
                          ? const Color(0xFF2C2B2A).withValues(alpha: 0.5)
                          : const Color(0xFF2C2B2A),
                    ),
                  ),
                ),
                const ResumeSvgIcon(ResumeIcons.chevronDown, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _downloadButton(bool canDownload) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: canDownload ? _handleDownload : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          width: isMobile ? 36 : null,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEBEAE5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ResumeSvgIcon(
                ResumeIcons.download,
                size: 14,
                color: canDownload
                    ? const Color(0xFF2C2B2A)
                    : const Color(0xFF9CA3AF),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 6),
                const Text(
                  'Download resume',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2C2B2A)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBorderButton({required VoidCallback onTap, required Widget child}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFEBEAE5)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 36, height: 36, child: Center(child: child)),
      ),
    );
  }

  Widget _buildBody(bool showPdfSkeleton, bool isUploading) {
    final upload = widget.upload;
    if (upload != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 64),
          child: ResumeUploadingCard(
            fileName: upload.fileName,
            progress: upload.progress,
            secondsLeft: upload.secondsLeft,
            phase: upload.phase,
            onCancel: widget.onCancelUpload ?? () {},
          ),
        ),
      );
    }

    if (widget.isLoading) {
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
      return Center(
        child: BreathingLogo(size: 32, animation: _breathingController),
      );
    }
    _breathingController.stop();

    final resume = widget.resume;
    if (resume == null) return _emptyState();

    if (resume.status == ResumeStatus.processing) {
      return _processingState();
    }

    if (_isPdfLoading || showPdfSkeleton) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ResumeSkeletonPulse(
            child: PdfPreviewSkeleton(maxHeight: constraints.maxHeight),
          );
        },
      );
    }

    if (_pdfData != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _useWebFallback
                ? ResumePdfWebFallback(
                    pdfBytes: _pdfData,
                    sourceUrl: resume.sourceUrl,
                    zoom: _zoom,
                  )
                : PdfPages(
                    pdfData: _pdfData!,
                    zoom: _zoom,
                    isSidebarOpen: _isSidebarOpen,
                    onNumPagesKnown: (n) => setState(() => _pdfPageCount = n),
                    onNativeFailed: () => setState(() => _useWebFallback = true),
                  ),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: ResumeZoomControls(
              zoom: _zoom,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),
        ],
      );
    }

    return _noPreviewState();
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              ResumeIcons.resumeEmpty,
              width: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Start creating your resume',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a method to begin. AI will help generate and optimize your resume content.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: widget.onCreateOpen,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF5F4F0),
                foregroundColor: const Color(0xFF2C2B2A),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const ResumeSvgIcon(ResumeIcons.upload, size: 16),
              label: const Text(
                'Upload existing resume (PDF/DOCX)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF171717),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Converting your file...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your document is being converted to PDF. This view refreshes automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _noPreviewState() {
    return ColoredBox(
      color: DinqTokens.bgPage,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ResumeSvgIcon(
                  ResumeIcons.fileText,
                  size: 28,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No preview available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload a file to get started.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
