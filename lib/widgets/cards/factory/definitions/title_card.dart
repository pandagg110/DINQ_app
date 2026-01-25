import 'package:flutter/material.dart';
import '../card_definition.dart';

class TitleCardDefinition extends CardDefinition {
  @override
  String get type => 'TITLE';

  @override
  String get icon => 'i-lucide-heading';

  @override
  String get name => 'Title';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['8x1'],
          defaultSize: '8x1',
        ),
        mobile: CardSizeConfig(
          supported: ['4x1'],
          defaultSize: '4x1',
        ),
      );

  @override
  Future<Map<String, dynamic>>? create() async {
    return {'title': ''};
  }

  @override
  Widget render(CardRenderParams params) {
    final title = params.card.data.metadata['title']?.toString() ?? '';
    final placeholderText = 'Add a title...';
    final displayText = title.isEmpty ? placeholderText : title;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: title.isEmpty
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF111827),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
