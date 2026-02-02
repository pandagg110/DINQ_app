import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/profile/profile_form_helpers.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  String _dateOfBirth = '';
  String _gender = '';
  String _jobStatus = '';
  String _location = '';
  bool _agreedToPrivacy = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final userStore = context.read<UserStore>();
    final userData = userStore.user?.userData;

    _nameController = TextEditingController(text: userData?.name ?? '');
    _dateOfBirth = (userData?.dateOfBirth?.length ?? 0) >= 10
        ? (userData?.dateOfBirth?.substring(0, 10) ?? '')
        : '';
    _gender = userData?.gender ?? '';
    _jobStatus = userData?.jobStatus ?? '';
    _location = userData?.location ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_agreedToPrivacy) {
      TopToastUtil.showError(
        context: context,
        title: 'Error',
        description: 'Please agree to the privacy policy',
      );
      return;
    }

    if (_nameController.text.isEmpty || _dateOfBirth.isEmpty || _gender.isEmpty) {
      TopToastUtil.showError(
        context: context,
        title: 'Error',
        description: 'Please fill in all required fields',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userStore = context.read<UserStore>();
      await userStore.updateUserData({
        'name': _nameController.text,
        'date_of_birth': _dateOfBirth,
        'gender': _gender,
        'job_status': _jobStatus,
        'location': _location,
      });

      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: 'Success',
        description: 'Profile updated successfully',
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      TopToastUtil.showError(context: context, title: 'Error', description: error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: ColorUtil.pageBgColor,
        appBar: DefaultAppBar(
          context,
          backgroundColor: ColorUtil.pageBgColor,
          titleString: 'Profile Information',
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // 提示文字（黄色背景）
                      _buildHintBanner(),
                      const SizedBox(height: 24),
                      // Name
                      _buildFormField(
                        label: 'Name',
                        showInfo: true,
                        child: _buildTextField(controller: _nameController, hintText: 'Enter name'),
                      ),
                      const SizedBox(height: 20),
                      // Date of Birth
                      _buildFormField(
                        label: 'Date of Birth',
                        showInfo: true,
                        child: _buildDatePicker(),
                      ),
                      const SizedBox(height: 20),
                      // Gender / Pronouns
                      _buildFormField(
                        label: 'Gender / Pronouns',
                        showInfo: true,
                        child: _buildGenderSelector(),
                      ),
                      const SizedBox(height: 20),
                      // Job Status
                      _buildFormField(label: 'Job Status', child: _buildJobStatusSelector()),
                      const SizedBox(height: 20),
                      // Location / Timezone
                      _buildFormField(
                        label: 'Location /Timezone',
                        showInfo: true,
                        child: _buildLocationSelector(),
                      ),
                      const SizedBox(height: 24),
                      // 隐私协议
                      _buildPrivacyAgreement(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // 底部 Confirm 按钮
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF0B9), // 浅黄色背景
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'We will never share your profile information publicly. These details are only used to provide better talent and opportunity matching for you.',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Geist',
          color: ColorUtil.textColor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child, bool showInfo = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist',
                color: ColorUtil.textColor,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 16, color: ColorUtil.sub3TextColor),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.sub3TextColor),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final result = await ProfileFormPickers.showMyDatePicker(
          context: context,
          initialDateStr: _dateOfBirth,
        );
        if (result != null) {
          setState(() => _dateOfBirth = result);
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateOfBirth.isNotEmpty ? _dateOfBirth : 'Select a date',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Geist',
                color: _dateOfBirth.isNotEmpty ? ColorUtil.textColor : ColorUtil.sub3TextColor,
              ),
            ),
            AssetImageView("settings_calendar", width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return _buildSelector(
      value: _gender,
      hint: 'Male',
      onTap: () async {
        final result = await ProfileFormPickers.showGenderPicker(
          context: context,
          currentGender: _gender,
        );
        if (result != null) {
          setState(() => _gender = result);
        }
      },
    );
  }

  Widget _buildJobStatusSelector() {
    return _buildSelector(
      value: ProfileFormConfig.getJobStatusLabel(_jobStatus),
      hint: 'Not set',
      onTap: () async {
        final result = await ProfileFormPickers.showJobStatusPicker(
          context: context,
          currentStatus: _jobStatus,
        );
        if (result != null) {
          setState(() => _jobStatus = result);
        }
      },
    );
  }

  Widget _buildLocationSelector() {
    return _buildSelector(
      value: _location,
      hint: 'Location /Timezone',
      onTap: () async {
        final result = await ProfileFormPickers.showTextEditDialog(
          context: context,
          title: 'Location / Timezone',
          initialValue: _location,
          hintText: 'Enter location',
        );
        if (result != null) {
          setState(() => _location = result);
        }
      },
    );
  }

  Widget _buildSelector({
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value.isNotEmpty ? value : hint,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Geist',
                  color: value.isNotEmpty ? ColorUtil.textColor : ColorUtil.sub3TextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 24, color: ColorUtil.sub3TextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyAgreement() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToPrivacy = !_agreedToPrivacy),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: _agreedToPrivacy ? ColorUtil.textColor : const Color(0xFFE5E5E5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
              color: _agreedToPrivacy ? ColorUtil.textColor : Colors.white,
            ),
            child: _agreedToPrivacy ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'I understand that my personal information will be kept private and only used to enhance talent and opportunity matching.',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Geist',
                color: ColorUtil.sub1TextColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final isValid =
        _nameController.text.isNotEmpty &&
        _agreedToPrivacy &&
        _dateOfBirth.isNotEmpty &&
        _gender.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      child: NormalButton(
        onTap: isValid && !_isSubmitting ? _handleSubmit : () {},
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isValid ? ColorUtil.textColor : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
