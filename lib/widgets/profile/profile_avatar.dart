import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/upload_service.dart';
import '../../stores/user_store.dart';
import '../../utils/toast_util.dart';
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
  final String? jobStatus; // "Hiring" | "Open_to_work" | "Internship" | "Freelance" | "Hidden"
  final VoidCallback? onAvatarUpdated;
  final VoidCallback? onStatusEdit;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final UploadService _uploadService = UploadService();
  bool _isUploading = false;
  bool _isHovering = false;
  String? _tempAvatarUrl;
  bool _hasError = false;

  String get _displayAvatarUrl {
    if (_hasError) {
      return ''; // 使用默认头像
    }
    return _tempAvatarUrl ?? widget.avatarUrl;
  }

  Future<void> _handleFileSelect() async {
    if (_isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _isUploading = true;
          _hasError = false;
        });

        try {
          // 上传文件
          final uploadedUrl = await _uploadService.uploadFile(
            bytes: file.bytes!,
            filename: file.name,
            contentType: file.extension == 'png'
                ? 'image/png'
                : file.extension == 'jpg' || file.extension == 'jpeg'
                    ? 'image/jpeg'
                    : file.extension == 'gif'
                        ? 'image/gif'
                        : file.extension == 'webp'
                            ? 'image/webp'
                            : 'image/jpeg',
          );

          // 更新用户数据
          final userStore = context.read<UserStore>();
          await userStore.updateUserData({'avatar_url': uploadedUrl});

          setState(() {
            _tempAvatarUrl = uploadedUrl;
            _isUploading = false;
          });

          ToastUtil.showSuccess(
            context: context,
            title: '上传成功',
            description: '头像已更新',
          );

          widget.onAvatarUpdated?.call();
        } catch (error) {
          setState(() {
            _isUploading = false;
          });
          ToastUtil.showError(
            context: context,
            title: '上传失败',
            description: error.toString(),
          );
        }
      }
    } catch (error) {
      ToastUtil.showError(
        context: context,
        title: '选择文件失败',
        description: error.toString(),
      );
    }
  }

  String? _getJobStatusCircleAsset() {
    if (widget.jobStatus == null || widget.jobStatus == 'Hidden') {
      return null;
    }
    // 映射工作状态到 SVG 资源路径
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
        return 'icons/avatar/blue_circle.png'; // 默认使用 Open_to_work
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobStatusCircleAsset = _getJobStatusCircleAsset();

    return MouseRegion(
      onEnter: widget.editable && !_isUploading
          ? (_) => setState(() => _isHovering = true)
          : null,
      onExit: widget.editable ? (_) => setState(() => _isHovering = false) : null,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E5E5),
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  // 头像图片
                  _displayAvatarUrl.isNotEmpty
                      ? Image.network(
                          _displayAvatarUrl,
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // 如果图片加载失败，显示默认图标
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_hasError) {
                                setState(() => _hasError = true);
                              }
                            });
                            return Icon(
                              Icons.person,
                              size: widget.size * 0.5,
                              color: Colors.grey,
                            );
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
                      : Icon(
                          Icons.person,
                          size: widget.size * 0.5,
                          color: Colors.grey,
                        ),
                  // 工作状态徽章 - 弧形背景（使用 PNG 图片）
                  if (jobStatusCircleAsset != null)
                    Positioned.fill(
                      child: Image.asset(
                        assetPath(jobStatusCircleAsset),
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 如果图片加载失败，不显示徽章
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 上传加载遮罩
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withOpacity(0.3),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // 悬停时的操作按钮
          if (widget.editable && !_isUploading && _isHovering)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handleFileSelect,
                      icon: const Icon(Icons.upload, size: 16),
                      label: const Text('Upload', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    if (widget.onStatusEdit != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: widget.onStatusEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Status', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

