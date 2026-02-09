import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';

/// 单条消息组数据（与 TSX MessageGroup 对应，先支持 global 搜索）
class MessageGroupData {
  const MessageGroupData({
    required this.id,
    required this.userQuery,
    this.loading = true,
    this.candidates = const [],
  });

  final int id;
  final String userQuery;
  final bool loading;
  final List<Map<String, dynamic>> candidates;
}

/// 与 TSX MessageGroupView 同步：用户问题 + AI 回复（加载态/候选人列表）
class MessageGroupView extends StatelessWidget {
  const MessageGroupView({
    super.key,
    required this.group,
    this.onCandidateClick,
    this.isLatest = false,
  });

  final MessageGroupData group;
  final void Function(List<Map<String, dynamic>> candidates, int index)? onCandidateClick;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 用户问题 - 靠右对齐（与 TSX 一致）
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              group.userQuery,
              style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
        // AI 回复区域
        _buildAiReply(context),
      ],
    );
  }

  Widget _buildAiReply(BuildContext context) {
    if (group.loading) {
      return Padding(
        padding: const EdgeInsets.only(left: 0, bottom: 16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '正在搜索…',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    if (group.candidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          '暂无匹配结果',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${group.candidates.length} 位候选人',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.candidates.asMap().entries.map((e) {
              final c = e.value;
              final name = c['name'] as String? ?? 'Unknown';
              final imageUrl = c['image_url'] as String?;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (onCandidateClick != null) {
                      onCandidateClick!(group.candidates, e.key);
                    } else {
                      final store = context.read<SearchStore>();
                      store.setTabsFromCandidates(group.candidates);
                      if (e.key < store.openTabs.length) {
                        store.setActiveTab(store.openTabs[e.key].id);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              imageUrl,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28),
                            ),
                          )
                        else
                          const CircleAvatar(
                            radius: 14,
                            child: Icon(Icons.person, size: 20),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
