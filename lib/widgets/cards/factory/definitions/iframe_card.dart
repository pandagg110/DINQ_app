import 'package:flutter/material.dart';
import '../card_definition.dart';

class IframeCardDefinition extends CardDefinition {
  @override
  String get type => 'IFRAME';

  @override
  String get icon => 'i-mdi:iframe-brackets-outline';

  @override
  String get name => 'Iframe';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
      );

  @override
  Widget render(CardRenderParams params) {
    final url = params.card.data.metadata['url']?.toString() ?? '';
    
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, size: 48, color: Color(0xFF6B7280)),
              SizedBox(height: 8),
              Text(
                'No iframe URL',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Note: Flutter WebView requires webview_flutter package
    // For now, show a placeholder with the URL
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code, size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                url,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Iframe content',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

