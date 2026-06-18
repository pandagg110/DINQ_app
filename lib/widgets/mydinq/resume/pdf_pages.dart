import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:synchronized/synchronized.dart';

import '../../../theme/dinq_tokens.dart';
import 'pdf_preview_skeleton.dart';
import 'resume_icons.dart';
import 'resume_pdf_web_fallback.dart';

/// Android 不允许并行渲染 PDF 页，缩略图需串行加锁。
final _pdfPageRenderLock = Lock();

/// 对齐 Web `PdfPages.tsx`：缩略图侧栏 + pdfx 原生预览 + 缩放。
class PdfPages extends StatefulWidget {
  const PdfPages({
    super.key,
    required this.pdfData,
    required this.zoom,
    this.isSidebarOpen = true,
    this.onNumPagesKnown,
    this.onNativeFailed,
  });

  final Uint8List pdfData;
  final double zoom;
  final bool isSidebarOpen;
  final ValueChanged<int>? onNumPagesKnown;
  final VoidCallback? onNativeFailed;

  @override
  State<PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<PdfPages> {
  PdfDocument? _document;
  PdfControllerPinch? _controller;
  int _numPages = 0;
  bool _loadFailed = false;
  int _activePage = 1;
  final _thumbScroll = ScrollController();

  bool get _isMobile => MediaQuery.sizeOf(context).width < 768;

  @override
  void initState() {
    super.initState();
    _openDocument();
  }

  @override
  void didUpdateWidget(covariant PdfPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pdfData, widget.pdfData)) {
      _disposeAll();
      _openDocument();
      return;
    }
    if (oldWidget.zoom != widget.zoom) {
      _applyZoomDelta(widget.zoom / oldWidget.zoom);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _thumbScroll.dispose();
    _disposeDocument();
    super.dispose();
  }

  Future<void> _openDocument() async {
    setState(() => _loadFailed = false);
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/dinq_resume_${identityHashCode(widget.pdfData)}.pdf',
      );
      await file.writeAsBytes(widget.pdfData, flush: true);
      final doc = await PdfDocument.openFile(file.path);
      if (!mounted) {
        await doc.close();
        return;
      }
      final controller = PdfControllerPinch(
        document: Future.value(doc),
        initialPage: 1,
      );
      setState(() {
        _document = doc;
        _controller = controller;
        _numPages = doc.pagesCount;
        _activePage = 1;
        _loadFailed = false;
      });
      widget.onNumPagesKnown?.call(doc.pagesCount);
    } catch (e) {
      debugPrint('PdfDocument.openFile failed: $e');
      if (mounted) {
        setState(() {
          _numPages = 0;
          _loadFailed = true;
        });
        if (isPdfxChannelError(e)) {
          widget.onNativeFailed?.call();
        }
      }
    }
  }

  Future<void> _disposeDocument() async {
    final doc = _document;
    _document = null;
    if (doc != null) await doc.close();
  }

  void _disposeAll() {
    _controller?.dispose();
    _controller = null;
    _disposeDocument();
  }

  void _applyZoomDelta(double factor) {
    final c = _controller;
    if (c == null || c.loadingState.value != PdfLoadingState.success) return;
    if ((factor - 1).abs() < 0.001) return;

    try {
      final rect = c.viewRect;
      final focal = Offset(rect.width / 2, rect.height / 2);
      final m = Matrix4.identity()
        ..translateByDouble(focal.dx, focal.dy, 0, 1)
        ..scaleByDouble(factor, factor, 1, 1)
        ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
      c.value = m * c.value;
    } catch (_) {}
  }

  void _scrollThumbIntoView(int page) {
    if (!_thumbScroll.hasClients) return;
    final target = (page - 1) * 150.0;
    _thumbScroll.animateTo(
      target.clamp(0, _thumbScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _scrollToPage(int pageNum) {
    setState(() => _activePage = pageNum);
    _controller?.animateToPage(
      pageNumber: pageNum,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  bool get _showSidebar =>
      _numPages > 1 && widget.isSidebarOpen && !_isMobile;

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return _buildLoadError();
    }
    if (_document == null || _controller == null || _numPages == 0) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ResumeSkeletonPulse(
            child: PdfPreviewSkeleton(
              showSidebar: _showSidebar,
              maxHeight: constraints.maxHeight,
            ),
          );
        },
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showSidebar) _buildThumbSidebar(),
        Expanded(
          child: ColoredBox(
            color: DinqTokens.bgPage,
            child: PdfViewPinch(
              controller: _controller!,
              padding: _isMobile ? 12 : 24,
              minScale: 0.5,
              maxScale: 6,
              scrollDirection: Axis.vertical,
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              onPageChanged: (page) {
                if (_activePage != page) {
                  setState(() => _activePage = page);
                  _scrollThumbIntoView(page);
                }
              },
              onDocumentLoaded: (doc) {
                widget.onNumPagesKnown?.call(doc.pagesCount);
                if (widget.zoom != 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _applyZoomDelta(widget.zoom);
                  });
                }
              },
              onDocumentError: (error) {
                debugPrint('PdfViewPinch error: $error');
                if (isPdfxChannelError(error)) {
                  widget.onNativeFailed?.call();
                } else if (mounted) {
                  setState(() => _loadFailed = true);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbSidebar() {
    return SizedBox(
      width: 140,
      child: ListView.builder(
        controller: _thumbScroll,
        padding: const EdgeInsets.all(12),
        itemCount: _numPages,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final isActive = _activePage == pageNum;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _scrollToPage(pageNum),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFF5F5F4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isActive
                          ? Border.all(color: const Color(0x99D6D3D1), width: 2)
                          : null,
                    ),
                    child: _PdfThumbImage(
                      document: _document!,
                      pageNumber: pageNum,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$pageNum',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF57534E)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadError() {
    return ColoredBox(
      color: DinqTokens.bgPage,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ResumeSvgIcon(ResumeIcons.fileText, size: 28, color: Color(0xFF6B7280)),
            SizedBox(height: 12),
            Text(
              'Failed to open PDF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfThumbImage extends StatefulWidget {
  const _PdfThumbImage({
    required this.document,
    required this.pageNumber,
  });

  final PdfDocument document;
  final int pageNumber;

  @override
  State<_PdfThumbImage> createState() => _PdfThumbImageState();
}

class _PdfThumbImageState extends State<_PdfThumbImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    await _pdfPageRenderLock.synchronized(() async {
      if (!mounted) return;
      try {
        const thumbW = 90.0;
        final page = await widget.document.getPage(widget.pageNumber);
        final scale = thumbW / page.width;
        final h = page.height * scale;
        PdfPageImage? image;
        try {
          image = await page.render(
            width: thumbW * 2,
            height: h * 2,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#ffffff',
          );
        } finally {
          await page.close();
        }
        if (!mounted) return;
        setState(() {
          _bytes = image?.bytes;
          _failed = image == null;
        });
      } catch (e) {
        debugPrint('Thumb page ${widget.pageNumber} render failed: $e');
        if (mounted) setState(() => _failed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return SizedBox(
        width: 90,
        height: _failed ? 90 : 126,
        child: _failed
            ? const Center(
                child: ResumeSvgIcon(
                  ResumeIcons.fileText,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              )
            : const ColoredBox(color: Color(0xFFEEEDE9)),
      );
    }
    return Image.memory(_bytes!, width: 90, fit: BoxFit.fitWidth, gaplessPlayback: true);
  }
}

/// 对齐 Web ResumePreview zoom controls。
class ResumeZoomControls extends StatelessWidget {
  const ResumeZoomControls({
    super.key,
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            onTap: onZoomIn,
            enabled: zoom < 3,
            icon: ResumeIcons.zoomIn,
            label: 'Zoom in',
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: const Color(0xFFE5E7EB),
          ),
          _ZoomButton(
            onTap: onZoomOut,
            enabled: zoom > 0.5,
            icon: ResumeIcons.zoomOut,
            label: 'Zoom out',
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.onTap,
    required this.enabled,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 32,
          height: 28,
          child: Center(
            child: ResumeSvgIcon(
              icon,
              size: 16,
              color: enabled
                  ? const Color(0xFF5F5E5B)
                  : const Color(0xFF5F5E5B).withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
