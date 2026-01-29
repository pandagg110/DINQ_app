import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'career_trajectory_constants.dart';

class CareerTrajectorySegments {
  static Widget buildSegmentBar({
    required BuildContext context,
    required Map<String, dynamic> segment,
    required int index,
    required int totalSegments,
    required String color,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
    required bool isHorizontal,
    bool showPercentage = false,
  }) {
    final segmentKey = '${segment['category']}-$index';
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';
    final isActive = hasRepresentative && activeSegmentKey == segmentKey;
    final percentage = (segment['percentage'] as num?)?.toDouble() ?? 0.0;
    
    Widget content = showPercentage
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          )
        : const SizedBox.shrink();

    Widget barWidget = Container(
      decoration: BoxDecoration(
        color: CareerTrajectoryConstants.parseColor(color),
        border: Border(
          top: const BorderSide(color: Colors.black, width: 1),
          left: const BorderSide(color: Colors.black, width: 1),
          right: index < totalSegments - 1 && isHorizontal
              ? const BorderSide(color: Colors.black, width: 1)
              : const BorderSide(color: Colors.black, width: 1),
          bottom: index < totalSegments - 1 && !isHorizontal
              ? const BorderSide(color: Colors.black, width: 1)
              : const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Center(child: content),
    );

    if (!hasRepresentative) {
      return isHorizontal
          ? Expanded(flex: (percentage * 100).toInt(), child: barWidget)
          : barWidget;
    }

    return isHorizontal
        ? Expanded(
            flex: (percentage * 100).toInt(),
            child: buildInteractiveSegment(
              context: context,
              child: barWidget,
              segmentKey: segmentKey,
              segment: segment,
              representative: representative,
              color: color,
              isActive: isActive,
              onHover: onHover,
              onHoverEnd: onHoverEnd,
              onOpenModal: onOpenModal,
            ),
          )
        : buildInteractiveSegment(
            context: context,
            child: barWidget,
            segmentKey: segmentKey,
            segment: segment,
            representative: representative,
            color: color,
            isActive: isActive,
            onHover: onHover,
            onHoverEnd: onHoverEnd,
            onOpenModal: onOpenModal,
          );
  }

  static Widget buildInteractiveSegment({
    required BuildContext context,
    required Widget child,
    required String segmentKey,
    required Map<String, dynamic> segment,
    required Map<String, dynamic> representative,
    required String color,
    required bool isActive,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    return MouseRegion(
      onEnter: (event) {
        if (!kIsWeb) return;
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          onHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onHover: (event) {
        if (!kIsWeb) return;
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          onHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onExit: (_) => onHoverEnd(),
      child: GestureDetector(
        onTap: () => onOpenModal(segment, representative, color),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.7,
          child: child,
        ),
      ),
    );
  }

  static Widget buildSegmentLabel({
    required BuildContext context,
    required Map<String, dynamic> segment,
    required int index,
    required String color,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    final segmentKey = '${segment['category']}-$index';
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';
    final isActive = hasRepresentative && activeSegmentKey == segmentKey;

    if (!hasRepresentative) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (event) {
        if (!kIsWeb) return;
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          onHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onHover: (event) {
        if (!kIsWeb) return;
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          onHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onExit: (_) => onHoverEnd(),
      child: GestureDetector(
        onTap: () => onOpenModal(segment, representative, color),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.85,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                backgroundImage: (representative['avatarUrl'] as String?) != null
                    ? NetworkImage(representative['avatarUrl'] as String)
                    : null,
                child: (representative['avatarUrl'] as String?) == null
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildAvatarPositioned({
    required BuildContext context,
    required Map<String, dynamic> segment,
    required int index,
    required List<Map<String, dynamic>> sortedSegments,
  }) {
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';

    if (!hasRepresentative) {
      return const SizedBox.shrink();
    }

    // Calculate center position
    double previousPercentage = 0;
    for (int i = 0; i < index; i++) {
      previousPercentage += (sortedSegments[i]['percentage'] as num?)?.toDouble() ?? 0;
    }
    final centerPosition = previousPercentage + ((segment['percentage'] as num?)?.toDouble() ?? 0) / 2;

    return Positioned(
      left: (centerPosition / 100) * MediaQuery.of(context).size.width - 16,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        backgroundImage: (representative['avatarUrl'] as String?) != null
            ? NetworkImage(representative['avatarUrl'] as String)
            : null,
        child: (representative['avatarUrl'] as String?) == null
            ? const Icon(Icons.person, size: 16)
            : null,
      ),
    );
  }

  static Widget buildSegmentAnnotation({
    required BuildContext context,
    required Map<String, dynamic> segment,
    required int index,
    required String color,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    final segmentKey = '${segment['category']}-$index';
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';
    final isActive = hasRepresentative && activeSegmentKey == segmentKey;
    final category = segment['category'] as String? ?? '';

    return MouseRegion(
      onEnter: (event) {
        if (!kIsWeb) return;
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          onHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onHover: (event) {
        if (!kIsWeb) return;
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          onHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onExit: (_) => onHoverEnd(),
      child: GestureDetector(
        onTap: () {
          if (hasRepresentative) {
            onOpenModal(segment, representative, color);
          }
        },
        child: Opacity(
          opacity: isActive ? 1.0 : 0.85,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasRepresentative)
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: (representative['avatarUrl'] as String?) != null
                      ? NetworkImage(representative['avatarUrl'] as String)
                      : null,
                  child: (representative['avatarUrl'] as String?) == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
              if (hasRepresentative) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.isEmpty
                          ? ''
                          : category.substring(0, 1).toUpperCase() + category.substring(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171717),
                      ),
                    ),
                    if (hasRepresentative) ...[
                      const SizedBox(height: 4),
                      Text(
                        (representative['name'] as String?) ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171717),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (representative['dinq'] ?? representative['position'] ?? '') as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

