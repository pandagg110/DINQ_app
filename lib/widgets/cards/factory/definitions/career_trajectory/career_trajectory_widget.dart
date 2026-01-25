import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'career_trajectory_constants.dart';
import 'career_trajectory_layouts.dart';
import 'career_hover_card.dart';
import 'career_trajectory_modal.dart';

class CareerTrajectoryWidget extends StatefulWidget {
  const CareerTrajectoryWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  State<CareerTrajectoryWidget> createState() => _CareerTrajectoryWidgetState();
}

class _CareerTrajectoryWidgetState extends State<CareerTrajectoryWidget> {
  String? _activeSegmentKey;
  Offset _hoverCardOffset = Offset.zero;
  Map<String, dynamic>? _activeModal;

  void _handleOpenModal(Map<String, dynamic> segment, Map<String, dynamic> representative, String segmentColor) {
    setState(() {
      _activeModal = {
        'segment': segment,
        'representative': representative,
        'colorScheme': CareerTrajectoryConstants.getColorScheme(segmentColor),
        'colorSchemeName': CareerTrajectoryConstants.getColorSchemeName(segmentColor),
      };
    });
    _showModal();
  }

  void _showModal() {
    if (_activeModal == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => CareerTrajectoryModal(
        segment: _activeModal!['segment'] as Map<String, dynamic>,
        representative: _activeModal!['representative'] as Map<String, dynamic>,
        colorScheme: _activeModal!['colorScheme'] as Map<String, Color>,
        colorSchemeName: _activeModal!['colorSchemeName'] as String,
        onClose: () {
          Navigator.of(context).pop();
          setState(() {
            _activeModal = null;
          });
        },
      ),
    );
  }

  void _handleHover(String segmentKey, Offset localPosition, Size cardSize) {
    if (!kIsWeb) return; // Only on desktop/web
    
    setState(() {
      _activeSegmentKey = segmentKey;
      
      // Calculate hover card position (similar to TSX logic)
      const hoverCardWidth = 380.0;
      const hoverCardHeight = 350.0;
      const defaultXOffset = 20.0;
      const defaultYOffset = -110.0;
      
      final screenSize = MediaQuery.of(context).size;
      final globalPosition = localPosition;
      
      // Calculate horizontal position
      double finalXOffset = defaultXOffset;
      final hoverCardLeft = globalPosition.dx + defaultXOffset;
      final hoverCardRight = hoverCardLeft + hoverCardWidth;
      
      if (hoverCardRight > screenSize.width) {
        finalXOffset = -hoverCardWidth - 20;
      }
      if (hoverCardLeft < 0) {
        finalXOffset = 20;
      }
      
      // Calculate vertical position
      double finalYOffset = defaultYOffset;
      final hoverCardTop = globalPosition.dy + defaultYOffset;
      final hoverCardBottom = hoverCardTop + hoverCardHeight;
      
      if (hoverCardBottom > screenSize.height) {
        final alternativeTop = globalPosition.dy + 20;
        final alternativeBottom = alternativeTop + hoverCardHeight;
        if (alternativeBottom <= screenSize.height) {
          finalYOffset = 20;
        } else {
          finalYOffset = screenSize.height - globalPosition.dy - hoverCardHeight - 10;
        }
      }
      if (hoverCardTop < 0) {
        finalYOffset = 20;
      }
      
      _hoverCardOffset = Offset(
        globalPosition.dx + finalXOffset,
        globalPosition.dy + finalYOffset,
      );
    });
  }

  void _handleHoverEnd() {
    if (!kIsWeb) return;
    setState(() {
      _activeSegmentKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final segments = (widget.card.data.metadata['segments'] as List<dynamic>?) ?? [];
    // debugPrint('CareerTrajectoryWidget: segments: ${segments}');
    // debugPrint('CareerTrajectoryWidget: segments: ${widget.card.toJson().toString()}');
    if (segments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No career trajectory data',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ),
      );
    }

    // Sort segments by percentage (ascending)
    final sortedSegments = List<Map<String, dynamic>>.from(segments)
      ..sort((a, b) => ((a['percentage'] as num?) ?? 0).compareTo((b['percentage'] as num?) ?? 0));

    // Find active segment for hover popup
    int activeSegmentIndex = -1;
    for (int idx = 0; idx < sortedSegments.length; idx++) {
      if ('${sortedSegments[idx]['category']}-$idx' == _activeSegmentKey) {
        activeSegmentIndex = idx;
        break;
      }
    }
    final activeSegment = activeSegmentIndex >= 0 ? sortedSegments[activeSegmentIndex] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content based on size
            _buildContent(sortedSegments),
            
            // Hover popup (desktop only)
            if (kIsWeb && activeSegment != null && activeSegmentIndex >= 0)
              Positioned(
                left: _hoverCardOffset.dx,
                top: _hoverCardOffset.dy,
                child: CareerHoverCard(
                  representative: activeSegment['representative'] as Map<String, dynamic>,
                  segment: activeSegment,
                  colorScheme: CareerTrajectoryConstants.getColorScheme(
                    CareerTrajectoryConstants.colors[activeSegmentIndex],
                  ),
                  colorSchemeName: CareerTrajectoryConstants.getColorSchemeName(
                    CareerTrajectoryConstants.colors[activeSegmentIndex],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> sortedSegments) {
    switch (widget.size) {
      case '2x2':
        return CareerTrajectoryLayouts.build2x2Layout(
          context: context,
          sortedSegments: sortedSegments,
          activeSegmentKey: _activeSegmentKey,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      case '2x4':
        return CareerTrajectoryLayouts.build2x4Layout(
          context: context,
          sortedSegments: sortedSegments,
          activeSegmentKey: _activeSegmentKey,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      case '4x2':
        return CareerTrajectoryLayouts.build4x2Layout(
          context: context,
          sortedSegments: sortedSegments,
          activeSegmentKey: _activeSegmentKey,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      case '4x4':
        return CareerTrajectoryLayouts.build4x4Layout(
          context: context,
          sortedSegments: sortedSegments,
          activeSegmentKey: _activeSegmentKey,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      default:
        return CareerTrajectoryLayouts.build4x4Layout(
          context: context,
          sortedSegments: sortedSegments,
          activeSegmentKey: _activeSegmentKey,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
    }
  }
}

