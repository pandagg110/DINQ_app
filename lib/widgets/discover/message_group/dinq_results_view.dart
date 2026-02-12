import 'package:flutter/material.dart';
import '../../common/asset_icon.dart';
import '../../../pages/profile/profile_page.dart';

/// 与 TSX DinqResultsView 对应，同步功能但只保留移动端样式
class DinqResultsView extends StatefulWidget {
  const DinqResultsView({
    super.key,
    required this.results,
    required this.loading,
    this.onLoadMore,
    this.hasMore = false,
  });

  final List<Map<String, dynamic>> results;
  final bool loading;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  @override
  State<DinqResultsView> createState() => _DinqResultsViewState();
}

class _DinqResultsViewState extends State<DinqResultsView> {
  static const int _initialDisplay = 5;
  bool _showAll = false;

  // 社交图标映射（使用 search 目录下的图标，与 TSX 一致）
  static String _getSocialIconPath(String type) {
    final typeLower = type.toLowerCase();
    final iconMap = <String, String>{
      'linkedin': 'icons/search/lineicons/linkedin.svg',
      'github': 'icons/search/lineicons/github.svg',
      'scholar': 'icons/search/lineicons/scholar.svg',
      'google_scholar': 'icons/search/lineicons/scholar.svg',
      'twitter': 'icons/search/lineicons/website.svg', // 如果没有 twitter 图标，使用 website
      'x': 'icons/search/lineicons/website.svg',
      'openreview': 'icons/search/lineicons/website.svg',
      'huggingface': 'icons/search/lineicons/website.svg',
    };
    return iconMap[typeLower] ?? 'icons/search/lineicons/website.svg';
  }

  static String? _extractUsernameFromProfileUrl(String? profileUrl) {
    if (profileUrl == null || profileUrl.isEmpty) return null;
    try {
      if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
        final uri = Uri.parse(profileUrl);
        final path = uri.path;
        if (path.isNotEmpty && path.startsWith('/')) {
          final parts = path.substring(1).split('/');
          return parts.isNotEmpty ? parts[0] : null;
        }
        return path.isEmpty ? null : path;
      }
      if (profileUrl.startsWith('/')) {
        final parts = profileUrl.substring(1).split('/');
        return parts.isNotEmpty ? parts[0] : null;
      }
      return profileUrl;
    } catch (e) {
      return profileUrl;
    }
  }

  void _openProfile(BuildContext context, String username) {
    Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => ProfilePage(username: username, showAppBar: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state - 移动端单栏样式
    if (widget.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部：头像 + 名字
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // 下方内容
                    const SizedBox(height: 12),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // 标签
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          height: 20,
                          width: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Empty state
    if (widget.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No DINQ users found. Try different keywords.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final displayedResults = _showAll
        ? widget.results
        : widget.results.take(_initialDisplay).toList();
    final hasHiddenResults =
        widget.results.length > _initialDisplay && !_showAll;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            'Found ${widget.results.length} DINQ Fellows. Visit their DINQ Card for more.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          // 结果列表 - 移动端单栏
          Column(
            children: displayedResults.map((result) {
              return _buildUserCard(result);
            }).toList(),
          ),
          // Show more 按钮 - 移动端样式
          if (hasHiddenResults)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Show more', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          // Load more (API) 按钮
          if (widget.hasMore && _showAll && widget.onLoadMore != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onLoadMore,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Load more results',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> result) {
    final name = result['name'] as String? ?? 'Unknown';
    // TSX 使用 avatar_url，需要同步
    final imageUrl = result['avatar_url'] as String?;
    final fullPosition = result['full_position'] as String?;
    final fullDegree = result['full_degree'] as String?;
    final tags = (result['tags'] as List<dynamic>?) ?? [];
    final location = result['location'] as String?;
    final socialLinks = (result['social_links'] as List<dynamic>?) ?? [];
    final profileUrl = result['profile_url'] as String?;
    final verificationStatus =
        result['verification_status'] as Map<String, dynamic>?;

    // 打印图片路径用于调试
    debugPrint('DinqResultsView - result keys: ${result.keys.toList()}');
    debugPrint('DinqResultsView - avatar_url: ${result['avatar_url']}');
    debugPrint('DinqResultsView - image_url: ${result['image_url']}');
    if (imageUrl != null && imageUrl.isNotEmpty) {
      debugPrint('DinqResultsView - Image URL: $imageUrl');
    } else {
      debugPrint('DinqResultsView - Image URL is null or empty');
    }

    // 计算验证数量
    int verifiedCount = 0;
    if (verificationStatus != null) {
      if (verificationStatus['career']?['verified'] == true) verifiedCount++;
      if (verificationStatus['education']?['verified'] == true) verifiedCount++;
      if (verificationStatus['social']?['verified'] == true) verifiedCount++;
    }

    final username = _extractUsernameFromProfileUrl(profileUrl);

    return InkWell(
      onTap: username != null
          ? () => _openProfile(context, username)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部区域：头像 + 姓名 + 按钮
                Row(
                  children: [
                    // 头像
                    GestureDetector(
                      onTap: username != null
                          ? () => _openProfile(context, username)
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                    'DinqResultsView - Image load error: $error',
                                  );
                                  debugPrint(
                                    'DinqResultsView - Image URL: $imageUrl',
                                  );
                                  return const Icon(Icons.person, size: 40);
                                },
                              )
                            : const Icon(Icons.person, size: 40),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 名字 + 验证徽章
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: username != null
                                  ? () => _openProfile(context, username)
                                  : null,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF171717),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (verifiedCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: verifiedCount == 1
                                    ? const Color(0xFFE3F2FD)
                                    : verifiedCount == 2
                                    ? const Color(0xFFF3E5F5)
                                    : const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 10,
                                    color: verifiedCount == 1
                                        ? const Color(0xFF1976D2)
                                        : verifiedCount == 2
                                        ? const Color(0xFF7B1FA2)
                                        : const Color(0xFFF9A825),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$verifiedCount',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: verifiedCount == 1
                                          ? const Color(0xFF1976D2)
                                          : verifiedCount == 2
                                          ? const Color(0xFF7B1FA2)
                                          : const Color(0xFFF9A825),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            SizedBox(width: 12),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Color(0xFFE5E7EB),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Chat 按钮 + DINQ Card 按钮
                    SizedBox(width: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                            ),
                            onPressed: () {
                              // TODO: 开始聊天
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            icon: const Icon(Icons.open_in_new, size: 16),
                            onPressed: username != null
                                ? () => _openProfile(context, username)
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // 职位和学历
                const SizedBox(height: 12),
                if (fullPosition != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.work_outline,
                        size: 14,
                        color: Color(0xFF303030),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fullPosition,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF303030),
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (fullDegree != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 14,
                        color: Color(0xFF7C7C7C),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fullDegree,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C7C7C),
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                // 标签
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      ...tags.take(3).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final tag = entry.value.toString();
                        final colors = [
                          {
                            'bg': const Color(0xFFF5D97A),
                            'text': const Color(0xFF5E4A1E),
                          },
                          {
                            'bg': const Color(0xFFF5C4C4),
                            'text': const Color(0xFF7A4A4A),
                          },
                          {
                            'bg': const Color(0xFFC8E6A0),
                            'text': const Color(0xFF3D5E3D),
                          },
                        ];
                        final color = colors[index % colors.length];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color['bg']!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: color['text'],
                            ),
                          ),
                        );
                      }),
                      if (tags.length > 3)
                        Text(
                          '+${tags.length - 3}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 底部区域：Location + 社媒链接
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Location
                if (location != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // 社媒链接
                Row(
                  children:
                      socialLinks.take(3).toList().map((link) {
                        final linkMap = link as Map<String, dynamic>;
                        final linkType = linkMap['type'] as String? ?? '';
                        final iconPath = _getSocialIconPath(linkType);
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              icon: Opacity(
                                opacity: 0.6,
                                child: AssetIcon(
                                  asset: iconPath,
                                  size: 14,
                                ),
                              ),
                              onPressed: () {
                                final url = linkMap['url'] as String?;
                                if (url != null) {
                                  // TODO: 打开链接
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      }).toList()..addAll([
                        if (socialLinks.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '+${socialLinks.length - 3}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
