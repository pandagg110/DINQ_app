import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/upload_service.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/profile/profile_form_helpers.dart';

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  State<SettingsProfilePage> createState() => _SettingsProfilePageState();
}

class _SettingsProfilePageState extends State<SettingsProfilePage> {
  final UploadService _uploadService = UploadService();
  bool _isUploading = false;

  Future<void> _handleAvatarUpload() async {
    if (_isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() => _isUploading = true);

        try {
          final uploadedUrl = await _uploadService.uploadFile(
            bytes: file.bytes!,
            filename: file.name,
            contentType: _getContentType(file.extension),
          );

          if (!mounted) return;
          final userStore = context.read<UserStore>();
          await userStore.updateUserData({'avatar_url': uploadedUrl});
          if (!mounted) return;
          setState(() => _isUploading = false);
          TopToastUtil.showSuccess(
            context: context,
            title: 'Upload Success',
            description: 'Avatar uploaded successfully',
          );
        } catch (error) {
          if (!mounted) return;
          setState(() => _isUploading = false);
          TopToastUtil.showError(
            context: context,
            title: 'Upload Failed',
            description: error.toString(),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Select Image Error',
        description: error.toString(),
      );
    }
  }

  String _getContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final userData = userStore.user?.userData;

    return Scaffold(
      backgroundColor: ColorUtil.pageBgColor,
      appBar: DefaultAppBar(
        context,
        backgroundColor: ColorUtil.pageBgColor,
        titleString: 'Profile',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    // 头像区域
                    _buildAvatarSection(userData?.avatarUrl ?? ''),
                    const SizedBox(height: 24),
                    // 提示文字
                    _buildHintText(),
                    const SizedBox(height: 24),
                    // 第一组信息卡片：Name
                    _buildInfoCard([
                      _buildInfoRow(
                        label: 'Name',
                        value: userData?.name ?? '',
                        onTap: () => _showEditDialog(
                          title: 'Name',
                          initialValue: userData?.name ?? '',
                          field: 'name',
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // 第二组信息卡片
                    _buildInfoCard([
                      _buildInfoRow(
                        label: 'Date of Birth',
                        value: _formatDateOfBirth(userStore),
                        onTap: () => _showDatePicker(userStore),
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        label: 'Gender',
                        value: _formatGender(userStore),
                        onTap: () => _showGenderPicker(userStore),
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        label: 'Location /Timezone',
                        value: _formatLocation(userData),
                        onTap: () => _showEditDialog(
                          title: 'Location',
                          initialValue: userData?.location ?? '',
                          field: 'location',
                        ),
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        label: 'Status',
                        value: _formatStatus(userData?.jobStatus),
                        onTap: () => _showStatusPicker(userStore),
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: _buildEditProfileButton(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String avatarUrl) {
    return Stack(
      children: [
        // 头像外圈（浅蓝色）
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE0F0FF)),
          width: 90,
          height: 90,
          child: ClipOval(
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : avatarUrl.isNotEmpty
                ? NetworkImageView(
                    imageUrl: avatarUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: const Icon(Icons.person, size: 50, color: Colors.grey),
                  )
                : Container(
                    width: 90,
                    height: 90,
                    color: const Color(0xFFE0F0FF),
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
          ),
        ),
        // 相机图标
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _handleAvatarUpload,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ColorUtil.textColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(child: AssetImageView("avatar_upload", width: 14, height: 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Text(
        'Complete your profile to get smarter matches.\n🔒Your info stays private-just helps us find the right collaborators and gigs.',
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Geist',
          color: ColorUtil.textColor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return NormalButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.textColor),
            ),
            Row(
              children: [
                Text(
                  value.isNotEmpty ? value : 'Not set',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Geist',
                    color: value.isNotEmpty ? ColorUtil.sub1TextColor : ColorUtil.sub3TextColor,
                  ),
                ),
                const SizedBox(width: 4),
                AssetImageView("gray_right", width: 20, height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: const Color(0xFFF0F0F0)),
    );
  }

  Widget _buildEditProfileButton() {
    return NormalButton(
      onTap: () => context.push('/settings/profile/edit'),
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorUtil.textColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Geist',
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateOfBirth(UserStore userStore) {
    final dob = userStore.user?.userData.dateOfBirth;
    return ProfileFormConfig.formatDateForDisplay(dob);
  }

  String _formatGender(UserStore userStore) {
    final gender = userStore.user?.userData.gender;
    if (gender == null || gender.isEmpty) return '';
    return gender;
  }

  String _formatLocation(dynamic userData) {
    if (userData == null) return '';
    final location = userData.location ?? '';
    final timezone = userData.timezone ?? '';
    if (location.isNotEmpty && timezone != null && timezone.isNotEmpty) {
      return '$location $timezone';
    } else if (location.isNotEmpty) {
      return location;
    } else if (timezone != null && timezone.isNotEmpty) {
      return timezone;
    }
    return '';
  }

  String _formatStatus(String? status) {
    return ProfileFormConfig.getJobStatusLabel(status);
  }

  Future<void> _showEditDialog({
    required String title,
    required String initialValue,
    required String field,
  }) async {
    final result = await ProfileFormPickers.showTextEditDialog(
      context: context,
      title: 'Edit $title',
      initialValue: initialValue,
      hintText: 'Enter $title',
    );

    if (result != null && result != initialValue) {
      final userStore = context.read<UserStore>();
      await userStore.updateUserData({field: result});
    }
  }

  Future<void> _showDatePicker(UserStore userStore) async {
    final dob = userStore.user?.userData.dateOfBirth;
    final result = await ProfileFormPickers.showMyDatePicker(context: context, initialDateStr: dob);

    if (result != null) {
      await userStore.updateUserData({'date_of_birth': result});
    }
  }

  Future<void> _showGenderPicker(UserStore userStore) async {
    final currentGender = userStore.user?.userData.gender ?? '';
    final result = await ProfileFormPickers.showGenderPicker(
      context: context,
      currentGender: currentGender,
    );

    if (result != null) {
      await userStore.updateUserData({'gender': result});
    }
  }

  Future<void> _showStatusPicker(UserStore userStore) async {
    final currentStatus = userStore.user?.userData.jobStatus ?? '';
    final result = await ProfileFormPickers.showJobStatusPicker(
      context: context,
      currentStatus: currentStatus,
    );

    if (result != null) {
      await userStore.updateUserData({'job_status': result});
    }
  }
}
