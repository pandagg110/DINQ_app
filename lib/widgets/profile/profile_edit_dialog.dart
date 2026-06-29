import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:croppy/croppy.dart';

import '../../models/user_models.dart';
import '../../services/upload_service.dart';
import '../../stores/user_store.dart';
import '../../utils/image_utils.dart';

/// Bottom sheet for editing profile data.
class ProfileEditDialog {
  static Future<bool?> show({
    required BuildContext context,
    required UserData initialData,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _ProfileEditBottomSheet(
          initialData: initialData,
          onSaved: onSaved,
        );
      },
    );
  }
}

class _ProfileEditBottomSheet extends StatefulWidget {
  const _ProfileEditBottomSheet({required this.initialData, this.onSaved});

  final UserData initialData;
  final VoidCallback? onSaved;

  @override
  State<_ProfileEditBottomSheet> createState() =>
      _ProfileEditBottomSheetState();
}

const List<Map<String, String>> _kJobStatuses = [
  {'value': '', 'label': 'Not set'},
  {'value': 'Hiring', 'label': 'Hiring'},
  {'value': 'Open_to_work', 'label': 'Open to work'},
  {'value': 'Internship', 'label': 'Internship'},
  {'value': 'Freelance', 'label': 'Freelance'},
  {'value': 'Hidden', 'label': 'Hidden'},
];

const List<String> _kTimezones = [
  '',
  'UTC',
  'America/New_York',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Paris',
  'Asia/Shanghai',
  'Asia/Tokyo',
  'Australia/Sydney',
];

class _ProfileEditBottomSheetState extends State<_ProfileEditBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _degreeController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _tagInputController;

  String _jobStatus = '';
  String? _timezone;
  List<String> _tags = [];
  String? _avatarUrl;
  bool _isAvatarUploading = false;

  final UploadService _uploadService = UploadService();

  bool _shouldLiftForKeyboard = false;
  bool _keyboardAlreadyActive = false;
  double? _safeAreaBottom;
  double _lastKeyboardHeight = 0.0;
  final ScrollController _scrollController = ScrollController();

  String get _displayAvatarUrl => _avatarUrl ?? widget.initialData.avatarUrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameController = TextEditingController(text: d.name);
    _positionController = TextEditingController(text: d.fullPosition);
    _degreeController = TextEditingController(text: d.fullDegree);
    _emailController = TextEditingController(text: d.email);
    _locationController = TextEditingController(text: d.location);
    _bioController = TextEditingController(text: d.bio);
    _tagInputController = TextEditingController();
    _jobStatus = d.jobStatus ?? '';
    _timezone = d.timezone;
    _tags = d.tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _degreeController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _tagInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _measureAndUpdateLift() {
    if (!mounted) return;
    final mq = MediaQuery.of(context);
    if (mq.viewInsets.bottom == 0) return;
    final focusNode = FocusManager.instance.primaryFocus;
    bool shouldLift = false;
    if (focusNode != null && focusNode.context != null) {
      final box = focusNode.context!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final distanceToBottom = screenHeight - (pos.dy + box.size.height);
        shouldLift = distanceToBottom < 300;
      }
    }
    if (shouldLift != _shouldLiftForKeyboard) {
      setState(() => _shouldLiftForKeyboard = shouldLift);
    }
  }

  Future<void> _onSave() async {
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'full_position': _positionController.text.trim(),
      'full_degree': _degreeController.text.trim(),
      'email': _emailController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
      'tags': _tags.join(','),
    };
    if (_jobStatus.isNotEmpty) payload['job_status'] = _jobStatus;
    if (_timezone != null && _timezone!.isNotEmpty) {
      payload['timezone'] = _timezone;
    }
    await context.read<UserStore>().updateUserData(payload);
    widget.onSaved?.call();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _addTag() {
    final t = _tagInputController.text.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() {
      _tags = [..._tags, t];
      _tagInputController.clear();
    });
  }

  void _removeTag(int index) {
    setState(() => _tags = [..._tags]..removeAt(index));
  }

  Future<void> _pickCropAndUploadAvatar() async {
    final imageFile = await ImageUtils.pickSinglePicture(context);
    if (imageFile == null || !mounted) return;

    final imageBytes = await imageFile.readAsBytes();
    if (!mounted) return;

    Uint8List? croppedBytes;
    try {
      final result = await showMaterialImageCropper(
        context,
        imageProvider: MemoryImage(imageBytes),
        cropPathFn: ellipseCropShapeFn,
        allowedAspectRatios: [const CropAspectRatio(width: 1, height: 1)],
        enabledTransformations: [
          Transformation.panAndScale,
          Transformation.resize,
        ],
      );
      if (result != null) {
        final byteData = await result.uiImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          croppedBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (e) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Crop Failed',
          description: e.toString(),
        );
      }
      return;
    }

    if (croppedBytes == null || !mounted) return;
    setState(() => _isAvatarUploading = true);
    try {
      final fileUrl = await _uploadService.uploadFile(
        bytes: croppedBytes,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.png',
        contentType: 'image/png',
      );
      if (!mounted) return;
      await context.read<UserStore>().updateUserData({'avatar_url': fileUrl});
      if (!mounted) return;

      setState(() {
        _avatarUrl = fileUrl;
        _isAvatarUploading = false;
      });
      TopToastUtil.showSuccess(
        context: context,
        title: 'Avatar Updated',
        description: '',
      );
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _isAvatarUploading = false);
        TopToastUtil.showError(
          context: context,
          title: 'Upload Failed',
          description: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _safeAreaBottom ??= MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = _safeAreaBottom!;
    final mq = MediaQuery.of(context);
    final currentKeyboardHeight = mq.viewInsets.bottom;
    if (_lastKeyboardHeight > 0 && currentKeyboardHeight == 0) {
      _keyboardAlreadyActive = false;
      _shouldLiftForKeyboard = false;
    }
    _lastKeyboardHeight = currentKeyboardHeight;
    if (currentKeyboardHeight > 0 && !_keyboardAlreadyActive) {
      _keyboardAlreadyActive = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _measureAndUpdateLift(),
      );
    }
    final bottomInset = _shouldLiftForKeyboard ? mq.viewInsets.bottom : 0.0;

    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 缃《澶撮儴锛氫笉闅忔粴鍔ㄩ殣钘忥紝宸?EditProfile銆佸彸 Save
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EditProfile',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                  TextButton(
                    onPressed: _onSave,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 鍙粴鍔ㄥ唴瀹瑰尯
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + safeAreaBottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 澶村儚鍖猴細宸﹀榻愶紝鏀寔鐐瑰嚮淇敼
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _isAvatarUploading
                                  ? null
                                  : _pickCropAndUploadAvatar,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: const Color(0xFFE5E7EB),
                                backgroundImage: _displayAvatarUrl.isNotEmpty
                                    ? NetworkImage(_displayAvatarUrl)
                                    : null,
                                child: _displayAvatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Color(0xFF9CA3AF),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isAvatarUploading
                                      ? null
                                      : _pickCropAndUploadAvatar,
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Image.asset(
                                      'assets/profile/img-add-icon.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_isAvatarUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.2),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        'Your name',
                        _nameController,
                        hint: 'Your name',
                        maxLength: 25,
                      ),
                      const SizedBox(height: 12),
                      _buildJobStatusDropdown(),
                      const SizedBox(height: 12),
                      _buildField(
                        'Position',
                        _positionController,
                        hint: 'Your Position',
                        maxLength: 100,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Degree',
                        _degreeController,
                        hint: 'Your degree',
                        maxLength: 100,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Email',
                        _emailController,
                        hint: 'Your email',
                        maxLength: 50,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Location',
                        _locationController,
                        hint: 'Your location',
                        maxLength: 40,
                      ),
                      const SizedBox(height: 12),
                      _buildTimezoneDropdown(),
                      const SizedBox(height: 12),
                      _buildField(
                        'Introduction',
                        _bioController,
                        hint: 'Tell us about yourself.',
                        maxLength: 200,
                        maxLines: 5,
                        showCounter: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTagsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobStatusDropdown() {
    final initialValue = _kJobStatuses.any((e) => e['value'] == _jobStatus)
        ? _jobStatus
        : _kJobStatuses.first['value']!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Status',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 6),
        DropdownMenu<String>(
          key: ValueKey('job_$initialValue'),
          initialSelection: initialValue,
          hintText: 'Not set',
          enableSearch: false,
          enableFilter: false,
          dropdownMenuEntries: _kJobStatuses
              .map(
                (e) => DropdownMenuEntry<String>(
                  value: e['value']!,
                  label: e['label']!,
                ),
              )
              .toList(),
          onSelected: (v) => setState(() => _jobStatus = v ?? ''),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    final hasValue = _timezone != null && _timezone!.isNotEmpty;
    final initialValue = hasValue ? _timezone! : _kTimezones.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timezone',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 6),
        DropdownMenu<String>(
          key: ValueKey('tz_$initialValue'),
          initialSelection: initialValue,
          hintText: 'Select timezone',
          enableSearch: false,
          enableFilter: false,
          dropdownMenuEntries: _kTimezones
              .map(
                (tz) => DropdownMenuEntry<String>(
                  value: tz,
                  label: tz.isEmpty ? 'Select timezone' : tz,
                ),
              )
              .toList(),
          onSelected: (v) =>
              setState(() => _timezone = (v == null || v.isEmpty) ? null : v),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        ),
      ],
    );
  }

  static const List<Color> _tagColors = [
    Color(0xFFFDE277),
    Color(0xFFFED7D7),
    Color(0xFFD6F995),
    Color(0xFFC6E2FF),
    Color(0xFFE2C6FF),
    Color(0xFFFFE4CC),
    Color(0xFFD4F4DD),
    Color(0xFFFFD6E8),
  ];

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Tags',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: InputDecoration(
                  hintText: 'Add Tags',
                  hintStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF171717),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: Color(0xFF171717),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _addTag,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_tags.length, (i) {
              final color = _tagColors[i % _tagColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tags[i],
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(i),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required String hint,
    int maxLength = 100,
    int maxLines = 1,
    bool showCounter = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            counterText: showCounter ? null : '',
            counterStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
        ),
      ],
    );
  }
}
