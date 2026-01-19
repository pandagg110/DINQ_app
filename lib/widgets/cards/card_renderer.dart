import 'package:flutter/material.dart';
import '../../models/card_models.dart';
import '../common/asset_icon.dart';

class CardRenderer extends StatelessWidget {
  const CardRenderer({super.key, required this.card});

  final CardItem card;

  @override
  Widget build(BuildContext context) {
    final type = card.data.type.toUpperCase();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: _buildContent(type),
    );
  }

  Widget _buildContent(String type) {
    switch (type) {
      case 'TITLE':
        return _buildTitleCard();
      case 'IMAGE':
        return _buildImageCard();
      case 'LINK':
        return _buildLinkCard();
      case 'GITHUB':
        return _buildGitHubCard();
      case 'LINKEDIN':
        return _buildLinkedInCard();
      case 'TWITTER':
        return _buildTwitterCard();
      default:
        return _buildDefaultCard();
    }
  }

  Widget _buildTitleCard() {
    final title = card.data.metadata['title']?.toString() ?? card.data.title;
    final subtitle = card.data.metadata['subtitle']?.toString() ?? card.data.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildImageCard() {
    final url = card.data.metadata['url']?.toString();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, fit: BoxFit.cover),
      );
    }
    return const Center(child: Text('Image')); 
  }

  Widget _buildLinkCard() {
    final title = card.data.metadata['title']?.toString() ?? 'Link';
    final url = card.data.metadata['url']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssetIcon(asset: 'icons/link-image.svg', size: 32),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(url, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
      ],
    );
  }

  Widget _buildGitHubCard() {
    final username = card.data.metadata['username']?.toString() ?? '';
    final stars = card.data.metadata['starCount'] ?? card.data.metadata['totalStars'] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssetIcon(asset: 'icons/social-icons/Github.svg', size: 32),
        const SizedBox(height: 12),
        Text(username.isNotEmpty ? '@$username' : 'GitHub',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Stars: $stars', style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildLinkedInCard() {
    final name = card.data.metadata['name']?.toString() ?? 'LinkedIn';
    final title = card.data.metadata['title']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssetIcon(asset: 'icons/social-icons/LinkedIn.svg', size: 32),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildTwitterCard() {
    final handle = card.data.metadata['username']?.toString() ?? 'Twitter';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssetIcon(asset: 'icons/social-icons/Twitter.svg', size: 32),
        const SizedBox(height: 12),
        Text(handle.startsWith('@') ? handle : '@$handle',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDefaultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.data.type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(card.data.title, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }
}

