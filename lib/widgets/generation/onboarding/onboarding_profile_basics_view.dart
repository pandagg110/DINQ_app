import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/upload_service.dart';
import '../../../utils/onboarding_draft_mapping.dart';
import '../../../utils/top_toast_util.dart';
import '../../common/read_bytes_from_path_stub.dart'
    if (dart.library.io) '../../common/read_bytes_from_path_io.dart' as path_reader;
import 'onboarding_footer.dart';
import 'onboarding_profile_preview.dart';
import 'onboarding_top_bar.dart';

/// 对齐 Web `/onboarding/profile/basics`；移动端对齐 Profile Details 设计稿。
class OnboardingProfileBasicsView extends StatefulWidget {
  const OnboardingProfileBasicsView({
    super.key,
    required this.nameController,
    required this.positionController,
    required this.companyController,
    required this.schoolController,
    required this.locationController,
    required this.avatarUrl,
    required this.educationLevel,
    required this.timezone,
    required this.onAvatarChanged,
    required this.onEducationLevelChanged,
    required this.onTimezoneChanged,
    required this.previewTags,
    required this.previewBio,
    required this.onBack,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final TextEditingController positionController;
  final TextEditingController companyController;
  final TextEditingController schoolController;
  final TextEditingController locationController;
  final String avatarUrl;
  final String educationLevel;
  final String timezone;
  final ValueChanged<String> onAvatarChanged;
  final ValueChanged<String> onEducationLevelChanged;
  final ValueChanged<String> onTimezoneChanged;
  final List<String> previewTags;
  final String previewBio;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<OnboardingProfileBasicsView> createState() =>
      _OnboardingProfileBasicsViewState();
}

class _OnboardingProfileBasicsViewState
    extends State<OnboardingProfileBasicsView> {
  final _uploadService = UploadService();
  bool _isAvatarUploading = false;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  void initState() {
    super.initState();
    for (final c in [
      widget.nameController,
      widget.positionController,
      widget.companyController,
      widget.schoolController,
      widget.locationController,
    ]) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final c in [
      widget.nameController,
      widget.positionController,
      widget.companyController,
      widget.schoolController,
      widget.locationController,
    ]) {
      c.removeListener(_refresh);
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _canContinue => !_isAvatarUploading;

  Future<void> _pickAvatar() async {
    if (_isAvatarUploading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      try {
        bytes = await path_reader.readBytesFromPath(file.path!);
      } catch (_) {}
    }
    if (bytes == null || !mounted) return;

    Uint8List? croppedBytes;
    try {
      final cropResult = await showMaterialImageCropper(
        context,
        imageProvider: MemoryImage(bytes),
        cropPathFn: ellipseCropShapeFn,
        allowedAspectRatios: const [CropAspectRatio(width: 1, height: 1)],
        enabledTransformations: const [
          Transformation.panAndScale,
          Transformation.resize,
        ],
      );
      if (cropResult != null) {
        final byteData =
            await cropResult.uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          croppedBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Crop failed',
          description: 'Failed to crop image',
        );
      }
      return;
    }
    if (croppedBytes == null || !mounted) return;

    setState(() => _isAvatarUploading = true);
    try {
      final url = await _uploadService.uploadFile(
        bytes: croppedBytes,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.png',
        contentType: 'image/png',
      );
      if (!mounted) return;
      widget.onAvatarChanged(url);
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Upload failed',
          description: 'Failed to upload avatar',
        );
      }
    } finally {
      if (mounted) setState(() => _isAvatarUploading = false);
    }
  }

  OnboardingProfilePreview _buildPreview() {
    return OnboardingProfilePreview(
      name: widget.nameController.text.trim(),
      position: widget.positionController.text.trim(),
      company: widget.companyController.text.trim(),
      school: widget.schoolController.text.trim(),
      location: widget.locationController.text.trim(),
      timezone: widget.timezone,
      bio: widget.previewBio,
      avatarUrl: widget.avatarUrl,
      tags: widget.previewTags,
    );
  }

  Widget _buildMobileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Profile Details',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Let's get your basic information set up for your workspace.",
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B6862),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        _FormLabel(label: 'AVATAR'),
        const SizedBox(height: 10),
        _MobileAvatarPicker(
          avatarUrl: widget.avatarUrl,
          isUploading: _isAvatarUploading,
          onTap: _pickAvatar,
        ),
        const SizedBox(height: 20),
        _FormField(
          label: 'FULL NAME',
          required: true,
          controller: widget.nameController,
          placeholder: 'Mark Qu',
          uppercaseLabel: true,
        ),
        const SizedBox(height: 20),
        _FormField(
          label: 'POSITION',
          controller: widget.positionController,
          placeholder: 'e.g., CEO and Co-founder',
          uppercaseLabel: true,
        ),
        const SizedBox(height: 20),
        _FormField(
          label: 'COMPANY',
          controller: widget.companyController,
          placeholder: 'e.g., DINQ',
          uppercaseLabel: true,
        ),
        const SizedBox(height: 20),
        _FormSelect(
          label: 'EDUCATION',
          value: widget.educationLevel,
          placeholder: 'Select level',
          options: educationLevels,
          onChanged: widget.onEducationLevelChanged,
          uppercaseLabel: true,
        ),
        const SizedBox(height: 20),
        _FormField(
          label: 'SCHOOL',
          controller: widget.schoolController,
          placeholder: 'e.g., USTC',
          uppercaseLabel: true,
        ),
        const SizedBox(height: 20),
        _FormField(
          label: 'LOCATION',
          controller: widget.locationController,
          placeholder: 'e.g., Beijing',
          uppercaseLabel: true,
        ),
        const SizedBox(height: 20),
        _FormSelect(
          label: 'TIMEZONE',
          value: widget.timezone,
          placeholder: 'Select timezone',
          options: onboardingTimezones,
          onChanged: widget.onTimezoneChanged,
          uppercaseLabel: true,
        ),
      ],
    );
  }

  Widget _buildDesktopForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Basic information',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is the identity block people see first on your DINQ page.',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF6B6862),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _DesktopAvatarUploadField(
          avatarUrl: widget.avatarUrl,
          isUploading: _isAvatarUploading,
          onTap: _pickAvatar,
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Full name',
          required: true,
          controller: widget.nameController,
          placeholder: 'Ada Lovelace',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Position',
                controller: widget.positionController,
                placeholder: 'Researcher',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormField(
                label: 'Company',
                controller: widget.companyController,
                placeholder: 'Acme Inc.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FormSelect(
                label: 'Education',
                value: widget.educationLevel,
                placeholder: 'Select',
                options: educationLevels,
                onChanged: widget.onEducationLevelChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormField(
                label: 'School',
                controller: widget.schoolController,
                placeholder: 'Stanford',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Location',
          controller: widget.locationController,
          placeholder: 'San Francisco, CA',
        ),
        const SizedBox(height: 16),
        _FormSelect(
          label: 'Timezone',
          value: widget.timezone,
          placeholder: 'Select timezone',
          options: onboardingTimezones,
          onChanged: widget.onTimezoneChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile(context)) {
      final bottomPad = MediaQuery.paddingOf(context).bottom;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingTopBar(step: 1, onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: _buildMobileForm(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
            child: _BasicsContinueButton(
              onPressed: _canContinue ? widget.onContinue : null,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(56, 64, 56, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingTopBar(step: 1, onBack: widget.onBack),
                const SizedBox(height: 32),
                _buildDesktopForm(),
                const SizedBox(height: 32),
                OnboardingDualActionFooter(
                  onBack: widget.onBack,
                  onContinue: widget.onContinue,
                  continueEnabled: _canContinue,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
            child: Center(child: _buildPreview()),
          ),
        ),
      ],
    );
  }
}

class _BasicsContinueButton extends StatelessWidget {
  const _BasicsContinueButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? const Color(0xFF171717) : const Color(0xFFE5E5E5),
          foregroundColor: enabled
              ? Colors.white
              : const Color(0xFF303030).withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MobileAvatarPicker extends StatelessWidget {
  const _MobileAvatarPicker({
    required this.avatarUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String avatarUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFEEEDE9)),
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl.isEmpty
                  ? const Icon(
                      Icons.file_upload_outlined,
                      size: 28,
                      color: Color(0xFF9E9B93),
                    )
                  : null,
            ),
            if (isUploading)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopAvatarUploadField extends StatelessWidget {
  const _DesktopAvatarUploadField({
    required this.avatarUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String avatarUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avatar',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B6862),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFFFAFAF8),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isUploading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDCD9D2),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFEEEDE9)),
                          image: avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl.isEmpty
                            ? const Icon(Icons.upload,
                                size: 18, color: Color(0xFF9E9B93))
                            : null,
                      ),
                      if (isUploading)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      avatarUrl.isNotEmpty ? 'Change photo' : 'Upload a photo',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: Color(0xFF6B6862),
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEEEDE9)),
                    ),
                    child: const Text(
                      'Choose File',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: Color(0xFF9E9B93),
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444), letterSpacing: 0),
                ),
              ]
            : null,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.placeholder,
    this.required = false,
    this.uppercaseLabel = false,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool required;
  final bool uppercaseLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        uppercaseLabel
            ? _FormLabel(label: label, required: required)
            : RichText(
                text: TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B6862),
                  ),
                  children: required
                      ? const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ]
                      : null,
                ),
              ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: _inputDecoration(placeholder),
        ),
      ],
    );
  }
}

class _FormSelect extends StatelessWidget {
  const _FormSelect({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onChanged,
    this.uppercaseLabel = false,
  });

  final String label;
  final String value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool uppercaseLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        uppercaseLabel
            ? _FormLabel(label: label)
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B6862),
                ),
              ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Colors.white,
              surfaceTint: Colors.transparent,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: dropdownValueOrNull(value, options),
            decoration: _inputDecoration(placeholder),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9B93)),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (next) => onChanged(next ?? ''),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Geist',
      fontSize: 14,
      color: Color.fromRGBO(48, 48, 48, 0.4),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF171717)),
    ),
  );
}
