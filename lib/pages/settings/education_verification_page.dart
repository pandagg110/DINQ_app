import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dinq_app/services/auth_service.dart';
import 'package:dinq_app/theme/dinq_tokens.dart';
import 'package:dinq_app/services/profile_service.dart';
import 'package:dinq_app/services/upload_service.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';

class EducationVerificationPage extends StatefulWidget {
  const EducationVerificationPage({super.key});

  @override
  State<EducationVerificationPage> createState() =>
      _EducationVerificationPageState();
}

class _EducationVerificationPageState extends State<EducationVerificationPage> {
  final ProfileService _profileService = ProfileService();
  final UploadService _uploadService = UploadService();
  final AuthService _authService = AuthService();

  // Student type: "current" or "graduated"
  String _studentType = 'current';

  // Form data
  String _university = '';
  String _degree = '';
  String _department = '';
  String _enrollMonth = '';
  String _enrollYear = '';
  String _verificationEmail = '';

  // Email verification state
  bool _isEmailVerified = false;

  // Uploaded documents
  List<String> _uploadedDocumentUrls = [];
  List<String> _uploadedFileNames = [];

  // Loading states
  bool _isSubmitting = false;
  bool _isUploading = false;

  // Existing verification data
  Map<String, dynamic>? _existingData;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final userStore = context.read<UserStore>();
    final verification = userStore.verify ?? {};
    final educationData =
        verification['education'] as Map<String, dynamic>? ?? {};

    if (educationData.isNotEmpty) {
      _existingData = educationData;
      final data = educationData['data'] as Map<String, dynamic>? ?? {};

      setState(() {
        _studentType = data['student_type']?.toString() ?? 'current';
        _university = data['university']?.toString() ?? '';
        _degree = data['degree']?.toString() ?? '';
        _department = data['department']?.toString() ?? '';
        _enrollMonth = data['enroll_month']?.toString() ?? '';
        _enrollYear = data['enroll_year']?.toString() ?? '';
        _verificationEmail = data['verification_email']?.toString() ?? '';
        _isEmailVerified = data['verification_email_verified'] == true;

        final documentUrls = data['documents'] ?? data['document_urls'] ?? [];
        if (documentUrls is List) {
          _uploadedDocumentUrls = documentUrls
              .map((e) => e.toString())
              .toList();
          _uploadedFileNames = _uploadedDocumentUrls.map((url) {
            try {
              final decodedUrl = Uri.decodeComponent(url);
              final parts = decodedUrl.split('/');
              final fileName = parts.last;
              return fileName.split('?').first;
            } catch (_) {
              final parts = url.split('/');
              return parts.last.split('?').first;
            }
          }).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _existingData?['status']?.toString();

    // dismissOnCapturedTaps: 用 Listener(onPointerUp) 收起键盘，不参与手势竞技场，
    // 避免裸 GestureDetector 抢走 TextField 的首次点击（首次激活弹不出键盘、需点两次）。
    return KeyboardDismissOnTap(
      dismissOnCapturedTaps: true,
      child: Scaffold(
        appBar: DefaultAppBar(
          context,
          titleString: "Education Verification",
        ),
        backgroundColor: DinqTokens.bgPage,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending status banner
                    if (status == 'pending') _buildPendingBanner(),

                    // Student type selection
                    _buildStudentTypeSelection(),
                    const SizedBox(height: 24),

                    // Form fields
                    _buildFormFields(),
                    const SizedBox(height: 24),

                    // Verification section
                    _buildVerificationSection(),
                  ],
                ),
              ),
            ),
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE277)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              Text(
                'Verification In Review',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your verification is currently being reviewed. You can update your information and resubmit if needed.',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF92400E),
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTypeSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildStudentTypeButton(
            type: 'current',
            label: 'Student',
            icon: 'icon_book',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStudentTypeButton(
            type: 'graduated',
            label: 'Graduated',
            icon: 'icon_teacher',
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTypeButton({
    required String type,
    required String label,
    required String icon,
  }) {
    final isSelected = _studentType == type;

    return NormalButton(
      onTap: () => setState(() => _studentType = type),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorUtil.textColor : const Color(0xFFD8D8D8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            AssetImageView(icon, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: ColorUtil.textColor,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // University
        _buildFormField(
          label: 'University',
          isRequired: true,
          child: _buildDropdownField(
            value: _university,
            hint: 'Open to Work',
            onTap: () => _showUniversityPicker(),
          ),
        ),
        const SizedBox(height: 16),

        // Degree
        _buildFormField(
          label: 'Degree',
          isRequired: true,
          child: _buildDropdownField(
            value: _degree,
            hint: 'Open to Work',
            onTap: () => _showDegreePicker(),
          ),
        ),
        const SizedBox(height: 16),

        // Department / Major
        _buildFormField(
          label: 'Department / Major',
          isRequired: true,
          child: _buildTextField(
            value: _department,
            hint: '',
            onChanged: (v) => setState(() => _department = v),
          ),
        ),
        const SizedBox(height: 16),

        // When did you enroll?
        _buildFormField(
          label: 'When did you enroll?',
          isRequired: false,
          child: Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: _enrollMonth,
                  hint: 'Month',
                  onTap: () => _showMonthPicker(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  value: _enrollYear,
                  hint: 'Year',
                  onTap: () => _showYearPicker(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required bool isRequired,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return NormalButton(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8D8D8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isNotEmpty ? value : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value.isNotEmpty
                      ? ColorUtil.textColor
                      : const Color(0xFF999999),
                  fontFamily: 'Geist',
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: ColorUtil.sub2TextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: ColorUtil.textColor,
          fontFamily: 'Geist',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: const Color(0xFF999999),
            fontFamily: 'Geist',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    if (_studentType == 'current') {
      return _buildCurrentStudentVerification();
    } else {
      return _buildGraduatedVerification();
    }
  }

  Widget _buildCurrentStudentVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
            children: [
              TextSpan(text: 'University Verification'),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please select one of the following authentication methods to complete your profile. You must provide either an email address or upload supporting documents.',
          style: TextStyle(
            fontSize: 12,
            color: ColorUtil.sub1TextColor,
            fontFamily: 'Geist',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Email Authentication
        _buildEmailAuthentication(),
        const SizedBox(height: 16),

        // 2. Document Upload
        _buildDocumentUpload(
          title: '2.Document Upload',
          description:
              'Please upload one of the following documents to complete your university verification:\n- Student ID Card\n- University Transcript\n- Enrollment Certificate\n- Degree Certificate\n- University Email Screenshot',
          allowMultiple: true,
        ),
      ],
    );
  }

  Widget _buildGraduatedVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
            children: [
              TextSpan(text: 'Verification'),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Document Upload
        _buildDocumentUpload(
          title: 'Document Upload',
          description:
              'Please upload the following documents to complete your university verification:\n- Graduation Certificate',
          allowMultiple: false,
        ),
      ],
    );
  }

  Widget _buildEmailAuthentication() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
            children: [
              TextSpan(text: '1.Email Authentication'),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (_isEmailVerified)
          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDDFEBC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AssetImageView("settings_success", width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          )
        else
          // Email input + Verify button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD8D8D8)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _verificationEmail = v),
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorUtil.textColor,
                      fontFamily: 'Geist',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Email address',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF999999),
                        fontFamily: 'Geist',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NormalButton(
                onTap: _handleVerifyEmail,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorUtil.textColor),
                  ),
                  child: Center(
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String description,
    required bool allowMultiple,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
            children: [
              TextSpan(text: title),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: ColorUtil.sub1TextColor,
            fontFamily: 'Geist',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // Upload area and info
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Upload button
            NormalButton(
              onTap: _uploadedDocumentUrls.length >= 3 || _isUploading
                  ? () {}
                  : _handleFileUpload,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD8D8D8),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Opacity(
                  opacity: _uploadedDocumentUrls.length >= 3 || _isUploading
                      ? 0.5
                      : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20, color: const Color(0xFF878787)),
                      const SizedBox(height: 8),
                      Text(
                        _isUploading ? 'Uploading...' : 'Upload',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF878787),
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Format info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format: JPG, PNG, or PDF',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF979797),
                    fontFamily: 'Geist',
                  ),
                ),
                Text(
                  'Max size: 10MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF979797),
                    fontFamily: 'Geist',
                  ),
                ),
                if (allowMultiple)
                  Text(
                    'Multiple files allowed (up to 3)',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF979797),
                      fontFamily: 'Geist',
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Uploaded files list
        if (_uploadedFileNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._uploadedFileNames.asMap().entries.map((entry) {
            final index = entry.key;
            final fileName = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: ColorUtil.textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  NormalButton(
                    onTap: () => _handleRemoveFile(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: const Color(0xFF878787),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFEFEFEF))),
      ),
      child: NormalButton(
        onTap: _isSubmitting ? () {} : _handleSubmit,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: _isSubmitting
                ? ColorUtil.textColor.withAlpha((255 * 0.5).toInt())
                : ColorUtil.textColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _isSubmitting ? 'Submitting...' : 'Submit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ Handlers ============

  void _handleVerifyEmail() {
    if (!_verificationEmail.contains('@')) {
      TopToastUtil.showInfo(
        context: context,
        title: 'Please enter a valid email address',
      );
      return;
    }
    _showEmailVerificationModal();
  }

  void _showEmailVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmailVerificationModal(
        email: _verificationEmail,
        authService: _authService,
        onVerifySuccess: () {
          setState(() => _isEmailVerified = true);
        },
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    if (_uploadedDocumentUrls.length >= 3) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: _studentType == 'current',
      );

      if (!mounted) return;
      if (result == null || result.files.isEmpty) return;

      final remainingSlots = 3 - _uploadedDocumentUrls.length;
      final filesToUpload = result.files.take(remainingSlots).toList();

      setState(() => _isUploading = true);

      for (final file in filesToUpload) {
        if (file.bytes == null && file.path == null) continue;

        // Check file size (10MB limit)
        final fileSize = file.size;
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            TopToastUtil.showInfo(
              context: context,
              title: '${file.name} exceeds 10MB limit',
            );
          }
          continue;
        }

        try {
          Uint8List bytes;
          if (file.bytes != null) {
            bytes = file.bytes!;
          } else {
            bytes = await File(file.path!).readAsBytes();
          }

          if (!mounted) return;

          final fileUrl = await _uploadService.uploadFile(
            bytes: bytes,
            filename: file.name,
            contentType: _getContentType(file.extension ?? ''),
          );

          if (!mounted) return;

          setState(() {
            _uploadedDocumentUrls.add(fileUrl);
            _uploadedFileNames.add(file.name);
          });
        } catch (e) {
          if (mounted) {
            TopToastUtil.showInfo(
              context: context,
              title: 'Failed to upload ${file.name}',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        TopToastUtil.showInfo(context: context, title: 'Failed to pick file');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  void _handleRemoveFile(int index) {
    setState(() {
      _uploadedDocumentUrls.removeAt(index);
      _uploadedFileNames.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    // Validate required fields
    if (_university.isEmpty || _degree.isEmpty || _department.isEmpty) {
      TopToastUtil.showInfo(
        context: context,
        title: 'Please fill in all required fields',
      );
      return;
    }

    // Validation based on student type
    if (_studentType == 'current') {
      if (!_isEmailVerified && _uploadedDocumentUrls.isEmpty) {
        TopToastUtil.showInfo(
          context: context,
          title: 'Please verify your email or upload supporting documents',
        );
        return;
      }
    } else {
      if (_uploadedDocumentUrls.isEmpty) {
        TopToastUtil.showInfo(
          context: context,
          title: 'Please upload your graduation certificate',
        );
        return;
      }
    }

    // Prepare submission data
    final submissionData = {
      'student_type': _studentType,
      'university': _university,
      'degree': _degree,
      'department': _department,
      if (_enrollMonth.isNotEmpty) 'enroll_month': _enrollMonth,
      if (_enrollYear.isNotEmpty) 'enroll_year': _enrollYear,
      if (_isEmailVerified) 'verification_email': _verificationEmail,
      if (_isEmailVerified) 'verification_email_verified': true,
      if (_uploadedDocumentUrls.isNotEmpty)
        'document_urls': _uploadedDocumentUrls,
    };

    setState(() => _isSubmitting = true);

    // 在异步操作前保存引用，确保数据更新不受 widget 销毁影响
    final userStore = context.read<UserStore>();

    try {
      await _profileService.submitEducationVerification(submissionData);

      // Update local state (即使 widget 销毁也要更新，保证数据一致性)
      userStore.updateVerify('education', {
        'status': 'pending',
        'verified': false,
        'rejection_reason': '',
        'submitted_at': DateTime.now().toIso8601String(),
        'data': submissionData,
      });

      // 跳转到成功页面（需要检查 mounted）
      if (mounted) {
        context.go('/settings/verification/success');
      }
    } catch (e) {
      if (mounted) {
        TopToastUtil.showInfo(
          context: context,
          title: 'Failed to submit: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============ Pickers ============

  void _showUniversityPicker() {
    _showSearchablePicker(
      title: 'Select University',
      initialValue: _university,
      onSelected: (value) => setState(() => _university = value),
    );
  }

  void _showDegreePicker() {
    final degrees = [
      "Associate Degree",
      "Bachelor's Degree",
      "Master's Degree",
      "Doctoral Degree (Ph.D.)",
      "Professional Degree (MBA, MD, JD, etc.)",
      "Postdoctoral",
      "Certificate",
      "Diploma",
    ];
    _showListPicker(
      title: 'Select Degree',
      items: degrees,
      selectedValue: _degree,
      onSelected: (value) => setState(() => _degree = value),
    );
  }

  void _showMonthPicker() {
    final months = [
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
    ];
    _showListPicker(
      title: 'Select Month',
      items: months,
      selectedValue: _enrollMonth,
      onSelected: (value) => setState(() => _enrollMonth = value),
    );
  }

  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(50, (i) => (currentYear - i).toString());
    _showListPicker(
      title: 'Select Year',
      items: years,
      selectedValue: _enrollYear,
      onSelected: (value) => setState(() => _enrollYear = value),
    );
  }

  void _showListPicker({
    required String title,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
                NormalButton(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(Icons.close, color: ColorUtil.textColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (ctx, index) {
                final item = items[index];
                final isSelected = item == selectedValue;
                return NormalButton(
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    color: isSelected ? const Color(0xFFF6F6F6) : Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorUtil.textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 20,
                            color: ColorUtil.textColor,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom),
        ],
      ),
    );
  }

  void _showSearchablePicker({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SearchablePickerModal(
        title: title,
        initialValue: initialValue,
        onSelected: (value) {
          onSelected(value);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ============ Email Verification Modal ============

class _EmailVerificationModal extends StatefulWidget {
  final String email;
  final AuthService authService;
  final VoidCallback onVerifySuccess;

  const _EmailVerificationModal({
    required this.email,
    required this.authService,
    required this.onVerifySuccess,
  });

  @override
  State<_EmailVerificationModal> createState() =>
      _EmailVerificationModalState();
}

class _EmailVerificationModalState extends State<_EmailVerificationModal> {
  final TextEditingController _codeController = TextEditingController();
  int _countdown = 60;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      } else {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await widget.authService.sendCode(
        email: widget.email,
        type: 'profile_verification',
      );
      if (!mounted) return;
      setState(() {
        _countdown = 60;
        _canResend = false;
      });
      _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to send verification code');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      await widget.authService.verifyCode(
        email: widget.email,
        code: _codeController.text.trim(),
      );
      widget.onVerifySuccess();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Invalid verification code');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final localPart = parts[0];
    final domain = parts[1];
    if (localPart.length <= 3) {
      return '${localPart[0]}***@$domain';
    }
    return '${localPart.substring(0, 3)}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'University Email Verification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
                NormalButton(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: ColorUtil.textColor),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Masked email
                Text(
                  _maskEmail(widget.email),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 16),

                // Code input + Resend button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD8D8D8)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 16,
                            color: ColorUtil.textColor,
                            fontFamily: 'Geist',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter verification code',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF999999),
                              fontFamily: 'Geist',
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    NormalButton(
                      onTap: _canResend && !_isSending ? _sendCode : () {},
                      child: Container(
                        width: 100,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _canResend
                                ? ColorUtil.textColor
                                : const Color(0xFFD8D8D8),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _isSending
                                ? 'Sending...'
                                : _canResend
                                ? 'Resend'
                                : '${_countdown}s',
                            style: TextStyle(
                              fontSize: 14,
                              color: _canResend
                                  ? ColorUtil.textColor
                                  : const Color(0xFF7B7B7B),
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFED7D7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFDC2626),
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Verify button
                NormalButton(
                  onTap: _isVerifying ? () {} : _verifyCode,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isVerifying
                          ? ColorUtil.textColor.withAlpha((255 * 0.5).toInt())
                          : ColorUtil.textColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _isVerifying ? 'Verifying...' : 'Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ============ Searchable Picker Modal ============

class _SearchablePickerModal extends StatefulWidget {
  final String title;
  final String initialValue;
  final ValueChanged<String> onSelected;

  const _SearchablePickerModal({
    required this.title,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<_SearchablePickerModal> createState() => _SearchablePickerModalState();
}

class _SearchablePickerModalState extends State<_SearchablePickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _universities = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialValue;
    _searchQuery = widget.initialValue;
    if (widget.initialValue.length >= 2) {
      _searchUniversities(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);

    _debounceTimer?.cancel();
    if (value.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _searchUniversities(value);
      });
    } else {
      setState(() => _universities = []);
    }
  }

  Future<void> _searchUniversities(String query) async {
    if (query.length < 2) return;

    setState(() => _isLoading = true);

    try {
      final response = await Dio().get(
        'http://universities.hipolabs.com/search',
        queryParameters: {'name': query},
      );

      if (!mounted) return;

      if (response.data is List) {
        setState(() {
          _universities = (response.data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
                NormalButton(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: ColorUtil.textColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search input
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8D8D8)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtil.textColor,
                  fontFamily: 'Geist',
                ),
                decoration: InputDecoration(
                  hintText: 'Search university...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                    fontFamily: 'Geist',
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF999999),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Results list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Text(
                      'Searching...',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF878787),
                        fontFamily: 'Geist',
                      ),
                    ),
                  )
                : _universities.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.length < 2
                          ? 'Type at least 2 characters'
                          : 'No universities found',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF878787),
                        fontFamily: 'Geist',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _universities.length,
                    itemBuilder: (ctx, index) {
                      final university = _universities[index];
                      final name = university['name']?.toString() ?? '';
                      final country = university['country']?.toString() ?? '';
                      final isSelected = name == widget.initialValue;
                      return NormalButton(
                        onTap: () => widget.onSelected(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected
                              ? const Color(0xFFF6F6F6)
                              : Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ColorUtil.textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                    if (country.isNotEmpty)
                                      Text(
                                        country,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF878787),
                                          fontFamily: 'Geist',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 20,
                                  color: ColorUtil.textColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Custom input option
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
            ),
            child: NormalButton(
              onTap: () {
                if (_searchQuery.isNotEmpty) {
                  widget.onSelected(_searchQuery);
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: ColorUtil.textColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Use "${_searchQuery.isNotEmpty ? _searchQuery : "custom input"}"',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Geist',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
