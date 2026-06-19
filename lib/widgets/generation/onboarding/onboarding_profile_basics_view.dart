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

/// 对齐 Web `/onboarding/profile/basics/page.tsx`。
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

  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_refresh);
    widget.positionController.addListener(_refresh);
    widget.companyController.addListener(_refresh);
    widget.schoolController.addListener(_refresh);
    widget.locationController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_refresh);
    widget.positionController.removeListener(_refresh);
    widget.companyController.removeListener(_refresh);
    widget.schoolController.removeListener(_refresh);
    widget.locationController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _canContinue => widget.nameController.text.trim().isNotEmpty;

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

  Widget _buildForm() {
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
        _AvatarUploadField(
          avatarUrl: widget.avatarUrl,
          isUploading: _isAvatarUploading,
          onTap: _pickAvatar,
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Full name',
          required: true,
          controller: widget.nameController,
          placeholder: 'Ada Lovelace',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Position',
                controller: widget.positionController,
                placeholder: 'Researcher',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
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
              child: _SelectField(
                label: 'Education',
                value: widget.educationLevel,
                placeholder: 'Select',
                options: educationLevels,
                onChanged: widget.onEducationLevelChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'School',
                controller: widget.schoolController,
                placeholder: 'Stanford',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Location',
          controller: widget.locationController,
          placeholder: 'San Francisco, CA',
        ),
        const SizedBox(height: 16),
        _SelectField(
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    if (isDesktop) {
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
                  _buildForm(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingTopBar(step: 1, onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: _buildForm(),
          ),
        ),
        OnboardingDualActionFooter(
          onBack: widget.onBack,
          onContinue: widget.onContinue,
          continueEnabled: _canContinue,
        ),
      ],
    );
  }
}

class _AvatarUploadField extends StatelessWidget {
  const _AvatarUploadField({
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
                            ? const Icon(Icons.upload, size: 18, color: Color(0xFF9E9B93))
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.placeholder,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
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

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B6862),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: _inputDecoration(placeholder),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (next) => onChanged(next ?? ''),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF171717)),
    ),
  );
}
