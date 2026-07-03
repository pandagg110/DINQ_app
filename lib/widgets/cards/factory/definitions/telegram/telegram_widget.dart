import 'package:flutter/material.dart';
import 'telegram_layouts.dart';

class TelegramWidget extends StatelessWidget {
  const TelegramWidget({
    super.key,
    required this.card,
    required this.size,
    required this.editable,
    required this.onUpdate,
  });

  final dynamic card;
  final String size;
  final bool editable;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final username = (metadata['username'] as String?) ?? '';
    final imageUrl = (metadata['imageUrl'] as String?) ?? '';
    void handleImageChange(String url) {
      onUpdate({...metadata, 'imageUrl': url});
    }

    switch (size) {
      case '2x2':
        return TelegramLayouts.build2x2Layout(username: username);
      case '2x4':
        return TelegramLayouts.build2x4Layout(
          username: username,
          imageUrl: imageUrl,
          editable: editable,
          onImageChange: handleImageChange,
        );
      case '4x2':
        return TelegramLayouts.build4x2Layout(
          username: username,
          imageUrl: imageUrl,
          editable: editable,
          onImageChange: handleImageChange,
        );
      case '4x4':
        return TelegramLayouts.build4x4Layout(
          username: username,
          imageUrl: imageUrl,
          editable: editable,
          onImageChange: handleImageChange,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}
