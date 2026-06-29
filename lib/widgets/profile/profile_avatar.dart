import 'package:flutter/material.dart';

import '../../utils/asset_path.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.userName,
    this.editable = false,
    this.size = 180,
    this.jobStatus,
    this.onAvatarUpdated,
    this.onStatusEdit,
  });

  final String avatarUrl;
  final String userName;
  final bool editable;
  final double size;
  final String? jobStatus;
  final VoidCallback? onAvatarUpdated;
  final VoidCallback? onStatusEdit;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _hasError = false;

  String get _displayAvatarUrl {
    if (_hasError) return '';
    return widget.avatarUrl;
  }

  Widget _buildDefaultAvatar() {
    return Image.asset(
      assetPath('profile/default-avator.png'),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.person,
            size: widget.size * 0.5,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  String? _getJobStatusCircleAsset() {
    if (widget.jobStatus == null || widget.jobStatus == 'Hidden') {
      return null;
    }

    switch (widget.jobStatus) {
      case 'Hiring':
        return 'icons/avatar/purple_circle.png';
      case 'Open_to_work':
        return 'icons/avatar/blue_circle.png';
      case 'Internship':
        return 'icons/avatar/yellow_circle.png';
      case 'Freelance':
        return 'icons/avatar/green_circle.png';
      default:
        return 'icons/avatar/blue_circle.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobStatusCircleAsset = _getJobStatusCircleAsset();

    return Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE5E5E5),
          ),
          child: ClipOval(
            child: Stack(
              children: [
                _displayAvatarUrl.isNotEmpty
                    ? Image.network(
                        _displayAvatarUrl,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_hasError) {
                              setState(() => _hasError = true);
                            }
                          });
                          return _buildDefaultAvatar();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : _buildDefaultAvatar(),
                if (jobStatusCircleAsset != null)
                  Positioned.fill(
                    child: Image.asset(
                      assetPath(jobStatusCircleAsset),
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
