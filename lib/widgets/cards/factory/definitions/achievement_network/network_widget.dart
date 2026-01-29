import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../../../stores/user_store.dart';
import 'network_constants.dart';
import 'network_hover_card.dart';
import 'network_modal.dart';
import 'network_layouts.dart';

class NetworkWidget extends StatefulWidget {
  const NetworkWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  State<NetworkWidget> createState() => _NetworkWidgetState();
}

class _NetworkWidgetState extends State<NetworkWidget> {
  String? _activeHoverKey;
  Offset _hoverCardOffset = Offset.zero;
  Map<String, dynamic>? _activeModal;

  void _handleHover(String connectionKey, Offset localPosition) {
    if (!kIsWeb) return;

    setState(() {
      _activeHoverKey = connectionKey;
      
      // Calculate hover card position
      const hoverCardWidth = 380.0;
      const hoverCardHeight = 450.0;
      const defaultXOffset = 40.0;
      const defaultYOffset = -130.0;
      
      final screenSize = MediaQuery.of(context).size;
      final globalPosition = localPosition;
      
      // Calculate horizontal position
      double finalXOffset = defaultXOffset;
      final hoverCardLeft = globalPosition.dx + defaultXOffset;
      final hoverCardRight = hoverCardLeft + hoverCardWidth;
      
      if (hoverCardRight > screenSize.width) {
        finalXOffset = -hoverCardWidth - 40;
      }
      if (hoverCardLeft < 0) {
        finalXOffset = 40;
      }
      
      // Calculate vertical position
      double finalYOffset = defaultYOffset;
      final hoverCardTop = globalPosition.dy + defaultYOffset;
      final hoverCardBottom = hoverCardTop + hoverCardHeight;
      
      if (hoverCardBottom > screenSize.height) {
        final alternativeTop = globalPosition.dy + 30;
        final alternativeBottom = alternativeTop + hoverCardHeight;
        if (alternativeBottom <= screenSize.height) {
          finalYOffset = 30;
        } else {
          finalYOffset = screenSize.height - globalPosition.dy - hoverCardHeight - 10;
        }
      }
      if (hoverCardTop < 0) {
        finalYOffset = 30;
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
      _activeHoverKey = null;
    });
  }

  void _handleOpenModal(Map<String, dynamic> connection, int index) {
    setState(() {
      _activeModal = connection;
    });
    _showModal();
  }

  void _showModal() {
    if (_activeModal == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => NetworkModal(
        connection: _activeModal!,
        onClose: () {
          Navigator.of(context).pop();
          setState(() {
            _activeModal = null;
          });
        },
      ),
    );
  }

  Map<String, dynamic>? _getActiveConnection() {
    if (_activeHoverKey == null) return null;
    
    final connections = (widget.card.data.metadata['connections'] as List<dynamic>?) ?? [];
    for (int i = 0; i < connections.length; i++) {
      final connection = connections[i] as Map<String, dynamic>;
      final connectionKey = '${connection['name']}-$i';
      if (connectionKey == _activeHoverKey || 
          _activeHoverKey!.startsWith('top-${connection['name']}') ||
          _activeHoverKey!.startsWith('bottom-${connection['name']}')) {
        return connection;
      }
    }
    return null;
  }

  bool _isTopRow(String? connectionKey) {
    if (connectionKey == null) return true;
    return connectionKey.startsWith('top-') || 
           (!connectionKey.startsWith('bottom-') && _activeHoverKey != null);
  }

  @override
  Widget build(BuildContext context) {
    final connections = (widget.card.data.metadata['connections'] as List<dynamic>?) ?? [];
    
    if (connections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No network data',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ),
      );
    }

    final connectionList = connections.cast<Map<String, dynamic>>();
    final activeConnection = _getActiveConnection();
    final isTopRow = _isTopRow(_activeHoverKey);

    // Get owner info from user store
    final userStore = context.watch<UserStore>();
    final ownerName = userStore.cardOwner?.name ?? 'User';
    final ownerAvatar = userStore.cardOwner?.avatarUrl ?? '/images/default-avatar.svg';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content based on size
            _buildContent(
              connectionList,
              ownerName,
              ownerAvatar,
            ),
            
            // Hover popup (desktop only)
            if (kIsWeb && activeConnection != null && (_hoverCardOffset.dx != 0 || _hoverCardOffset.dy != 0))
              Positioned(
                left: _hoverCardOffset.dx,
                top: _hoverCardOffset.dy,
                child: NetworkHoverCard(
                  connection: activeConnection,
                  colorScheme: NetworkConstants.getColorScheme(isTopRow),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    List<Map<String, dynamic>> connections,
    String ownerName,
    String ownerAvatar,
  ) {
    switch (widget.size) {
      case '2x2':
        return NetworkLayouts.build2x2Layout(
          context: context,
          connections: connections,
          activeHoverKey: _activeHoverKey,
          hoverCardOffset: _hoverCardOffset,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      case '2x4':
        return NetworkLayouts.build2x4Layout(
          context: context,
          connections: connections,
          activeHoverKey: _activeHoverKey,
          hoverCardOffset: _hoverCardOffset,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      case '4x2':
        return NetworkLayouts.build4x2Layout(
          context: context,
          connections: connections,
          activeHoverKey: _activeHoverKey,
          hoverCardOffset: _hoverCardOffset,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
        );
      case '4x4':
        return NetworkLayouts.build4x4Layout(
          context: context,
          connections: connections,
          activeHoverKey: _activeHoverKey,
          hoverCardOffset: _hoverCardOffset,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
          ownerName: ownerName,
          ownerAvatar: ownerAvatar,
        );
      default:
        return NetworkLayouts.build4x4Layout(
          context: context,
          connections: connections,
          activeHoverKey: _activeHoverKey,
          hoverCardOffset: _hoverCardOffset,
          onHover: _handleHover,
          onHoverEnd: _handleHoverEnd,
          onOpenModal: _handleOpenModal,
          ownerName: ownerName,
          ownerAvatar: ownerAvatar,
        );
    }
  }
}

