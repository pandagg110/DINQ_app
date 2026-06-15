import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/message_models.dart';
import '../../services/message_service.dart';
import '../../stores/messages_store.dart';

/// 聊天里的「组队招募」卡片。
/// 还原 web DINQ_client `TeamRecruitCard.tsx`：标题+状态徽章+描述、成员头像簇
/// （发起人带皇冠）、右侧上下文动作（Join / Leave / Assemble / Cancel / Delete / Chat）。
/// 数据全部来自 message.metadata，动作走 MessageService 的 team-recruit 接口，
/// 成功后用服务端返回的最新 message 调 MessagesStore.replaceMessage 刷新。
class TeamRecruitCard extends StatefulWidget {
  final Message message;
  final String currentUserId;

  const TeamRecruitCard({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  State<TeamRecruitCard> createState() => _TeamRecruitCardState();
}

class _TeamRecruitCardState extends State<TeamRecruitCard> {
  final _service = MessageService();

  // 当前进行中的动作，用于禁用按钮 + 显示 loading
  String? _pending; // join / leave / close / delete

  static const _maxAvatars = 4;
  static const _defaultAvatar =
      'https://dinq.me/images/default-avatar.png';

  Map<String, dynamic> get _meta => widget.message.metadata ?? const {};

  String get _title => (_meta['team_title'] ?? 'Team recruit').toString();
  String get _description => (_meta['team_description'] ?? '').toString();
  int get _maxMembers =>
      (_meta['team_max_members'] is num) ? (_meta['team_max_members'] as num).toInt() : 0;
  List<String> get _memberIds =>
      (_meta['team_members'] as List?)?.map((e) => e.toString()).toList() ?? const [];
  List<Map<String, dynamic>> get _membersInfo =>
      (_meta['team_members_info'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      const [];
  String get _state => (_meta['team_state'] ?? 'open').toString();
  String get _teamConvId => (_meta['team_conv_id'] ?? '').toString();

  bool get _isInitiator => widget.message.senderId == widget.currentUserId;
  bool get _hasJoined => _memberIds.contains(widget.currentUserId);
  bool get _isOpen => _state == 'open';
  bool get _canJoin => _isOpen && !_hasJoined && !_isInitiator;

  Future<void> _run(String action) async {
    if (_pending != null) return;
    setState(() => _pending = action == 'close-spawn' || action == 'close-cancel' ? 'close' : action);
    final router = GoRouter.of(context);
    try {
      final store = context.read<MessagesStore>();
      Map<String, dynamic> res;
      switch (action) {
        case 'join':
          res = await _service.joinTeamRecruit(widget.message.id);
          break;
        case 'leave':
          res = await _service.leaveTeamRecruit(widget.message.id);
          break;
        default: // close-spawn / close-cancel
          res = await _service.closeTeamRecruit(
            widget.message.id,
            spawnTeam: action == 'close-spawn',
          );
      }
      // 服务端返回 { message, spawned_conv_id }
      final updated = res['message'];
      if (updated is Map) {
        store.replaceMessage(Message.fromJson(Map<String, dynamic>.from(updated)));
      }
      final spawnedId = res['spawned_conv_id']?.toString();
      if (spawnedId != null && spawnedId.isNotEmpty) {
        router.go('/admin/inbox/$spawnedId');
      }
    } catch (e) {
      _snack('Action failed: $e');
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  Future<void> _delete() async {
    if (_pending != null || !_isInitiator) return;
    final store = context.read<MessagesStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete team'),
        content: const Text(
            'This removes the team recruit from the organization Team list and chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE24B3C))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _pending = 'delete');
    try {
      await _service.deleteTeamRecruit(widget.message.id);
      // 后端只做展示移除：本地标记 recalled，渲染层会隐藏卡片
      store.replaceMessage(
            Message(
              id: widget.message.id,
              conversationId: widget.message.conversationId,
              senderId: widget.message.senderId,
              messageType: widget.message.messageType,
              content: widget.message.content,
              metadata: widget.message.metadata,
              status: widget.message.status,
              isRecalled: true,
              replyToMessageId: widget.message.replyToMessageId,
              createdAt: widget.message.createdAt,
            ),
          );
    } catch (e) {
      _snack('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8D5CE)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.outlined_flag, size: 16, color: Color(0xFF9E9B93)),
              const SizedBox(width: 12),
              Expanded(child: _titleBlock()),
              if (_membersInfo.isNotEmpty) ...[
                const SizedBox(width: 8),
                _avatarCluster(),
              ],
              _actionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF171717)),
              ),
            ),
            const SizedBox(width: 8),
            _stateBadge(),
          ],
        ),
        if (_description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9B93)),
          ),
        ],
      ],
    );
  }

  Widget _stateBadge() {
    if (_state == 'full') {
      return _badge('Full', const Color(0xFFF4F9F0), const Color(0xFF5C8840),
          icon: Icons.check, iconSize: 12);
    }
    if (_state == 'closed') {
      return _badge('Closed', const Color(0xFFF7F6F2), const Color(0xFF9E9B93));
    }
    return _badge('${_memberIds.length} / $_maxMembers', const Color(0xFFF0F4FB),
        const Color(0xFF5E81AC));
  }

  Widget _badge(String text, Color bg, Color fg, {IconData? icon, double iconSize = 12}) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 3),
          ],
          Text(text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }

  Widget _avatarCluster() {
    final overflow = _membersInfo.length > _maxAvatars;
    final visible =
        _membersInfo.take(overflow ? _maxAvatars - 1 : _membersInfo.length).toList();
    final overflowN = _membersInfo.length - visible.length;
    const size = 28.0;

    final stack = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      stack.add(Padding(
        padding: EdgeInsets.only(left: i * (size - 8)),
        child: _avatar(visible[i], size),
      ));
    }
    if (overflowN > 0) {
      stack.add(Padding(
        padding: EdgeInsets.only(left: visible.length * (size - 8)),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EEE8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text('+$overflowN',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF6B6862))),
        ),
      ));
    }
    final width = visible.length * (size - 8) + (overflowN > 0 ? size : 8);
    return SizedBox(height: size, width: width.toDouble(), child: Stack(children: stack));
  }

  Widget _avatar(Map<String, dynamic> info, double size) {
    final url = (info['avatar_url'] ?? '').toString().trim();
    final isInitiatorSlot = info['user_id']?.toString() == widget.message.senderId;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: NetworkImage(url.isNotEmpty ? url : _defaultAvatar),
                fit: BoxFit.cover,
                onError: (_, _) {},
              ),
              color: const Color(0xFFE5E3DD),
            ),
          ),
          if (isInitiatorSlot)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: const Icon(Icons.star, size: 8, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionArea() {
    final action = _buildAction();
    if (action == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFEEEDE9))),
      ),
      child: action,
    );
  }

  Widget? _buildAction() {
    // 满员/关闭且已进子群
    if ((_state == 'full' || _state == 'closed') && _teamConvId.isNotEmpty && _hasJoined) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _linkBtn('Chat ›', const Color(0xFF5E81AC),
              () => context.go('/admin/inbox/$_teamConvId')),
          if (_isInitiator) ...[
            const SizedBox(width: 6),
            _deleteBtn(),
          ],
        ],
      );
    }
    // 发起人 + open
    if (_isInitiator && _isOpen) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_memberIds.length >= 2)
            _linkBtn('Assemble ›', const Color(0xFF171717),
                () => _run('close-spawn'),
                loading: _pending == 'close'),
          _linkBtn('Cancel', const Color(0xFF9E9B93), () => _run('close-cancel')),
          _deleteBtn(),
        ],
      );
    }
    // 已加入（非发起人）→ 可退出（移动端用显式按钮替代 web 的头像 hover）
    if (_isOpen && _hasJoined && !_isInitiator) {
      return _linkBtn('Leave', const Color(0xFF9E9B93), () => _run('leave'),
          loading: _pending == 'leave');
    }
    // open → 加入
    if (_isOpen) {
      return _linkBtn(
        'Join ›',
        _canJoin ? const Color(0xFF5E81AC) : const Color(0xFFC8C5BE),
        _canJoin ? () => _run('join') : null,
        loading: _pending == 'join',
      );
    }
    return null;
  }

  Widget _linkBtn(String label, Color color, VoidCallback? onTap, {bool loading = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (_pending != null || onTap == null) ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const SizedBox(
                  width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _deleteBtn() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pending != null ? null : _delete,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: _pending == 'delete'
            ? const SizedBox(
                width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
            : const Icon(Icons.delete_outline, size: 14, color: Color(0xFF9E9B93)),
      ),
    );
  }
}
