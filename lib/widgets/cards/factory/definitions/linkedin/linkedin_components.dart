import 'package:flutter/material.dart';
import 'linkedin_utils.dart';

class LinkedInComponents {
  // Organization Logo component
  static Widget buildOrgLogo({
    required String? logo,
    required String name,
    String size = 'md',
  }) {
    final sizeValue = size == 'sm' ? 20.0 : size == 'lg' ? 40.0 : 32.0;
    final displayLogo = (logo?.isNotEmpty == true) ? logo! : '/images/defaultCompany.png';

    return Container(
      width: sizeValue,
      height: sizeValue,
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

  // Avatar Group for 2x2 layout
  static Widget buildAvatarGroup({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    return Wrap(
      spacing: -16,
      children: careerJourney.take(7).map((item) {
        return Container(
          margin: const EdgeInsets.only(right: 16),
          child: buildOrgLogo(
            logo: item['logo']?.toString(),
            name: item['name']?.toString() ?? '',
            size: 'md',
          ),
        );
      }).toList(),
    );
  }

  // Vertical Timeline for 2x4 layout
  static Widget buildVerticalTimeline({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    if (careerJourney.isEmpty) {
      return const Center(child: Text('No career data'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        
        // Calculate positions based on years
        final years = careerJourney.map((item) => item['year'] as int).toList();
        final minYear = years.reduce((a, b) => a < b ? a : b);
        final maxYear = years.reduce((a, b) => a > b ? a : b);
        final yearSpan = maxYear - minYear;

        // Calculate positions
        List<double> positions;
        if (yearSpan == 0 || careerJourney.length == 1) {
          if (careerJourney.length == 1) {
            positions = [0.5];
          } else {
            positions = List.generate(
              careerJourney.length,
              (i) => i / (careerJourney.length - 1),
            );
          }
        } else {
          final minSpan = yearSpan > (careerJourney.length - 1) * 3
              ? yearSpan
              : (careerJourney.length - 1) * 3;
          final maxSpan = (careerJourney.length - 1) * 6;
          final normalizedSpan = minSpan < maxSpan ? minSpan : maxSpan;

          positions = careerJourney.map((item) {
            final yearOffset = (item['year'] as int) - minYear;
            final scaledOffset = (yearOffset / yearSpan) * normalizedSpan;
            return scaledOffset / normalizedSpan;
          }).toList();
        }

        // Adjust positions for minimum spacing
        const minGapPx = 48.0;
        final minGapPercent = (minGapPx / height) * 100;

        final adjustedPositions = [...positions];
        for (int i = 1; i < adjustedPositions.length; i++) {
          final prevPos = adjustedPositions[i - 1];
          final currentPos = adjustedPositions[i];
          final gap = (currentPos - prevPos) * 100;

          if (gap < minGapPercent) {
            adjustedPositions[i] = prevPos + minGapPercent / 100;
          }
        }

        // Normalize to fit within safe margins (5% to 95%)
        const safeMargin = 5.0;
        const usableRange = 90.0;
        final minPos = adjustedPositions.reduce((a, b) => a < b ? a : b);
        final maxPos = adjustedPositions.reduce((a, b) => a > b ? a : b);
        final posRange = maxPos - minPos;

        final finalPositions = adjustedPositions.map((pos) {
          if (careerJourney.length == 1) return height * 0.5;
          final normalized = (pos - minPos) / posRange;
          return (safeMargin + normalized * usableRange) / 100 * height;
        }).toList();

        return Stack(
          children: [
            // Vertical Timeline Line
            if (careerJourney.length > 1)
              Positioned(
                left: 16,
                top: finalPositions[0],
                bottom: height - finalPositions[finalPositions.length - 1],
                child: Container(
                  width: 1,
                  color: const Color(0xFF171717),
                ),
              ),
            
            // Timeline Nodes
            ...careerJourney.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Positioned(
                left: 0,
                top: finalPositions[index] - 16,
                child: Row(
                  children: [
                    buildOrgLogo(
                      logo: item['logo']?.toString(),
                      name: item['name']?.toString() ?? '',
                      size: 'md',
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item['year']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // Horizontal Timeline for 4x2 layout
  static Widget buildHorizontalTimeline({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    if (careerJourney.isEmpty) {
      return const Center(child: Text('No career data'));
    }

    // Calculate positions (similar logic to vertical)
    final years = careerJourney.map((item) => item['year'] as int).toList();
    final minYear = years.reduce((a, b) => a < b ? a : b);
    final maxYear = years.reduce((a, b) => a > b ? a : b);
    final yearSpan = maxYear - minYear;

    List<double> positions;
    if (yearSpan == 0) {
      if (careerJourney.length == 1) {
        positions = [0.0];
      } else {
        positions = List.generate(
          careerJourney.length,
          (i) => i / (careerJourney.length - 1),
        );
      }
    } else {
      final minSpan = yearSpan > (careerJourney.length - 1) * 4
          ? yearSpan
          : (careerJourney.length - 1) * 4;
      final maxSpan = (careerJourney.length - 1) * 8;
      final normalizedSpan = minSpan < maxSpan ? minSpan : maxSpan;

      positions = careerJourney.map((item) {
        final yearOffset = (item['year'] as int) - minYear;
        final scaledOffset = (yearOffset / yearSpan) * normalizedSpan;
        return scaledOffset / normalizedSpan;
      }).toList();
    }

    // Adjust for minimum spacing
    const estimatedWidth = 600.0;
    const minGapPx = 72.0;
    final minGapPercent = (minGapPx / estimatedWidth) * 100;

    final adjustedPositions = [...positions];
    for (int i = 1; i < adjustedPositions.length; i++) {
      final prevPos = adjustedPositions[i - 1];
      final currentPos = adjustedPositions[i];
      final gap = (currentPos - prevPos) * 100;

      if (gap < minGapPercent) {
        adjustedPositions[i] = prevPos + minGapPercent / 100;
      }
    }

    // Normalize
    const safeMargin = 5.0;
    const usableRange = 90.0;
    final minPos = adjustedPositions.reduce((a, b) => a < b ? a : b);
    final maxPos = adjustedPositions.reduce((a, b) => a > b ? a : b);
    final posRange = maxPos - minPos;

    final finalPositions = adjustedPositions.map((pos) {
      if (careerJourney.length == 1) return 50.0;
      final normalized = (pos - minPos) / posRange;
      return safeMargin + normalized * usableRange;
    }).toList();

    return Stack(
      children: [
        // Horizontal Timeline Line
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Container(
            height: 1,
            color: const Color(0xFF171717),
          ),
        ),
        
        // Timeline Nodes
        ...careerJourney.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Positioned(
            left: finalPositions[index] - 16,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildOrgLogo(
                  logo: item['logo']?.toString(),
                  name: item['name']?.toString() ?? '',
                  size: 'md',
                ),
                const SizedBox(height: 8),
                Text(
                  '${item['year']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Career Chart for 4x4 layout (simplified - just show list for now)
  static Widget buildCareerChart({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    // For now, show a simple list view
    // In a full implementation, this would use a chart library like fl_chart
    return ListView.builder(
      itemCount: careerJourney.length,
      itemBuilder: (context, index) {
        final item = careerJourney[index];
        return ListTile(
          leading: buildOrgLogo(
            logo: item['logo']?.toString(),
            name: item['name']?.toString() ?? '',
            size: 'sm',
          ),
          title: Text(item['name']?.toString() ?? ''),
          subtitle: Text(
            '${item['position']} • ${formatDuration(item['duration']?.toString() ?? '')}',
          ),
          trailing: Text(
            '${item['year']}',
            style: const TextStyle(color: Color(0xFF9CA3AF)),
          ),
        );
      },
    );
  }
}

