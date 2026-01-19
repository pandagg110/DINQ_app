import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../utils/asset_path.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.position});

  final String? position;

  @override
  Widget build(BuildContext context) {
    final isAnalysis = position == 'analysis';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isAnalysis ? 24 : 32),
      color: isAnalysis ? const Color(0xFFF9F9F9) : const Color(0xFFA6C0CC),
      child: Column(
        children: [
          if (!isAnalysis) _buildTopLinks(context),
          Divider(color: const Color(0xFF171717).withOpacity(0.8)),
          const SizedBox(height: 12),
          if (MediaQuery.of(context).size.width < 900) _buildSocialRow(iconSize: 28),
          if (MediaQuery.of(context).size.width < 900) const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'Copyright ? 2026 DINQ Inc. All rights reserved',
                style: TextStyle(fontSize: 14, color: Color(0xFF171717)),
                textAlign: TextAlign.center,
              ),
              if (isAnalysis && MediaQuery.of(context).size.width >= 900)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSocialRow(iconSize: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopLinks(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Column(
      children: [
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _FooterLink(label: 'Terms of Use', path: '/terms'),
                  _FooterLink(label: 'Privacy Policy', path: '/privacy'),
                  _FooterLink(label: 'Cookie Policy', path: '/cookies'),
                  _FooterLink(label: 'Community Guidelines', path: '/guidelines'),
                  _FooterLink(label: 'Contact Us', onTap: () => _showContactModal(context)),
                ],
              ),
              _buildSocialRow(iconSize: 28),
            ],
          )
        else
          Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FooterLink(label: 'Terms of Use', path: '/terms'),
                  _FooterLink(label: 'Privacy Policy', path: '/privacy'),
                  _FooterLink(label: 'Cookie Policy', path: '/cookies'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _FooterLink(label: 'Community Guidelines', path: '/guidelines'),
                  _FooterLink(label: 'Contact Us', onTap: () => _showContactModal(context)),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }

  Widget _buildSocialRow({required double iconSize}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SocialIcon(
          asset: 'images/landing/footer-x.svg',
          size: iconSize,
          url: 'https://x.com/dinq_me',
        ),
        const SizedBox(width: 12),
        _SocialIcon(
          asset: 'icons/social-icons-line/discord.svg',
          size: iconSize,
          url: 'https://discord.gg/dgkW7ej2bj',
        ),
        const SizedBox(width: 12),
        _SocialIcon(
          asset: 'icons/social-icons-line/youtube.svg',
          size: iconSize,
          url: 'https://www.youtube.com/@DINQ-e5o',
        ),
      ],
    );
  }

  void _showContactModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ContactDialog(),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.path, this.onTap});

  final String label;
  final String? path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap ?? (path != null ? () => context.go(path!) : null),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF171717),
        textStyle: const TextStyle(fontSize: 14),
      ),
      child: Text(label),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.asset, required this.size, required this.url});

  final String asset;
  final double size;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: SvgPicture.asset(
        assetPath(asset),
        width: size,
        height: size,
      ),
    );
  }
}

class _ContactDialog extends StatelessWidget {
  const _ContactDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contact Us', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _ContactRow(label: 'Company', value: 'DINQ LABS INC'),
            const _ContactRow(label: 'Address', value: '8 THE GREEN SUITE B, DOVER, DE 19901'),
            _ContactRow(
              label: 'Email',
              value: 'support@dinqlabs.com',
              isLink: true,
              onTap: () => launchUrl(Uri.parse('mailto:support@dinqlabs.com')),
            ),
            _ContactRow(
              label: 'Phone',
              value: '+1 (661) 750-9241',
              isLink: true,
              onTap: () => launchUrl(Uri.parse('tel:+16617509241')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.value, this.isLink = false, this.onTap});

  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: GestureDetector(
              onTap: isLink ? onTap : null,
              child: Text(
                value,
                style: TextStyle(
                  decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                  color: const Color(0xFF171717),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


