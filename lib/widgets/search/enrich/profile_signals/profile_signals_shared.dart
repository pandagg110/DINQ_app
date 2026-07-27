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

  static const _borderColor = Color(0xFFEBE8E2);
  static const _buttonBorderColor = Color(0xFFD8D5CF);
  static const _fillColor = Color(0xFFF5F4F0);
  static const _summaryBg = Color(0xFFF6F6F6);

  @override
  Widget build(BuildContext context) {
    return ProfileSignalFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 320.0;

          return SizedBox(
            height: side,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _skeletonBar(width: 40, height: 40, radius: 12),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _metricTile()),
                              const SizedBox(width: 8),
                              Expanded(child: _metricTile()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _metricTile()),
                              const SizedBox(width: 8),
                              Expanded(child: _metricTile()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _summaryBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _skeletonBar(height: 16),
                        const SizedBox(height: 8),
                        _skeletonBar(height: 16, widthFactor: 0.86),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _buttonBorderColor, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _skeletonBar(width: 16, height: 16, radius: 4),
                        const SizedBox(width: 8),
                        _skeletonBar(width: 64, height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metricTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _skeletonBar(width: 80, height: 12),
          const SizedBox(height: 8),
          _skeletonBar(width: 40, height: 24),
        ],
      ),
    );
  }

  Widget _skeletonBar({
    double? width,
    double height = 12,
    double widthFactor = 1,
    double radius = 4,
  }) {
    if (width != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _fillColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _fillColor,
          borderRadius: BorderRadius.circular(radius),
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
