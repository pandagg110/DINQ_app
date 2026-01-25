import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../card_definition.dart';

class CareerTrajectoryCardDefinition extends CardDefinition {
  @override
  String get type => 'CAREER_TRAJECTORY';

  @override
  String get icon => 'i-lucide-trending-up';

  @override
  String get name => 'Career Trajectory';

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
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    // rawMetadata is an array of segments
    final segments = (rawMetadata is List ? rawMetadata : []) as List<dynamic>;
    
    final adaptedSegments = segments.asMap().entries.map((entry) {
      final index = entry.key;
      final segment = entry.value as Map<String, dynamic>;
      final roleModel = segment['role_model'] as Map<String, dynamic>?;
      
      Map<String, dynamic> representative;
      if (roleModel != null) {
        final data = roleModel['data'] as Map<String, dynamic>?;
        representative = {
          'name': roleModel['name'] ?? data?['name'] ?? 'Unknown',
          'position': data?['highlight'] ?? 
                      data?['company'] ?? 
                      data?['institution'] ?? 
                      'Unknown Position',
          'dinq': data?['dinq'],
          'avatarUrl': roleModel['photo'] ?? data?['photo'] ?? '/images/default-avatar.svg',
          'brief': roleModel['brief'] ?? data?['brief'] ?? '',
          'highlight': data?['highlight'] ?? '',
          'school': roleModel['school'] ?? data?['school'] ?? '',
          'companyLogo': null,
          'location': null,
          'socialMedia': roleModel['social_media'] != null
              ? {
                  'linkedin': roleModel['social_media']?['linkedin'],
                  'github': roleModel['social_media']?['github'],
                  'scholar': roleModel['social_media']?['scholar'],
                  'twitter': roleModel['social_media']?['twitter'],
                }
              : null,
        };
      } else {
        representative = {
          'name': 'Unknown',
          'position': 'Unknown Position',
          'dinq': null,
          'avatarUrl': '/images/default-avatar.svg',
          'brief': '',
          'highlight': '',
          'school': '',
          'companyLogo': null,
          'location': null,
          'socialMedia': null,
        };
      }

      // Get color based on category type
      final categoryType = segment['type']?.toString() ?? '';
      final color = _getCareerColor(categoryType, index);

      return {
        'category': categoryType,
        'percentage': segment['probability'] ?? 0,
        'color': color,
        'representative': representative,
      };
    }).toList();

    return {
      'segments': adaptedSegments,
    };
  }

  String _getCareerColor(String type, int index) {
    // Simplified color mapping - you may want to match the TypeScript version exactly
    final colors = [
      '#1487FA', // developer - blue
      '#DDFEBC', // researcher - green
      '#FFE4CC', // entrepreneur - orange
      '#E2C6FF', // educator - purple
    ];
    
    switch (type.toLowerCase()) {
      case 'developer':
        return '#1487FA';
      case 'researcher':
        return '#DDFEBC';
      case 'entrepreneur':
        return '#FFE4CC';
      case 'educator':
        return '#E2C6FF';
      default:
        return colors[index % colors.length];
    }
  }

  @override
  Widget render(CardRenderParams params) {
    return _CareerTrajectoryCardWidget(
      card: params.card,
      size: params.size,
    );
  }
}

class _CareerTrajectoryCardWidget extends StatefulWidget {
  const _CareerTrajectoryCardWidget({
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  State<_CareerTrajectoryCardWidget> createState() => _CareerTrajectoryCardWidgetState();
}

class _CareerTrajectoryCardWidgetState extends State<_CareerTrajectoryCardWidget> {
  String? _activeSegmentKey;
  Offset _hoverCardOffset = Offset.zero;
  Map<String, dynamic>? _activeModal;

  // Color scheme based on TSX version
  static const List<String> colors = ['#E2C6FF', '#1487FA', '#DDFEBC']; // purple, blue, green

  static const Map<String, Map<String, Color>> colorSchemes = {
    'purple': {
      'main': Color(0xFFEFDFFF),
      'light': Color(0xFFF8F1FF),
      'divider': Color(0xFFCAB4EF),
      'textGray': Color(0xFF897C96),
      'iconColor': Color(0x661D0944),
    },
    'blue': {
      'main': Color(0xFFCCE5FF),
      'light': Color(0xFFE5F2FF),
      'divider': Color(0xFFB4D7EF),
      'textGray': Color(0xFF82909E),
      'iconColor': Color(0x66093344),
    },
    'green': {
      'main': Color(0xFFE3F5D1),
      'light': Color(0xFFF7FFEE),
      'divider': Color(0xFFDBEAC1),
      'textGray': Color(0xFF8B9085),
      'iconColor': Color(0xFF869874),
    },
  };

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF1487FA);
    } catch (e) {
      return const Color(0xFF1487FA);
    }
  }

  String _getColorSchemeName(String segmentColor) {
    if (segmentColor == colors[0]) return 'purple';
    if (segmentColor == colors[1]) return 'blue';
    return 'green';
  }

  Map<String, Color> _getColorScheme(String segmentColor) {
    return colorSchemes[_getColorSchemeName(segmentColor)] ?? colorSchemes['blue']!;
  }

  void _handleOpenModal(Map<String, dynamic> segment, Map<String, dynamic> representative, String segmentColor) {
    setState(() {
      _activeModal = {
        'segment': segment,
        'representative': representative,
        'colorScheme': _getColorScheme(segmentColor),
        'colorSchemeName': _getColorSchemeName(segmentColor),
      };
    });
    _showModal();
  }

  void _showModal() {
    if (_activeModal == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _CareerTrajectoryModal(
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
    debugPrint('career_trajectory_card: ${widget.card.data.metadata}');
    final segments = (widget.card.data.metadata['segments'] as List<dynamic>?) ?? [];
    
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
            _buildContent(sortedSegments, constraints),
            
            // Hover popup (desktop only)
            if (kIsWeb && activeSegment != null && activeSegmentIndex >= 0)
              Positioned(
                left: _hoverCardOffset.dx,
                top: _hoverCardOffset.dy,
                child: _CareerHoverCard(
                  representative: activeSegment['representative'] as Map<String, dynamic>,
                  segment: activeSegment,
                  colorScheme: _getColorScheme(colors[activeSegmentIndex]),
                  colorSchemeName: _getColorSchemeName(colors[activeSegmentIndex]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> sortedSegments, BoxConstraints constraints) {
    switch (widget.size) {
      case '2x2':
        return _build2x2Layout(sortedSegments);
      case '2x4':
        return _build2x4Layout(sortedSegments);
      case '4x2':
        return _build4x2Layout(sortedSegments);
      case '4x4':
        return _build4x4Layout(sortedSegments);
      default:
        return _build4x4Layout(sortedSegments);
    }
  }

  Widget _build2x2Layout(List<Map<String, dynamic>> sortedSegments) {
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
                        _buildSegmentBar(
                          sortedSegments[index],
                          index,
                          sortedSegments.length,
                          colors[index],
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

  Widget _build2x4Layout(List<Map<String, dynamic>> sortedSegments) {
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
                          child: _buildSegmentBar(
                            sortedSegments[index],
                            index,
                            sortedSegments.length,
                            colors[index],
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
                          child: _buildSegmentLabel(sortedSegments[index], index, colors[index]),
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

  Widget _build4x2Layout(List<Map<String, dynamic>> sortedSegments) {
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
                        _buildAvatarPositioned(sortedSegments[index], index, sortedSegments),
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
                        _buildSegmentBar(
                          sortedSegments[index],
                          index,
                          sortedSegments.length,
                          colors[index],
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

  Widget _build4x4Layout(List<Map<String, dynamic>> sortedSegments) {
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
                          child: _buildSegmentBar(
                            sortedSegments[index],
                            index,
                            sortedSegments.length,
                            colors[index],
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
                        child: _CareerFlowDiagram(
                          careerA: (sortedSegments[0]['percentage'] as num?)?.toDouble() ?? 0,
                          careerB: (sortedSegments[1]['percentage'] as num?)?.toDouble() ?? 0,
                          careerC: (sortedSegments[2]['percentage'] as num?)?.toDouble() ?? 0,
                          colors: colors,
                        ),
                      ),
                      
                      // Annotations Overlay
                      Column(
                        children: [
                          for (int index = 0; index < sortedSegments.length; index++)
                            Expanded(
                              flex: (sortedSegments[index]['percentage'] as num).toInt(),
                              child: _buildSegmentAnnotation(sortedSegments[index], index, colors[index]),
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

  Widget _buildSegmentBar(
    Map<String, dynamic> segment,
    int index,
    int totalSegments,
    String color,
    {required bool isHorizontal, bool showPercentage = false}
  ) {
    final segmentKey = '${segment['category']}-$index';
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';
    final isActive = hasRepresentative && _activeSegmentKey == segmentKey;
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
        color: _parseColor(color),
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
            child: _buildInteractiveSegment(
              barWidget,
              segmentKey,
              segment,
              representative,
              color,
              isActive,
            ),
          )
        : _buildInteractiveSegment(
            barWidget,
            segmentKey,
            segment,
            representative,
            color,
            isActive,
          );
  }

  Widget _buildInteractiveSegment(
    Widget child,
    String segmentKey,
    Map<String, dynamic> segment,
    Map<String, dynamic> representative,
    String color,
    bool isActive,
  ) {
    return MouseRegion(
      onEnter: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _handleHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onHover: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _handleHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onExit: (_) => _handleHoverEnd(),
      child: GestureDetector(
        onTap: () => _handleOpenModal(segment, representative, color),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.7,
          child: child,
        ),
      ),
    );
  }

  Widget _buildSegmentLabel(Map<String, dynamic> segment, int index, String color) {
    final segmentKey = '${segment['category']}-$index';
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';
    final isActive = hasRepresentative && _activeSegmentKey == segmentKey;

    if (!hasRepresentative) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _handleHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onHover: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _handleHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onExit: (_) => _handleHoverEnd(),
      child: GestureDetector(
        onTap: () => _handleOpenModal(segment, representative, color),
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

  Widget _buildAvatarPositioned(
    Map<String, dynamic> segment,
    int index,
    List<Map<String, dynamic>> sortedSegments,
  ) {
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

  Widget _buildSegmentAnnotation(
    Map<String, dynamic> segment,
    int index,
    String color,
  ) {
    final segmentKey = '${segment['category']}-$index';
    final representative = segment['representative'] as Map<String, dynamic>?;
    final hasRepresentative = representative != null && representative['name'] != 'Unknown';
    final isActive = hasRepresentative && _activeSegmentKey == segmentKey;
    final category = segment['category'] as String? ?? '';

    return MouseRegion(
      onEnter: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _handleHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onHover: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _handleHover(segmentKey, localPosition, renderBox.size);
        }
      },
      onExit: (_) => _handleHoverEnd(),
      child: GestureDetector(
        onTap: () {
          if (hasRepresentative) {
            _handleOpenModal(segment, representative, color);
          }
        },
        child: Opacity(
          opacity: isActive ? 1.0 : 0.85,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
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
      ),
    );
  }
}

// Hover Card Component
class _CareerHoverCard extends StatelessWidget {
  const _CareerHoverCard({
    required this.representative,
    required this.segment,
    required this.colorScheme,
    required this.colorSchemeName,
  });

  final Map<String, dynamic> representative;
  final Map<String, dynamic> segment;
  final Map<String, Color> colorScheme;
  final String colorSchemeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme['main'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme['divider']!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: (representative['avatarUrl'] as String?) != null
                    ? NetworkImage(representative['avatarUrl'] as String)
                    : null,
                child: (representative['avatarUrl'] as String?) == null
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      representative['name'] as String? ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (representative['dinq'] ?? representative['position'] ?? '') as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme['textGray'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme['divider'], height: 1),
          const SizedBox(height: 12),
          
          // Category
          Text(
            (segment['category'] as String? ?? '')
                .isEmpty
                ? ''
                : (segment['category'] as String)
                    .substring(0, 1)
                    .toUpperCase() +
                    (segment['category'] as String).substring(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme['textGray'],
            ),
          ),
          const SizedBox(height: 8),
          
          // Brief
          if (representative['brief'] != null && (representative['brief'] as String).isNotEmpty)
            Text(
              representative['brief'] as String,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme['textGray'],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// Flow Diagram Component (simplified version)
class _CareerFlowDiagram extends StatelessWidget {
  const _CareerFlowDiagram({
    required this.careerA,
    required this.careerB,
    required this.careerC,
    required this.colors,
  });

  final double careerA;
  final double careerB;
  final double careerC;
  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FlowDiagramPainter(
        careerA: careerA,
        careerB: careerB,
        careerC: careerC,
        colors: colors,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FlowDiagramPainter extends CustomPainter {
  const _FlowDiagramPainter({
    required this.careerA,
    required this.careerB,
    required this.careerC,
    required this.colors,
  });

  final double careerA;
  final double careerB;
  final double careerC;
  final List<String> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified flow diagram - draw connecting lines between segments
    // This is a placeholder implementation
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.grey.withOpacity(0.3);

    // Draw simple connecting lines (simplified version of the TSX flow diagram)
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Modal Component
class _CareerTrajectoryModal extends StatelessWidget {
  const _CareerTrajectoryModal({
    required this.segment,
    required this.representative,
    required this.colorScheme,
    required this.colorSchemeName,
    required this.onClose,
  });

  final Map<String, dynamic> segment;
  final Map<String, dynamic> representative;
  final Map<String, Color> colorScheme;
  final String colorSchemeName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: colorScheme['main'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme['divider']!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: (representative['avatarUrl'] as String?) != null
                        ? NetworkImage(representative['avatarUrl'] as String)
                        : null,
                    child: (representative['avatarUrl'] as String?) == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          representative['name'] as String? ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (representative['dinq'] ?? representative['position'] ?? '') as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme['textGray'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(color: colorScheme['divider'], height: 1),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      (segment['category'] as String? ?? '')
                          .isEmpty
                          ? ''
                          : (segment['category'] as String)
                              .substring(0, 1)
                              .toUpperCase() +
                              (segment['category'] as String).substring(1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme['textGray'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Brief
                    if (representative['brief'] != null && (representative['brief'] as String).isNotEmpty)
                      Text(
                        representative['brief'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme['textGray'],
                        ),
                      ),
                    
                    // Additional info can be added here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
