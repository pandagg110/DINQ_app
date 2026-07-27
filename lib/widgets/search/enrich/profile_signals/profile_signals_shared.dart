import 'package:flutter/material.dart';

import '../../../common/metric_display.dart';

class ProfileSignalsSectionHeader extends StatelessWidget {
  const ProfileSignalsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: Color(0xFF9E9A94),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: Color(0xFFF0EEEA), height: 1, thickness: 1),
          ),
        ],
      ),
    );
  }
}

class ProfileSignalFrame extends StatelessWidget {
  const ProfileSignalFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final minHeight = width.isFinite && width > 0 ? width : 320.0;

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBE8E2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ProfileSignalSkeleton extends StatelessWidget {
  const ProfileSignalSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSignalFrame(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4F0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 148,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  4,
                  (_) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEBE8E2)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD8D5CF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSignalMetricTile extends StatelessWidget {
  const ProfileSignalMetricTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      child: MetricDisplay(
        label: label,
        value: value,
        align: MetricAlign.start,
      ),
    );
  }
}

Widget buildProfileSignalOrgLogo({
  required String? logo,
  required String name,
  double size = 32,
}) {
  final displayLogo =
      (logo?.isNotEmpty == true) ? logo! : '/images/defaultCompany.png';

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey[100],
      border: Border.all(color: const Color(0xFF171717), width: 1),
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
              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.business, size: 16),
              );
            },
          );
        },
      ),
    ),
  );
}
