import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../theme/dinq_tokens.dart';

/// pdfx 是否因原生通道不可用而失败。
bool isPdfxChannelError(Object error) {
  if (error is PlatformException) {
    return error.code == 'channel-error' ||
        (error.message ?? '').contains('Unable to establish connection');
  }
  return error.toString().contains('channel-error');
}

/// pdfx 原生通道不可用时的 PDF 预览降级（WebView + HTML embed）。
class ResumePdfWebFallback extends StatefulWidget {
  const ResumePdfWebFallback({
    super.key,
    this.pdfBytes,
    this.sourceUrl,
    this.zoom = 1,
  });

  final Uint8List? pdfBytes;
  final String? sourceUrl;
  final double zoom;

  @override
  State<ResumePdfWebFallback> createState() => _ResumePdfWebFallbackState();
}

class _ResumePdfWebFallbackState extends State<ResumePdfWebFallback> {
  WebViewController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(DinqTokens.bgPage);

      if (widget.pdfBytes != null && widget.pdfBytes!.isNotEmpty) {
        final b64 = base64Encode(widget.pdfBytes!);
        await controller.loadHtmlString(_pdfEmbedHtml(b64));
      } else if (widget.sourceUrl != null && widget.sourceUrl!.isNotEmpty) {
        final encoded = Uri.encodeComponent(widget.sourceUrl!);
        await controller.loadRequest(
          Uri.parse(
            'https://docs.google.com/gviewer?embedded=true&url=$encoded',
          ),
        );
      } else {
        throw Exception('No PDF source');
      }

      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String _pdfEmbedHtml(String base64Pdf) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
<style>
  html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #F5F4F0; overflow: auto; }
  embed, iframe { display: block; width: 100%; min-height: 100vh; border: 0; }
</style>
</head>
<body>
<embed src="data:application/pdf;base64,$base64Pdf" type="application/pdf" />
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'Unable to preview PDF',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final viewportH = constraints.maxHeight;
        final zoom = widget.zoom;
        final contentW = viewportW * zoom;
        final contentH = viewportH * zoom;

        return ColoredBox(
          color: DinqTokens.bgPage,
          child: ClipRect(
            child: SizedBox(
              width: viewportW,
              height: viewportH,
              child: SingleChildScrollView(
                primary: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: SizedBox(
                    width: math.max(contentW, viewportW),
                    height: math.max(contentH, viewportH),
                    child: Center(
                      child: SizedBox(
                        width: contentW,
                        height: contentH,
                        child: WebViewWidget(controller: _controller!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
