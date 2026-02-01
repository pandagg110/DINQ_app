/**
 * NetworkEditForm - Flutter 迁移自 Web NetworkEditModal.tsx
 * ACHIEVEMENT_NETWORK 卡片编辑表单：connections 增删改、头像上传、机构 logo 刷新
 */

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../models/card_models.dart';
import '../../../services/datasource_service.dart';
import '../../../services/tool_service.dart';
import '../../../services/upload_service.dart';
import '../../../stores/card_store.dart';
import '../../../utils/asset_path.dart';
import '../../../utils/toast_util.dart';

/// Network 连接项（对应 Web NetworkConnection）
class NetworkConnection {
  NetworkConnection({
    this.name = '',
    this.avatarUrl = '',
    this.institutionLogoUrl,
    this.affiliation = '',
    this.position = '',
    this.relationshipType = '',
    this.score = 0,
    this.reason = '',
  });

  String name;
  String avatarUrl;
  String? institutionLogoUrl;
  String affiliation;
  String position;
  String relationshipType;
  int score;
  String reason;

  /// API 格式（AchievementNetworkPerson）
  Map<String, dynamic> toApiJson() => {
    'name': name,
    'sources': <String>[],
    'avatar_url': avatarUrl,
    'affiliation': affiliation,
    'position': position,
    'final_score': score,
    'relationship_type': relationshipType,
    'institution_logo_url': institutionLogoUrl,
    'reason_for_inclusion': reason,
    'representative_collaboration': null,
  };

  static NetworkConnection fromMap(Map<String, dynamic> m) {
    return NetworkConnection(
      name: (m['name'] ?? '').toString(),
      avatarUrl: (m['avatarUrl'] ?? m['avatar_url'] ?? '').toString(),
      institutionLogoUrl: m['institution_logo_url']?.toString(),
      affiliation: (m['affiliation'] ?? '').toString(),
      position: (m['position'] ?? '').toString(),
      relationshipType: (m['relationshipType'] ?? m['relationship_type'] ?? '')
          .toString(),
      score: (m['score'] ?? m['final_score'] ?? 0) is int
          ? (m['score'] ?? m['final_score'] ?? 0) as int
          : int.tryParse((m['score'] ?? m['final_score'] ?? 0).toString()) ?? 0,
      reason: (m['reason'] ?? m['reason_for_inclusion'] ?? '').toString(),
    );
  }
}

/// Network 编辑表单（含 save 逻辑），供 EditCardDialog 使用
class NetworkEditFormWithSave extends StatelessWidget {
  const NetworkEditFormWithSave({
    super.key,
    required this.card,
    required this.onSaveReady,
  });

  final CardItem card;
  final void Function(Future<void> Function() save) onSaveReady;

  @override
  Widget build(BuildContext context) {
    return NetworkEditForm(
      card: card,
      hideHeader: true,
      onSaveReady: onSaveReady,
      onSaved: () => Navigator.of(context).pop(),
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

/// Network 编辑表单，对应 Web NetworkEditModal
class NetworkEditForm extends StatefulWidget {
  const NetworkEditForm({
    super.key,
    required this.card,
    required this.onSaved,
    required this.onCancel,
    this.asBottomSheet = false,
    this.hideHeader = false,
    this.onSaveReady,
  });

  final CardItem card;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  /// 作为底部弹框内容，不使用 Dialog 包裹
  final bool asBottomSheet;

  /// 隐藏头部（由父级统一提供 header + Save）
  final bool hideHeader;

  /// 父级调用时注册 save 回调
  final void Function(Future<void> Function() save)? onSaveReady;

  @override
  State<NetworkEditForm> createState() => _NetworkEditFormState();
}

class _NetworkEditFormState extends State<NetworkEditForm> {
  late List<NetworkConnection> _connections;
  int _activeIndex = 0;
  bool _isUploadingAvatar = false;
  bool _isRefreshingLogo = false;
  final _toolService = ToolService();
  final _uploadService = UploadService();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _positionController = TextEditingController();
  final _affiliationController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConnections();
    _syncControllers();
    widget.onSaveReady?.call(() => _handleSave());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _positionController.dispose();
    _affiliationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    if (_connections.isEmpty) return;
    final c = _current;
    if (_nameController.text != c.name) _nameController.text = c.name;
    if (_relationshipController.text != c.relationshipType)
      _relationshipController.text = c.relationshipType;
    if (_positionController.text != c.position)
      _positionController.text = c.position;
    if (_affiliationController.text != c.affiliation)
      _affiliationController.text = c.affiliation;
    if (_reasonController.text != c.reason) _reasonController.text = c.reason;
  }

  void _loadConnections() {
    final list =
        widget.card.data.metadata['connections'] as List<dynamic>? ?? [];
    _connections = list
        .whereType<Map>()
        .map(
          (e) => NetworkConnection.fromMap(Map<String, dynamic>.from(e)),
        )
        .toList();
    if (_connections.isEmpty) {
      _connections = [
        NetworkConnection(avatarUrl: assetPath('images/default-avatar.svg')),
      ];
    }
    _activeIndex = _activeIndex.clamp(0, _connections.length - 1);
    _syncControllers();
  }

  NetworkConnection get _current => _connections[_activeIndex];

  void _updateField(String field, dynamic value) {
    setState(() {
      switch (field) {
        case 'name':
          _current.name = value?.toString() ?? '';
          break;
        case 'avatarUrl':
          _current.avatarUrl = value?.toString() ?? '';
          break;
        case 'institution_logo_url':
          _current.institutionLogoUrl = value?.toString();
          break;
        case 'affiliation':
          _current.affiliation = value?.toString() ?? '';
          break;
        case 'position':
          _current.position = value?.toString() ?? '';
          break;
        case 'relationshipType':
          _current.relationshipType = value?.toString() ?? '';
          break;
        case 'reason':
          _current.reason = value?.toString() ?? '';
          break;
      }
    });
  }

  Future<void> _handleAvatarUpload() async {
    if (_isUploadingAvatar) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      );
      if (result == null || result.files.single.bytes == null) return;

      setState(() => _isUploadingAvatar = true);
      final file = result.files.single;
      final ext = file.extension ?? 'jpg';
      final contentType = ext == 'png'
          ? 'image/png'
          : ext == 'jpg' || ext == 'jpeg'
          ? 'image/jpeg'
          : ext == 'gif'
          ? 'image/gif'
          : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

      final url = await _uploadService.uploadFile(
        bytes: file.bytes!,
        filename: file.name,
        contentType: contentType,
      );
      _updateField('avatarUrl', url);
      if (mounted)
        ToastUtil.showSuccess(
          context: context,
          title: 'Uploaded',
          description: '',
        );
    } catch (e) {
      if (mounted)
        ToastUtil.showError(
          context: context,
          title: 'Upload failed',
          description: e.toString(),
        );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleRefreshLogo() async {
    final affiliation = _current.affiliation.trim();
    if (affiliation.isEmpty) return;
    try {
      setState(() => _isRefreshingLogo = true);
      final url = await _toolService.getInstitutionLogo(affiliation);
      if (url != null) {
        _updateField('institution_logo_url', url);
        if (mounted)
          ToastUtil.showSuccess(
            context: context,
            title: 'Logo updated',
            description: '',
          );
      } else {
        _updateField('institution_logo_url', null);
      }
    } catch (e) {
      _updateField('institution_logo_url', null);
      if (mounted)
        ToastUtil.showError(
          context: context,
          title: 'Failed to fetch logo',
          description: e.toString(),
        );
    } finally {
      if (mounted) setState(() => _isRefreshingLogo = false);
    }
  }

  void _handleDeletePerson() {
    setState(() {
      _connections.removeAt(_activeIndex);
      if (_connections.isEmpty) {
        widget.onCancel();
        return;
      }
      if (_activeIndex >= _connections.length) {
        _activeIndex = _connections.length - 1;
      }
      _syncControllers();
    });
  }

  void _handleAddPerson() {
    setState(() {
      _connections.add(
        NetworkConnection(avatarUrl: assetPath('images/default-avatar.svg')),
      );
      _activeIndex = _connections.length - 1;
      _syncControllers();
    });
  }

  /// 保存逻辑与 NetworkEditModal.tsx handleSave 同步：
  /// 1. 将 connections 转为 AchievementNetworkPerson[] (toApiJson)
  /// 2. 调用 updateAchievementNetwork API
  /// 3. 更新本地 metadata.connections（UI 格式）
  /// 4. onSaved() 关闭弹框
  Future<void> _handleSave() async {
    if (_isUploadingAvatar || _isRefreshingLogo) return;
    try {
      // 1. Convert to API format (AchievementNetworkPerson)
      final rawData = _connections.map((c) => c.toApiJson()).toList();
      print('rawData: $rawData');
      print('datasource_id: ${widget.card.data.id}');
      await DatasourceService().updateAchievementNetwork({
        'datasource_id': widget.card.data.id,
        'data': rawData,
      });

      // 2. Update local state with UI format (onSave callback 等价)
      final cardStore = context.read<CardStore>();
      final newMetadata = Map<String, dynamic>.from(widget.card.data.metadata);
      newMetadata['connections'] = _connections
          .map(
            (c) => {
              'name': c.name,
              'avatarUrl': c.avatarUrl,
              'avatar_url': c.avatarUrl,
              'institution_logo_url': c.institutionLogoUrl,
              'affiliation': c.affiliation,
              'position': c.position,
              'relationshipType': c.relationshipType,
              'relationship_type': c.relationshipType,
              'score': c.score,
              'reason': c.reason,
              'reason_for_inclusion': c.reason,
            },
          )
          .toList();
      cardStore.updateCardData(
        widget.card.id,
        CardData(
          id: widget.card.data.id,
          type: widget.card.data.type,
          title: widget.card.data.title,
          description: widget.card.data.description,
          metadata: newMetadata,
          status: widget.card.data.status,
        ),
      );
      // 3. Close (onClose)
      widget.onSaved();
    } catch (e) {
      if (mounted)
        ToastUtil.showError(
          context: context,
          title: 'Save failed',
          description: e.toString(),
        );
    }
  }

  final _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF0C0C0C)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final disabled = _isUploadingAvatar || _isRefreshingLogo;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.hideHeader) _buildHeader(disabled),
        _buildTabs(),
        SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 20),
                _buildFormFields(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildFooter(disabled),
      ],
    );

    if (widget.asBottomSheet) {
      return content;
    }
    return content;
  }

  Widget _buildHeader(bool disabled) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Edit Network',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
          ),
          TextButton(
            onPressed: disabled ? null : _handleSave,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildTabs() {
    const perRow = 6;
    const gap = 8.0;

    final items = <Widget>[
      ...List.generate(_connections.length, (i) {
        final selected = _activeIndex == i;
        return GestureDetector(
          onTap: () => setState(() {
            _activeIndex = i;
            _syncControllers();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF0C0C0C)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }),
      if (_connections.length < 6)
        GestureDetector(
          onTap: _handleAddPerson,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C0C),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += perRow) {
          final rowItems = items.skip(i).take(perRow).toList();
          final count = rowItems.length;
          final itemWidth = (totalWidth - (count - 1) * gap) / count;
          rows.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: i + perRow < items.length ? gap : 0,
              ),
              child: Row(
                children: [
                  for (var j = 0; j < rowItems.length; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    SizedBox(
                      width: itemWidth,
                      child: rowItems[j],
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('* Avatar'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _handleAvatarUpload,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                  color: const Color(0xFFF9FAFB),
                ),
                child: ClipOval(
                  child: _current.avatarUrl.isNotEmpty &&
                          _current.avatarUrl.startsWith('http')
                      ? Image.network(_current.avatarUrl, fit: BoxFit.cover)
                      : SvgPicture.asset(
                          _current.avatarUrl.isNotEmpty
                              ? _current.avatarUrl
                              : assetPath('images/default-avatar.svg'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              if (_isUploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/profile/img-add-icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('* Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (v) => _updateField('name', v),
          decoration: _inputDecoration.copyWith(hintText: 'Enter Name'),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Title'),
        const SizedBox(height: 8),
        TextField(
          controller: _positionController,
          onChanged: (v) => _updateField('position', v),
          decoration: _inputDecoration.copyWith(
            hintText: 'e.g., Growth Marketer',
          ),
          style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildLabel('Relationship'),
        const SizedBox(height: 8),
        TextField(
          controller: _relationshipController,
          onChanged: (v) => _updateField('relationshipType', v),
          decoration: _inputDecoration.copyWith(
            hintText: 'e.g., Colleague, Collaborator',
          ),
          style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildLabel('Affiliation'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: _affiliationController,
                    onChanged: (v) => _updateField('affiliation', v),
                    decoration: _inputDecoration.copyWith(
                      hintText: 'Company or Organization',
                      contentPadding: EdgeInsets.only(
                        left: 16,
                        right: (_current.institutionLogoUrl != null &&
                                    _current.institutionLogoUrl!.isNotEmpty) ||
                                _isRefreshingLogo
                            ? 56
                            : 16,
                        top: 12,
                        bottom: 12,
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
                  ),
                  if (_isRefreshingLogo)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  else if (_current.institutionLogoUrl != null &&
                      _current.institutionLogoUrl!.isNotEmpty)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _current.institutionLogoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                onPressed:
                    _isRefreshingLogo || _current.affiliation.trim().isEmpty
                        ? null
                        : _handleRefreshLogo,
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(40, 40),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildLabel('Description'),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          onChanged: (v) => _updateField('reason', v),
          maxLines: 4,
          decoration: _inputDecoration.copyWith(
            hintText: 'e.g., Colleague at DINQ working as Growth Marketer',
            alignLabelWithHint: true,
          ),
          style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFooter(bool disabled) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: disabled ? null : _handleDeletePerson,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text(
                'Delete Person',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
