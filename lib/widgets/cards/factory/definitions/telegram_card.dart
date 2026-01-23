import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class TelegramCardDefinition extends CardDefinition {
  @override
  String get type => 'TELEGRAM';

  @override
  String get icon => '/icons/social-icons/Telegram.svg';

  @override
  String get name => 'Telegram';

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
  Future<Map<String, dynamic>>? create() async {
    return {
      'username': '',
      'imageUrl': '',
    };
  }

  @override
  String? validate(Map<String, dynamic> metadata) {
    final username = metadata['username']?.toString() ?? '';
    if (username.trim().isEmpty) {
      return 'Telegram username is required';
    }
    return null; // Validation passed
  }

  @override
  Widget render(CardRenderParams params) {
    final username = params.card.data.metadata['username']?.toString() ?? '';
    final imageUrl = params.card.data.metadata['imageUrl']?.toString();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Telegram.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            username.isNotEmpty ? '@$username' : 'Telegram',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

