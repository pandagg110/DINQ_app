import 'package:flutter/material.dart';
import 'telegram_layouts.dart';

class TelegramWidget extends StatelessWidget {
  const TelegramWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final username = (metadata['username'] as String?) ?? '';
    final imageUrl = (metadata['imageUrl'] as String?) ?? '';

    switch (size) {
      case '2x2':
        return TelegramLayouts.build2x2Layout(
          username: username,
        );
      case '2x4':
        return TelegramLayouts.build2x4Layout(
          username: username,
          imageUrl: imageUrl,
        );
      case '4x2':
        return TelegramLayouts.build4x2Layout(
          username: username,
          imageUrl: imageUrl,
        );
      case '4x4':
        return TelegramLayouts.build4x4Layout(
          username: username,
          imageUrl: imageUrl,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

