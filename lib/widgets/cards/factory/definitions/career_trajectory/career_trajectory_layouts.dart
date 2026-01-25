import 'package:flutter/material.dart';
import 'career_trajectory_constants.dart';
import 'career_trajectory_segments.dart';
import 'career_flow_diagram.dart';

class CareerTrajectoryLayouts {
  static Widget build2x2Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> sortedSegments,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    final largestSegment = sortedSegments.last;
    final largestRepresentative = largestSegment['representative'] as Map<String, dynamic>?;
    final hasLargestRepresentative = largestRepresentative != null && 
                                     largestRepresentative['name'] != 'Unknown';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title - Two lines
          const Text(
            'Career\nTrajectory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar and Category
                if (hasLargestRepresentative)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          (largestSegment['category'] as String? ?? '')
                              .isEmpty
                              ? ''
                              : (largestSegment['category'] as String)
                                  .substring(0, 1)
                                  .toUpperCase() +
                                  (largestSegment['category'] as String)
                                      .substring(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          backgroundImage: (largestRepresentative['avatarUrl'] as String?) != null
                              ? NetworkImage(largestRepresentative['avatarUrl'] as String)
                              : null,
                          child: (largestRepresentative['avatarUrl'] as String?) == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                
                // Horizontal Stacked Bar
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      for (int index = 0; index < sortedSegments.length; index++)
                        CareerTrajectorySegments.buildSegmentBar(
                          context: context,
                          segment: sortedSegments[index],
                          index: index,
                          totalSegments: sortedSegments.length,
                          color: CareerTrajectoryConstants.colors[index],
                          activeSegmentKey: activeSegmentKey,
                          onHover: onHover,
                          onHoverEnd: onHoverEnd,
                          onOpenModal: onOpenModal,
                          isHorizontal: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget build2x4Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> sortedSegments,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Career\nTrajectory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vertical Stacked Bar
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      for (int index = 0; index < sortedSegments.length; index++)
                        Expanded(
                          flex: (sortedSegments[index]['percentage'] as num).toInt(),
                          child: CareerTrajectorySegments.buildSegmentBar(
                            context: context,
                            segment: sortedSegments[index],
                            index: index,
                            totalSegments: sortedSegments.length,
                            color: CareerTrajectoryConstants.colors[index],
                            activeSegmentKey: activeSegmentKey,
                            onHover: onHover,
                            onHoverEnd: onHoverEnd,
                            onOpenModal: onOpenModal,
                            isHorizontal: false,
                            showPercentage: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Category Labels with Avatars
                Expanded(
                  child: Column(
                    children: [
                      for (int index = 0; index < sortedSegments.length; index++)
                        Expanded(
                          flex: (sortedSegments[index]['percentage'] as num).toInt(),
                          child: CareerTrajectorySegments.buildSegmentLabel(
                            context: context,
                            segment: sortedSegments[index],
                            index: index,
                            color: CareerTrajectoryConstants.colors[index],
                            activeSegmentKey: activeSegmentKey,
                            onHover: onHover,
                            onHoverEnd: onHoverEnd,
                            onOpenModal: onOpenModal,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget build4x2Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> sortedSegments,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Career Trajectory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatars Row
                SizedBox(
                  height: 32,
                  child: Stack(
                    children: [
                      for (int index = 0; index < sortedSegments.length; index++)
                        CareerTrajectorySegments.buildAvatarPositioned(
                          context: context,
                          segment: sortedSegments[index],
                          index: index,
                          sortedSegments: sortedSegments,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Horizontal Stacked Bar with Percentages
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      for (int index = 0; index < sortedSegments.length; index++)
                        CareerTrajectorySegments.buildSegmentBar(
                          context: context,
                          segment: sortedSegments[index],
                          index: index,
                          totalSegments: sortedSegments.length,
                          color: CareerTrajectoryConstants.colors[index],
                          activeSegmentKey: activeSegmentKey,
                          onHover: onHover,
                          onHoverEnd: onHoverEnd,
                          onOpenModal: onOpenModal,
                          isHorizontal: true,
                          showPercentage: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget build4x4Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> sortedSegments,
    required String? activeSegmentKey,
    required Function(String, Offset, Size) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, Map<String, dynamic>, String) onOpenModal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Career Trajectory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Vertical Stacked Bar
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      for (int index = 0; index < sortedSegments.length; index++)
                        Expanded(
                          flex: (sortedSegments[index]['percentage'] as num).toInt(),
                          child: CareerTrajectorySegments.buildSegmentBar(
                            context: context,
                            segment: sortedSegments[index],
                            index: index,
                            totalSegments: sortedSegments.length,
                            color: CareerTrajectoryConstants.colors[index],
                            activeSegmentKey: activeSegmentKey,
                            onHover: onHover,
                            onHoverEnd: onHoverEnd,
                            onOpenModal: onOpenModal,
                            isHorizontal: false,
                            showPercentage: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                // Right Column: Flow Diagram Background + Annotations
                Expanded(
                  child: Stack(
                    children: [
                      // Flow Diagram Background
                      Positioned.fill(
                        child: CareerFlowDiagram(
                          careerA: (sortedSegments[0]['percentage'] as num?)?.toDouble() ?? 0,
                          careerB: (sortedSegments[1]['percentage'] as num?)?.toDouble() ?? 0,
                          careerC: (sortedSegments[2]['percentage'] as num?)?.toDouble() ?? 0,
                          colors: CareerTrajectoryConstants.colors,
                        ),
                      ),
                      
                      // Annotations Overlay
                      Column(
                        children: [
                          for (int index = 0; index < sortedSegments.length; index++)
                            Expanded(
                              flex: (sortedSegments[index]['percentage'] as num).toInt(),
                              child: CareerTrajectorySegments.buildSegmentAnnotation(
                                context: context,
                                segment: sortedSegments[index],
                                index: index,
                                color: CareerTrajectoryConstants.colors[index],
                                activeSegmentKey: activeSegmentKey,
                                onHover: onHover,
                                onHoverEnd: onHoverEnd,
                                onOpenModal: onOpenModal,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

