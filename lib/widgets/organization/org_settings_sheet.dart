import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../services/upload_service.dart';
import '../../utils/top_toast_util.dart';
import '../common/read_bytes_from_path_stub.dart'
    if (dart.library.io) '../common/read_bytes_from_path_io.dart'
    as path_reader;

/// 删除组织二次确认（对齐 web profileHeader.deleteDialog / settings.danger，
/// 两处文案一致：标题「Delete this organization?」+ 加粗组织名正文 +
/// 红色「Delete organization」确认按钮）。返回是否确认。
Future<bool> showDeleteOrganizationConfirm(
    BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Delete this organization?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717))),
      content: Text.rich(
        TextSpan(
          text: 'This will permanently delete ',
          children: [
            TextSpan(
                text: name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF171717))),
            const TextSpan(text: ' and all its cards. This cannot be undone.'),
          ],
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Color(0xFF6B6862)))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete organization',
                style: TextStyle(
                    color: Color(0xFFDC2626), fontWeight: FontWeight.w600))),
      ],
    ),
  );
  return ok == true;
}

/// 组织设置弹层，对齐 web OrgSettingsModal.tsx：
/// - Branding 区（settings.branding「Logo & cover」）：封面 + logo 即选即传即存
///   （web OrgBrandingEditor + persist PUT /orgs/{id}，OrgSettingsModal.tsx:47-82），
///   有自定义封面时提供「Reset cover to default」（onBackgroundReset，tsx:78）。
/// - 基础字段（web 在 OrgProfileHeader 用 InlineEditText 内联编辑
///   name/location/description；App 无内联编辑形态，收敛到设置里统一编辑保存）。
/// - Danger zone（settings.danger）：仅 owner 可见 Delete organization。
/// 权限：入口仅 canManage(owner/admin) 打开；删除仅 owner（web layout.tsx:62-63）。
class OrgSettingsSheet extends StatefulWidget {
  const OrgSettingsSheet({
    super.key,
    required this.org,
    required this.canDelete,
    required this.onPatched,
    required this.onDeleted,
  });

  final Map<String, dynamic> org;
  final bool canDelete;

  /// 每次成功 PUT 后回传补丁（后端只回显提交字段，父层需本地合并）。
  final ValueChanged<Map<String, dynamic>> onPatched;

  /// 删除成功且弹层已关闭后回调（父层负责退出详情页）。
  final VoidCallback onDeleted;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> org,
    required bool canDelete,
    required ValueChanged<Map<String, dynamic>> onPatched,
    required VoidCallback onDeleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrgSettingsSheet(
        org: org,
        canDelete: canDelete,
        onPatched: onPatched,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<OrgSettingsSheet> createState() => _OrgSettingsSheetState();
}

class _OrgSettingsSheetState extends State<OrgSettingsSheet> {
  static const _ink = Color(0xFF171717);
  static const _muted = Color(0xFF6B6862);
  static const _border = Color(0xFFE8E6E1);
  static const _danger = Color(0xFFDC2626);
  static const _descMaxLen = 200;

  /// 无自定义封面时的默认 banner（对齐 web DEFAULT_ORG_BANNER）。
  static const kDefaultOrgBanner = 'assets/images/org-card.png';

  final _service = AccountService();
  final _uploadService = UploadService();

  late final TextEditingController _nameCtrl =
      TextEditingController(text: (widget.org['name'] ?? '').toString());
  late final TextEditingController _locationCtrl =
      TextEditingController(text: (widget.org['location'] ?? '').toString());
  late final TextEditingController _descCtrl =
      TextEditingController(text: (widget.org['description'] ?? '').toString());

  late String _logoUrl = (widget.org['logo_url'] ?? '').toString();
  late String _backgroundUrl =
      (widget.org['background_url'] ?? '').toString();
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  bool _saving = false;
  bool _deleting = false;

  String get _orgId => (widget.org['id'] ?? '').toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toastSuccess(String title) {
    if (!mounted) return;
    TopToastUtil.showSuccess(context: context, title: title, description: '');
  }

  void _toastError(String title) {
    if (!mounted) return;
    TopToastUtil.showError(context: context, title: title, description: '');
  }

  /// 选图 → 裁剪（封面 401:120 / logo 1:1）→ 上传 OSS → PUT 持久化。
  /// 复用 organization_create_page 的 file_picker + croppy + UploadService
  /// 链路；区别是设置页要即传即存（web OrgSettingsModal persist，tsx:57-65）。
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
      _toastError('Crop failed');
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
      final field = isCover ? 'background_url' : 'logo_url';
      await _service.updateOrg(_orgId, {field: url});
      if (!mounted) return;
      setState(() => isCover ? _backgroundUrl = url : _logoUrl = url);
      widget.onPatched({field: url});
      _toastSuccess(isCover ? 'Cover updated' : 'Logo updated');
    } catch (_) {
      _toastError('Upload failed');
    } finally {
      if (mounted) {
        setState(
            () => isCover ? _uploadingCover = false : _uploadingLogo = false);
      }
    }
  }

  /// 封面重置为默认（web onBackgroundReset → persist {background_url: ""}）。
  Future<void> _resetCover() async {
    if (_uploadingCover) return;
    setState(() => _uploadingCover = true);
    try {
      await _service.updateOrg(_orgId, {'background_url': ''});
      if (!mounted) return;
      setState(() => _backgroundUrl = '');
      widget.onPatched({'background_url': ''});
      _toastSuccess('Cover reset to default');
    } catch (_) {
      _toastError('Update failed');
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && !_saving;

  /// 保存基础字段：只提交有变化的字段（web InlineEditText 每字段独立
  /// PUT；App 收敛为一次提交）。
  Future<void> _save() async {
    if (!_canSave) return;
    final patch = <String, dynamic>{};
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final description = _descCtrl.text.trim();
    if (name != (widget.org['name'] ?? '').toString()) patch['name'] = name;
    if (location != (widget.org['location'] ?? '').toString()) {
      patch['location'] = location;
    }
    if (description != (widget.org['description'] ?? '').toString()) {
      patch['description'] = description;
    }
    if (patch.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.updateOrg(_orgId, patch);
      if (!mounted) return;
      widget.onPatched(patch);
      _toastSuccess('Organization updated');
      Navigator.of(context).pop();
    } catch (_) {
      _toastError('Update failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    final name = (widget.org['name'] ?? 'Organization').toString();
    final ok = await showDeleteOrganizationConfirm(context, name);
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteOrg(_orgId);
      if (!mounted) return;
      _toastSuccess('$name deleted');
      Navigator.of(context).pop();
      widget.onDeleted();
    } catch (_) {
      _toastError('Delete failed');
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏（web AdaptiveModal title「Settings」+ 右上 X）
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Settings',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _ink)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: _muted),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeading('Logo & cover'),
                      const SizedBox(height: 8),
                      _brandingEditor(),
                      if (_backgroundUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _resetCover,
                          child: const Text('Reset cover to default',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _muted,
                                  decoration: TextDecoration.underline)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _label('Name'),
                      _input(_nameCtrl, 'Organization name',
                          maxLength: 60, onChanged: (_) => setState(() {})),
                      const SizedBox(height: 16),
                      _label('Location'),
                      _input(_locationCtrl, 'Location', maxLength: 60),
                      const SizedBox(height: 16),
                      _label('Description'),
                      _descriptionField(),
                      const SizedBox(height: 20),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _canSave ? _save : null,
                        child: Opacity(
                          opacity: _canSave ? 1 : 0.5,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_saving ? 'Saving…' : 'Save',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                      if (widget.canDelete) ...[
                        const SizedBox(height: 24),
                        Container(height: 1, color: const Color(0xFFEEEDE9)),
                        const SizedBox(height: 20),
                        const Text('Danger zone',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _danger)),
                        const SizedBox(height: 2),
                        const Text(
                            'Once deleted, this organization and all its cards '
                            'cannot be recovered.',
                            style: TextStyle(fontSize: 12, color: _muted)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _delete,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_deleting)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _danger),
                                  )
                                else
                                  const Icon(Icons.delete_outline,
                                      size: 14, color: _danger),
                                const SizedBox(width: 6),
                                Text(
                                    _deleting
                                        ? 'Deleting…'
                                        : 'Delete organization',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _danger)),
                              ],
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
        ),
      ),
    );
  }

  Widget _sectionHeading(String t) => Text(t,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: _ink));

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
      );

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
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
        contentPadding: contentPadding ?? const EdgeInsets.all(14),
        border: _fieldBorder(const Color(0xFFD8D8D8)),
        enabledBorder: _fieldBorder(const Color(0xFFD8D8D8)),
        focusedBorder: _fieldBorder(_ink),
      ),
    );
  }

  /// 描述输入：内嵌右下角字符计数（同 organization_create_page）。
  Widget _descriptionField() {
    return Stack(
      children: [
        _input(_descCtrl, 'Tell people about this organization...',
            maxLines: 3,
            maxLength: _descMaxLen,
            onChanged: (_) => setState(() {}),
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 30)),
        Positioned(
          right: 12,
          bottom: 10,
          child: IgnorePointer(
            child: Text('${_descCtrl.text.characters.length}/$_descMaxLen',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9E9B93))),
          ),
        ),
      ],
    );
  }

  /// 封面(401:120) + 叠加 logo 的品牌编辑器，视觉同
  /// organization_create_page._brandingEditor；此处上传成功即持久化。
  Widget _brandingEditor() {
    final name = _nameCtrl.text.trim();
    final initials = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _uploadingCover ? null : () => _pickImage(isCover: true),
                child: AspectRatio(
                  aspectRatio: 401 / 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_backgroundUrl.isNotEmpty)
                        Image.network(_backgroundUrl, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                                kDefaultOrgBanner,
                                fit: BoxFit.cover))
                      else
                        Image.asset(kDefaultOrgBanner, fit: BoxFit.cover),
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
              const SizedBox(height: 36, width: double.infinity),
            ],
          ),
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
                              size: 13, color: _muted),
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
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: _ink)),
      );
}
