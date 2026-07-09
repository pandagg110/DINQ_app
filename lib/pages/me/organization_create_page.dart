import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../services/upload_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/common/read_bytes_from_path_stub.dart'
    if (dart.library.io) '../../widgets/common/read_bytes_from_path_io.dart' as path_reader;

/// 创建组织（对齐 web POST /org）。名称 + Handle(slug，带可用性检查) + 类型 + 简介。
class OrganizationCreatePage extends StatefulWidget {
  const OrganizationCreatePage({super.key});

  @override
  State<OrganizationCreatePage> createState() => _OrganizationCreatePageState();
}

class _OrganizationCreatePageState extends State<OrganizationCreatePage> {
  final _service = AccountService();
  final _uploadService = UploadService();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  Timer? _slugDebounce;

  /// idle | invalid | checking | available | taken（对齐 web SlugStatus，
  /// CreateOrganizationDialog.tsx:38-43）。
  String _slugStatus = 'idle';
  bool _submitting = false;

  /// 2–32 位小写字母/数字/连字符，首尾不能是连字符（对齐 web SLUG_REGEX，
  /// CreateOrganizationDialog.tsx:36）。
  static final _slugRegex = RegExp(r'^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$');
  String _logoUrl = '';
  String _backgroundUrl = '';
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  // 默认「未指定」（对齐 web：org_type 可选，不预选 company）。
  String _type = '';

  /// 无自定义封面时的默认 banner（对齐 web OrgBrandingEditor.tsx:53-54：
  /// backgroundUrl || DEFAULT_ORG_BANNER，而不是灰底占位）。
  static const kDefaultOrgBanner = 'assets/images/org-card.png';

  static const _descMaxLen = 200;

  // value → label，对齐 web ORG_TYPES；'' 表示未指定。
  static const _typeLabels = <String, String>{
    '': 'Not specified',
    'community': 'Community',
    'company': 'Company',
    'lab': 'Research Lab',
    'opensource': 'Open Source',
    'event': 'Event',
    'investor': 'Investor',
    'incubator': 'Incubator',
    'media': 'Media',
  };

  @override
  void dispose() {
    _slugDebounce?.cancel();
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // 对齐 web：slug 转小写、空格转连字符。
  void _onSlugInput(String v) {
    final sanitized = v.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    if (sanitized != v) {
      _slugCtrl.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    _onSlugChanged(sanitized);
  }

  void _onSlugChanged(String v) {
    _slugDebounce?.cancel();
    final slug = v.trim();
    if (slug.isEmpty) {
      setState(() => _slugStatus = 'idle');
      return;
    }
    // 格式非法直接提示，不请求（对齐 web CreateOrganizationDialog.tsx:91-94）
    if (!_slugRegex.hasMatch(slug)) {
      setState(() => _slugStatus = 'invalid');
      return;
    }
    setState(() => _slugStatus = 'checking');
    _slugDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final ok = await _service.checkOrgSlug(slug);
        if (!mounted || _slugCtrl.text.trim() != slug) return;
        setState(() => _slugStatus = ok ? 'available' : 'taken');
      } catch (_) {
        if (mounted) setState(() => _slugStatus = 'idle');
      }
    });
  }

  // 必须等 slug 校验通过才能提交（对齐 web canSubmit：
  // slugStatus.kind === "available"，CreateOrganizationDialog.tsx:118-122）
  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _slugCtrl.text.trim().isNotEmpty &&
      _slugStatus == 'available' &&
      !_submitting;

  /// Logo & 封面上传：选图 → 裁剪（封面 401:120 / logo 1:1）→ 上传 OSS。
  /// 复用 onboarding 头像那套（file_picker + croppy + UploadService）。
  Future<void> _pickImage({required bool isCover}) async {
    if (_uploadingCover || _uploadingLogo) return;
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

    Uint8List? cropped;
    try {
      final cropResult = await showMaterialImageCropper(
        context,
        imageProvider: MemoryImage(bytes),
        allowedAspectRatios: [
          isCover
              ? const CropAspectRatio(width: 401, height: 120)
              : const CropAspectRatio(width: 1, height: 1),
        ],
        enabledTransformations: const [
          Transformation.panAndScale,
          Transformation.resize,
        ],
      );
      if (cropResult != null) {
        final byteData =
            await cropResult.uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) cropped = byteData.buffer.asUint8List();
      }
    } catch (_) {
      if (mounted) _snack('Crop failed');
      return;
    }
    if (cropped == null || !mounted) return;

    setState(() => isCover ? _uploadingCover = true : _uploadingLogo = true);
    try {
      final url = await _uploadService.uploadFile(
        bytes: cropped,
        filename:
            '${isCover ? 'cover' : 'logo'}_${DateTime.now().millisecondsSinceEpoch}.png',
        contentType: 'image/png',
      );
      if (!mounted) return;
      setState(() => isCover ? _backgroundUrl = url : _logoUrl = url);
    } catch (_) {
      if (mounted) _snack('Upload failed');
    } finally {
      if (mounted) {
        setState(() => isCover ? _uploadingCover = false : _uploadingLogo = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await _service.createOrg(
        name: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim(),
        orgType: _type,
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        logoUrl: _logoUrl,
        backgroundUrl: _backgroundUrl,
      );
      if (!mounted) return;
      _snack('Organization created');
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Create failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Create organization'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _label('Logo & cover'),
          _brandingEditor(),
          const SizedBox(height: 16),
          _label('Name'),
          _input(_nameCtrl, 'DINQ Labs', maxLength: 60,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          _label('Slug'),
          _slugField(),
          const SizedBox(height: 6),
          _slugHint(),
          const SizedBox(height: 16),
          _label('Type'),
          _typeSelector(),
          const SizedBox(height: 16),
          _label('Description'),
          _descriptionField(),
          const SizedBox(height: 16),
          _label('Location'),
          _input(_locationCtrl, 'San Francisco, CA'),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _canSubmit ? _submit : null,
            child: Opacity(
              opacity: _canSubmit ? 1 : 0.5,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorUtil.textColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_submitting ? 'Creating…' : 'Create',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 对齐 web OrgBrandingEditor：封面横幅(401:120) + 叠在左下的方形 logo，
  /// 都点击换图；无 logo 显示名字首字母。
  Widget _brandingEditor() {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().characters.first.toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E6E1)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:
                    _uploadingCover ? null : () => _pickImage(isCover: true),
                child: AspectRatio(
                  aspectRatio: 401 / 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 无自定义封面时显示默认 banner（对齐 web），加载
                      // 失败同样回退默认素材
                      if (_backgroundUrl.isNotEmpty)
                        Image.network(_backgroundUrl, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                                kDefaultOrgBanner,
                                fit: BoxFit.cover))
                      else
                        Image.asset(kDefaultOrgBanner, fit: BoxFit.cover),
                      // 移动端无 hover，右下角常驻小相机作为「可点击换图」
                      // 提示（web 的 Change cover 提示是 hover 才出现）
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.camera_alt,
                              size: 14, color: Colors.white70),
                        ),
                      ),
                      if (_uploadingCover)
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // logo 承载区（对齐 web OrgBrandingEditor 的 h-9=36px）
              const SizedBox(height: 36, width: double.infinity),
            ],
          ),
          // logo 叠在封面左下。用 Positioned 固定 64x64（对齐 web
          // h-16 w-16 方形），此前 Transform.translate 放在 44 高的
          // 父容器里会把 logo 高度压到 44 导致矩形被压扁。
          Positioned(
            left: 16,
            bottom: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _uploadingLogo ? null : () => _pickImage(isCover: false),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEADFCE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_logoUrl.isNotEmpty)
                      Image.network(_logoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _logoInitials(initials))
                    else
                      _logoInitials(initials),
                    if (_uploadingLogo)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(Icons.camera_alt,
                              size: 13, color: Color(0xFF6B6862)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoInitials(String initials) => Center(
        child: Text(initials,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ColorUtil.textColor)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
      );

  /// 单层描边（12px 圆角）。必须把 enabled/focused 状态一起显式指定：
  /// 全局 inputDecorationTheme 的 enabledBorder/focusedBorder（8px 圆角）
  /// 优先级高于 decoration.border，不覆盖会叠出内外两层不同圆角的边框。
  OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Widget _input(TextEditingController c, String hint,
      {int maxLines = 1,
      int? maxLength,
      ValueChanged<String>? onChanged,
      EdgeInsets? contentPadding}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
        contentPadding: contentPadding ?? const EdgeInsets.all(14),
        // 对齐 web create dialog：enabled #D8D8D8 / focused #171717
        border: _fieldBorder(const Color(0xFFD8D8D8)),
        enabledBorder: _fieldBorder(const Color(0xFFD8D8D8)),
        focusedBorder: _fieldBorder(const Color(0xFF171717)),
      ),
    );
  }

  /// 描述输入：字符计数放在输入框内部右下角（Stack + Positioned，
  /// contentPadding 底部预留），同 onboarding_profile_expertise_view.dart。
  Widget _descriptionField() {
    return Stack(
      children: [
        _input(_descCtrl, 'A short description of what this organization does.',
            maxLines: 3,
            maxLength: _descMaxLen,
            onChanged: (_) => setState(() {}),
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 30)),
        Positioned(
          right: 12,
          bottom: 10,
          child: IgnorePointer(
            child: Text('${_descCtrl.text.characters.length}/$_descMaxLen',
                style: const TextStyle(
                    fontSize: 12, color: DinqTokens.textTertiary)),
          ),
        ),
      ],
    );
  }

  /// Handle 输入：常驻显示 `dinq.me/` 前缀（Flutter 的 prefixText 未聚焦时不显示，
  /// 会导致前缀看不见，故用 Row 常驻展示），对齐 web。
  Widget _slugField() {
    return Container(
      // 外层 Container 是唯一边框（对齐 web slug 输入的组合框样式）
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Text('dinq.me/',
              style: TextStyle(fontSize: 15, color: Color(0xFFA8A29E))),
          Expanded(
            child: TextField(
              controller: _slugCtrl,
              maxLength: 32,
              onChanged: _onSlugInput,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              decoration: const InputDecoration(
                hintText: 'dinq-labs',
                hintStyle: TextStyle(color: Color(0xFFA8A29E)),
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 2),
                // 全状态去边框：全局 inputDecorationTheme 的
                // enabledBorder/focusedBorder 会盖过 border: none，
                // 导致外层 Container 边框内再套一层输入框边框
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          // 框内右侧状态图标：转圈 / 绿勾 / 红叉（对齐 web
          // CreateOrganizationDialog.tsx:207-213）
          if (_slugStatus == 'checking')
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF9E9B93)),
            )
          else if (_slugStatus == 'available')
            const Icon(Icons.check_rounded,
                size: 16, color: Color(0xFF16A34A))
          else if (_slugStatus == 'taken')
            const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFFEF4444)),
        ],
      ),
    );
  }

  /// slug 提示行，常驻（对齐 web SlugHint，CreateOrganizationDialog.tsx:290-317）。
  Widget _slugHint() {
    switch (_slugStatus) {
      case 'invalid':
        return const Text('Use 2–32 lowercase letters, digits, or hyphens.',
            style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)));
      case 'taken':
        return const Text('Already taken',
            style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)));
      case 'available':
        return const Text('Available',
            style: TextStyle(fontSize: 12, color: Color(0xFF16A34A)));
      case 'checking':
        return const Text('Checking availability…',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93)));
      default:
        return const Text('Lowercase letters, digits, and hyphens.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93)));
    }
  }

  Widget _typeSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _type,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      style: TextStyle(fontSize: 15, color: ColorUtil.textColor),
      // 弹出面板显式白底 + 圆角：M3 默认会带 surfaceTint 紫底（同
      // onboarding_socials_view.dart PopupMenuButton 的修法；全局
      // popupMenuTheme 覆盖不到 DropdownButton 的 dropdownColor）
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: _fieldBorder(const Color(0xFFD8D8D8)),
        enabledBorder: _fieldBorder(const Color(0xFFD8D8D8)),
        focusedBorder: _fieldBorder(const Color(0xFF171717)),
      ),
      items: [
        for (final e in _typeLabels.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => setState(() => _type = v ?? ''),
    );
  }
}
