import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../stores/user_store.dart';
import 'profile_avatar.dart';
import 'profile_edit_dialog.dart';

/// Profile 页头部：仅展示内容；编辑态通过弹框修改（与 AddCardDialog 风格一致）。
/// 编辑/浏览切换使用 !_isPreviewMode && isEditable（isEditMode）。
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.data,
    required this.username,
    this.isPreviewMode = true,
    this.onPreviewModeChanged,
    this.onAvatarUpdated,
    this.onStatusEdit,
    this.onDataUpdated,
  });

  final UserData data;
  final String username;
  final bool isPreviewMode;
  final ValueChanged<bool>? onPreviewModeChanged;
  final VoidCallback? onAvatarUpdated;
  final VoidCallback? onStatusEdit;
  final VoidCallback? onDataUpdated;

  static const _tagColors = [
    Color(0xFFFDE277),
    Color(0xFFFED7D7),
    Color(0xFFD6F995),
    Color(0xFFC6E2FF),
    Color(0xFFE2C6FF),
    Color(0xFFFFE4CC),
    Color(0xFFD4F4DD),
    Color(0xFFFFD6E8),
  ];

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final isEditable = userStore.isLoggedIn() &&
        userStore.user?.userData.domain == data.domain;
    final isEditMode = !isPreviewMode && isEditable;

    final tags = data.tags.isNotEmpty
        ? data.tags
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .take(5)
            .map((t) => t.length > 20 ? t.substring(0, 20) : t)
            .toList()
        : <String>[];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview / Edit 切换（仅当可编辑时显示）
        if (isEditable) ...[
          _buildPreviewEditToggle(context),
          const SizedBox(height: 24),
        ],
        // 头像
        ProfileAvatar(
          avatarUrl: data.avatarUrl,
          userName: data.name.isNotEmpty ? data.name : username,
          editable: isEditMode,
          size: 180,
          jobStatus: data.jobStatus,
          onAvatarUpdated: onAvatarUpdated,
          onStatusEdit: isEditable ? onStatusEdit : null,
        ),
        const SizedBox(height: 8),
        // 姓名（编辑态空时显示占位）
        _buildNameOrPlaceholder(isEditMode),
        const SizedBox(height: 8),
        // 职位（编辑态始终显示，空为占位）
        if (isEditMode || data.fullPosition.isNotEmpty)
          _buildRowTextOrPlaceholder(
            icon: Icons.work_outline,
            iconColor: const Color(0xFF303030),
            text: data.fullPosition,
            placeholder: 'Your position',
            isPlaceholder: isEditMode && data.fullPosition.isEmpty,
          ),
        // 学历
        if (isEditMode || data.fullDegree.isNotEmpty)
          _buildRowTextOrPlaceholder(
            icon: Icons.school_outlined,
            iconColor: const Color(0xFF7C7C7C),
            text: data.fullDegree,
            placeholder: 'Your degree',
            isPlaceholder: isEditMode && data.fullDegree.isEmpty,
          ),
        // Email
        if (isEditMode || data.email.isNotEmpty)
          _buildRowTextOrPlaceholder(
            icon: Icons.mail_outline,
            iconColor: const Color(0xFF303030),
            text: data.email,
            placeholder: 'Your email',
            isPlaceholder: isEditMode && data.email.isEmpty,
          ),
        // Location
        if (isEditMode || data.location.isNotEmpty)
          _buildRowTextOrPlaceholder(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF303030),
            text: data.location,
            placeholder: 'Your location',
            isPlaceholder: isEditMode && data.location.isEmpty,
          ),
        // Timezone（编辑态或有时区时显示）
        if (isEditMode || (data.timezone != null && data.timezone!.isNotEmpty))
          _buildRowTextOrPlaceholder(
            icon: Icons.schedule_outlined,
            iconColor: const Color(0xFF303030),
            text: data.timezone ?? '',
            placeholder: 'Select timezone',
            isPlaceholder: isEditMode && (data.timezone == null || data.timezone!.isEmpty),
          ),
        // 标签（编辑态始终显示区域，空时显示占位）
        if (isEditMode || tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          tags.isEmpty && isEditMode
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Add tag',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                      height: 24 / 15,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tags.asMap().entries.map((e) {
                    final colorIndex = e.key % _tagColors.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tagColors[colorIndex],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171717),
                          height: 20 / 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
        // 个人简介（编辑态始终显示，空为占位）
        if (isEditMode || data.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            data.bio.isEmpty && isEditMode
                ? 'Tell us about yourself...'
                : data.bio,
            style: TextStyle(
              fontSize: 16,
              color: (data.bio.isEmpty && isEditMode)
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF171717),
              height: 24 / 16,
            ),
          ),
        ],
       
        const SizedBox(height: 8),
      ],
    );
    // 仅在编辑模式（已切到 Edit）下点击头部才打开编辑弹框；Preview 时不响应
    if (isEditMode) {
      return GestureDetector(
        onTap: () {
          ProfileEditDialog.show(
            context: context,
            initialData: data,
            onSaved: onDataUpdated,
          );
        },
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  Widget _buildPreviewEditToggle(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const inset = 4.0;
        final segmentWidth = (w - inset * 2) / 2;
        final sliderWidth = segmentWidth - inset;
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: isPreviewMode ? inset : segmentWidth + inset,
                top: inset,
                bottom: inset,
                width: sliderWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onPreviewModeChanged?.call(true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isPreviewMode
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onPreviewModeChanged?.call(false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: !isPreviewMode
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameOrPlaceholder(bool isEditMode) {
    final showPlaceholder = isEditMode && data.name.isEmpty;
    final displayText = showPlaceholder
        ? 'Enter your name'
        : (data.name.isNotEmpty ? data.name : username);
    return Text(
      displayText,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: showPlaceholder ? const Color(0xFF9CA3AF) : const Color(0xFF171717),
        height: 40 / 32,
      ),
    );
  }

  Widget _buildRowTextOrPlaceholder({
    required IconData icon,
    required Color iconColor,
    required String text,
    required String placeholder,
    required bool isPlaceholder,
  }) {
    final displayText = isPlaceholder ? placeholder : text;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor.withValues(alpha: 0.64)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isPlaceholder ? const Color(0xFF9CA3AF) : const Color(0xFF171717),
                height: 24 / 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
