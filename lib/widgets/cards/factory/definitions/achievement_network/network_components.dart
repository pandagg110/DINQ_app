import 'package:flutter/material.dart';

/// Company logo badge component
class CompanyLogoBadge extends StatelessWidget {
  const CompanyLogoBadge({
    super.key,
    this.logoUrl,
    this.size = 'md',
  });

  final String? logoUrl;
  final String size; // 'sm' or 'md'

  @override
  Widget build(BuildContext context) {
    final badgeSize = size == 'sm' ? 16.0 : 20.0;
    final displayLogo = logoUrl != null && logoUrl!.trim().isNotEmpty
        ? logoUrl!
        : '/images/defaultCompany.png';

    return Positioned(
      bottom: -4,
      right: -4,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: ClipOval(
          child: Image.network(
            displayLogo,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/defaultCompany.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

