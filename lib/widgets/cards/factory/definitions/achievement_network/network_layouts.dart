import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'network_constants.dart';
import 'network_components.dart';

class NetworkLayouts {
  // 2x2 Size - Horizontal row at bottom
  static Widget build2x2Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> connections,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildAvatarGroup(
                connections: connections.take(6).toList(),
                activeHoverKey: activeHoverKey,
                hoverCardOffset: hoverCardOffset,
                onHover: onHover,
                onHoverEnd: onHoverEnd,
                onOpenModal: onOpenModal,
                isTopRow: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical layout with whitespace
  static Widget build2x4Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> connections,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          const Spacer(),
          _buildAvatarGroup(
            connections: connections.take(6).toList(),
            activeHoverKey: activeHoverKey,
            hoverCardOffset: hoverCardOffset,
            onHover: onHover,
            onHoverEnd: onHoverEnd,
            onOpenModal: onOpenModal,
            isTopRow: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal row of avatars with company badges
  static Widget build4x2Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> connections,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: connections.asMap().entries.map((entry) {
                final index = entry.key;
                final connection = entry.value;
                final connectionKey = '${connection['name']}-$index';
                return _buildAvatarWithBadge(
                  connection: connection,
                  connectionKey: connectionKey,
                  index: index,
                  activeHoverKey: activeHoverKey,
                  hoverCardOffset: hoverCardOffset,
                  onHover: onHover,
                  onHoverEnd: onHoverEnd,
                  onOpenModal: onOpenModal,
                  isTopRow: true,
                  size: 48,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 4x4 Size - Network graph with center person and connections
  static Widget build4x4Layout({
    required BuildContext context,
    required List<Map<String, dynamic>> connections,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
    required String ownerName,
    required String ownerAvatar,
  }) {
    final topRow = connections.take(3).toList();
    final bottomRow = connections.skip(3).take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  // Grid background
                  CustomPaint(
                    painter: _GridPainter(),
                    size: Size.infinite,
                  ),

                  // Connection lines
                  CustomPaint(
                    painter: _ConnectionLinesPainter(
                      topRow: topRow,
                      bottomRow: bottomRow,
                    ),
                    size: Size.infinite,
                  ),

                  // Content
                  _buildNetworkGraphContent(
                    context: context,
                    topRow: topRow,
                    bottomRow: bottomRow,
                    ownerName: ownerName,
                    ownerAvatar: ownerAvatar,
                    activeHoverKey: activeHoverKey,
                    hoverCardOffset: hoverCardOffset,
                    onHover: onHover,
                    onHoverEnd: onHoverEnd,
                    onOpenModal: onOpenModal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Avatar group
  static Widget _buildAvatarGroup({
    required List<Map<String, dynamic>> connections,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
    required bool isTopRow,
  }) {
    return Wrap(
      spacing: -8,
      children: connections.asMap().entries.map((entry) {
        final index = entry.key;
        final connection = entry.value;
        final connectionKey = '${connection['name']}-$index';
        return _buildAvatar(
          connection: connection,
          connectionKey: connectionKey,
          index: index,
          activeHoverKey: activeHoverKey,
          hoverCardOffset: hoverCardOffset,
          onHover: onHover,
          onHoverEnd: onHoverEnd,
          onOpenModal: onOpenModal,
          isTopRow: isTopRow,
          size: 32,
        );
      }).toList(),
    );
  }

  // Helper: Single avatar
  static Widget _buildAvatar({
    required Map<String, dynamic> connection,
    required String connectionKey,
    required int index,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
    required bool isTopRow,
    required double size,
  }) {
    final avatarUrl = connection['avatarUrl']?.toString();
    
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/default-avatar.svg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 16);
                    },
                  );
                },
              )
            : Image.asset(
                'assets/images/default-avatar.svg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 16);
                },
              ),
      ),
    );

    if (kIsWeb) {
      return Builder(
        builder: (context) {
          return MouseRegion(
            onEnter: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(event.position);
                onHover(connectionKey, localPosition);
              }
            },
            onHover: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(event.position);
                onHover(connectionKey, localPosition);
              }
            },
            onExit: (_) => onHoverEnd(),
            child: GestureDetector(
              onTap: () => onOpenModal(connection, index),
              child: avatar,
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => onOpenModal(connection, index),
      child: avatar,
    );
  }

  // Helper: Avatar with company badge
  static Widget _buildAvatarWithBadge({
    required Map<String, dynamic> connection,
    required String connectionKey,
    required int index,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
    required bool isTopRow,
    required double size,
  }) {
    final avatarUrl = connection['avatarUrl']?.toString();
    final logoUrl = connection['institution_logo_url']?.toString();

    Widget avatarWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/default-avatar.svg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 24);
                        },
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/default-avatar.svg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 24);
                    },
                  ),
          ),
        ),
        CompanyLogoBadge(logoUrl: logoUrl, size: size == 48 ? 'md' : 'sm'),
      ],
    );

    if (kIsWeb) {
      return Builder(
        builder: (context) {
          return MouseRegion(
            onEnter: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(event.position);
                onHover(connectionKey, localPosition);
              }
            },
            onHover: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(event.position);
                onHover(connectionKey, localPosition);
              }
            },
            onExit: (_) => onHoverEnd(),
            child: GestureDetector(
              onTap: () => onOpenModal(connection, index),
              child: avatarWidget,
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => onOpenModal(connection, index),
      child: avatarWidget,
    );
  }

  // Helper: Network graph content (4x4)
  static Widget _buildNetworkGraphContent({
    required BuildContext context,
    required List<Map<String, dynamic>> topRow,
    required List<Map<String, dynamic>> bottomRow,
    required String ownerName,
    required String ownerAvatar,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        return Stack(
          children: [
            // Top Row
            ...topRow.asMap().entries.map((entry) {
              final index = entry.key;
              final connection = entry.value;
              final connectionKey = 'top-${connection['name']}-$index';
              final xPosition = width * (NetworkConstants.connectionXPositions[index] / 100);
              final yPosition = height * 0.27;
              
              return Positioned(
                left: xPosition,
                top: yPosition,
                child: Transform.translate(
                  offset: const Offset(-50, -100),
                  child: _buildTopRowItem(
                    connection: connection,
                    connectionKey: connectionKey,
                    index: index,
                    activeHoverKey: activeHoverKey,
                    hoverCardOffset: hoverCardOffset,
                    onHover: onHover,
                    onHoverEnd: onHoverEnd,
                    onOpenModal: onOpenModal,
                  ),
                ),
              );
            }),

            // Center Avatar
            Positioned(
              left: width * 0.5,
              top: height * 0.5,
              child: Transform.translate(
                offset: const Offset(-28, -28),
                child: _buildCenterAvatar(ownerName: ownerName, ownerAvatar: ownerAvatar),
              ),
            ),

            // Bottom Row
            ...bottomRow.asMap().entries.map((entry) {
              final index = entry.key;
              final connection = entry.value;
              final connectionKey = 'bottom-${connection['name']}-${index + 3}';
              final xPosition = width * (NetworkConstants.connectionXPositions[index] / 100);
              final yPosition = height * 0.73;
              final actualIndex = index + 3;
              
              return Positioned(
                left: xPosition,
                top: yPosition,
                child: Transform.translate(
                  offset: const Offset(-50, 0),
                  child: _buildBottomRowItem(
                    connection: connection,
                    connectionKey: connectionKey,
                    index: actualIndex,
                    activeHoverKey: activeHoverKey,
                    hoverCardOffset: hoverCardOffset,
                    onHover: onHover,
                    onHoverEnd: onHoverEnd,
                    onOpenModal: onOpenModal,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // Helper: Top row item
  static Widget _buildTopRowItem({
    required Map<String, dynamic> connection,
    required String connectionKey,
    required int index,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
  }) {
    final name = connection['name']?.toString() ?? '';
    final avatarUrl = connection['avatarUrl']?.toString();
    final logoUrl = connection['institution_logo_url']?.toString();

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default-avatar.svg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 20);
                            },
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/default-avatar.svg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 20);
                        },
                      ),
              ),
            ),
            CompanyLogoBadge(logoUrl: logoUrl, size: 'sm'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: NetworkConstants.blueTagColor,
            borderRadius: BorderRadius.circular(999),
          ),
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (kIsWeb) {
      return Builder(
        builder: (context) {
          return MouseRegion(
            onEnter: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(event.position);
                onHover(connectionKey, localPosition);
              }
            },
            onHover: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPosition = renderBox.globalToLocal(event.position);
                onHover(connectionKey, localPosition);
              }
            },
            onExit: (_) => onHoverEnd(),
            child: GestureDetector(
              onTap: () => onOpenModal(connection, index),
              child: content,
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => onOpenModal(connection, index),
      child: content,
    );
  }

  // Helper: Bottom row item
  static Widget _buildBottomRowItem({
    required Map<String, dynamic> connection,
    required String connectionKey,
    required int index,
    required String? activeHoverKey,
    required Offset hoverCardOffset,
    required Function(String, Offset) onHover,
    required VoidCallback onHoverEnd,
    required Function(Map<String, dynamic>, int) onOpenModal,
  }) {
    final name = connection['name']?.toString() ?? '';
    final avatarUrl = connection['avatarUrl']?.toString();
    final logoUrl = connection['institution_logo_url']?.toString();

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: NetworkConstants.purpleTagColor,
            borderRadius: BorderRadius.circular(999),
          ),
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default-avatar.svg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 20);
                            },
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/default-avatar.svg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 20);
                        },
                      ),
              ),
            ),
            CompanyLogoBadge(logoUrl: logoUrl, size: 'sm'),
          ],
        ),
      ],
    );

    if (kIsWeb) {
      return Builder(
        builder: (context) {
          return MouseRegion(
            onEnter: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(event.position);
            onHover(connectionKey, localPosition);
          }
        },
            onHover: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(event.position);
            onHover(connectionKey, localPosition);
          }
        },
            onExit: (_) => onHoverEnd(),
            child: GestureDetector(
              onTap: () => onOpenModal(connection, index),
              child: content,
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => onOpenModal(connection, index),
      child: content,
    );
  }

  // Helper: Center avatar
  static Widget _buildCenterAvatar({
    required String ownerName,
    required String ownerAvatar,
  }) {
    return Stack(
      children: [
        // Golden background circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NetworkConstants.goldenBackground,
            border: Border.all(color: const Color(0xFF171717), width: 0.56),
          ),
        ),
        // Avatar
        Positioned(
          left: 4,
          top: 4,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF171717), width: 0.56),
            ),
            child: ClipOval(
              child: ownerAvatar.isNotEmpty
                  ? Image.network(
                      ownerAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            ownerName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(''),
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        ownerName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(''),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
            ),
          ),
        ),
        // Name on left
        Positioned(
          right: 72,
          top: 18,
          child: SizedBox(
            width: 100,
            child: Text(
              ownerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// Grid painter for 4x4 layout
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NetworkConstants.gridColor
      ..strokeWidth = 1;

    // Draw vertical lines
    for (int i = 0; i <= 16; i++) {
      final x = (size.width / 16) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= 16; i++) {
      final y = (size.height / 16) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Connection lines painter for 4x4 layout
class _ConnectionLinesPainter extends CustomPainter {
  final List<Map<String, dynamic>> topRow;
  final List<Map<String, dynamic>> bottomRow;

  _ConnectionLinesPainter({
    required this.topRow,
    required this.bottomRow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.25;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final topJunctionY = centerY - (size.height * 0.15);
    final bottomJunctionY = centerY + (size.height * 0.15);
    final topConnectionY = size.height * 0.27;
    final bottomConnectionY = size.height * 0.73;
    final xPositions = [
      size.width * 0.2,
      size.width * 0.5,
      size.width * 0.8,
    ];

    // Vertical line from center to top junction
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX, topJunctionY),
      paint,
    );

    // Vertical line from center to bottom junction
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX, bottomJunctionY),
      paint,
    );

    // Diagonal lines from top junction to connection points
    for (int i = 0; i < topRow.length; i++) {
      canvas.drawLine(
        Offset(centerX, topJunctionY),
        Offset(xPositions[i], topConnectionY),
        paint,
      );
    }

    // Diagonal lines from bottom junction to connection points
    for (int i = 0; i < bottomRow.length; i++) {
      canvas.drawLine(
        Offset(centerX, bottomJunctionY),
        Offset(xPositions[i], bottomConnectionY),
        paint,
      );
    }

    // Draw junction dots
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Top junction background
    final topJunctionBgPaint = Paint()
      ..color = NetworkConstants.blueTagColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, topJunctionY), 1.5, topJunctionBgPaint);
    canvas.drawCircle(Offset(centerX, topJunctionY), 0.75, dotPaint);

    // Bottom junction background
    final bottomJunctionBgPaint = Paint()
      ..color = NetworkConstants.purpleTagColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, bottomJunctionY), 1.5, bottomJunctionBgPaint);
    canvas.drawCircle(Offset(centerX, bottomJunctionY), 0.75, dotPaint);

    // Connection dots
    for (int i = 0; i < topRow.length; i++) {
      canvas.drawCircle(Offset(xPositions[i], topConnectionY), 0.75, dotPaint);
    }
    for (int i = 0; i < bottomRow.length; i++) {
      canvas.drawCircle(Offset(xPositions[i], bottomConnectionY), 0.75, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

