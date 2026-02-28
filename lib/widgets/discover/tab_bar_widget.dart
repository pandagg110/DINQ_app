import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';

const double normalTabUnit = 68.0; // 64px + 4px gap

/// 仅允许 http/https，避免 file:/// 导致 "No host specified in URI"
bool _isValidHttpUrl(String? s) {
  if (s == null || s.trim().isEmpty) return false;
  final lower = s.trim().toLowerCase();
  if (lower.startsWith('file:')) return false;
  return lower.startsWith('http://') || lower.startsWith('https://');
}

class TabBarWidget extends StatefulWidget {
  const TabBarWidget({super.key, this.displayTabs});

  /// 若传入则用此列表渲染（用于移动端按姓名去重），否则用 store.openTabs
  final List<SearchTabData>? displayTabs;

  @override
  State<TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> {
  bool _useMiniTabs = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchStore>(
      builder: (context, searchStore, _) {
        final openTabs = widget.displayTabs ?? searchStore.openTabs;
        final activeTabId = searchStore.activeTabId;
        final isSearching = searchStore.isSearching;

        if (openTabs.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedWidth) {
              return const SizedBox.shrink();
            }
            
            final availableWidth = constraints.maxWidth - 8;
            final normalTabsWidth = openTabs.length * normalTabUnit - 4;
            final shouldUseMini = normalTabsWidth > availableWidth;

            if (shouldUseMini != _useMiniTabs) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _useMiniTabs = shouldUseMini;
                  });
                }
              });
            }

            return Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                children: openTabs.map((tab) {
                  final candidate = tab.candidate;
                  final isActive = tab.id == activeTabId;
                  final isAnyLoading = tab.isLoading || tab.enrichLoading || tab.networkLoading;
                  final hasAnyComplete = tab.profile != null || tab.network != null;

                  if (_useMiniTabs) {
                    // 迷你标签模式
                    return _buildMiniTab(
                      context,
                      tab,
                      candidate,
                      isActive,
                      isAnyLoading,
                      hasAnyComplete,
                      isSearching,
                      searchStore,
                    );
                  } else {
                    // 普通标签模式
                    return _buildNormalTab(
                      context,
                      tab,
                      candidate,
                      isActive,
                      isAnyLoading,
                      hasAnyComplete,
                      isSearching,
                      searchStore,
                    );
                  }
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniTab(
    BuildContext context,
    SearchTabData tab,
    Map<String, dynamic> candidate,
    bool isActive,
    bool isAnyLoading,
    bool hasAnyComplete,
    bool isSearching,
    SearchStore searchStore,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isActive) {
            searchStore.closeTab(tab.id);
          } else {
            searchStore.setActiveTab(tab.id);
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 30,
            maxWidth: 64,
          ),
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isActive
              ? const Icon(Icons.close, size: 12, color: Colors.white)
              : _buildTabAvatar(candidate, isAnyLoading, hasAnyComplete, isSearching),
        ),
      ),
    );
  }

  Widget _buildNormalTab(
    BuildContext context,
    SearchTabData tab,
    Map<String, dynamic> candidate,
    bool isActive,
    bool isAnyLoading,
    bool hasAnyComplete,
    bool isSearching,
    SearchStore searchStore,
  ) {
    final profileDone = tab.profile != null;
    final networkDone = tab.network != null;
    final completedCount = (profileDone ? 1 : 0) + (networkDone ? 1 : 0);
    final hasStatus = isAnyLoading || completedCount > 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => searchStore.setActiveTab(tab.id),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 头像
              _buildTabAvatar(candidate, isAnyLoading, hasAnyComplete, isSearching),
              const SizedBox(width: 3),
              // 名字
              Expanded(
                child: Text(
                  candidate['name']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              // loading 时优先显示 loading，选中且非 loading 时显示关闭
              SizedBox(
                width: 20,
                height: 20,
                child: (isActive && !isAnyLoading)
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 12,
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        onPressed: () => searchStore.closeTab(tab.id),
                      )
                    : (hasStatus
                        ? _buildStatusIcon(isAnyLoading, completedCount, isActive)
                        : IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 12,
                            icon: const Icon(Icons.close),
                            color: isActive ? Colors.white : const Color(0xFF6B7280),
                            onPressed: () => searchStore.closeTab(tab.id),
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabAvatar(
    Map<String, dynamic> candidate,
    bool isAnyLoading,
    bool hasAnyComplete,
    bool isSearching,
  ) {
    final imageUrl = candidate['image_url']?.toString();
    final size = 20.0;

    Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE5E5E5),
      backgroundImage: _isValidHttpUrl(imageUrl) ? NetworkImage(imageUrl!) : null,
      child: !_isValidHttpUrl(imageUrl)
          ? const Icon(Icons.person, size: 12, color: Color(0xFF9CA3AF))
          : null,
    );

    if (isAnyLoading) {
      return Stack(
        children: [
          avatar,
          Positioned.fill(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF6B7280).withOpacity(0.7),
              ),
            ),
          ),
        ],
      );
    }

    if (hasAnyComplete) {
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981), width: 1),
            ),
            child: avatar,
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildStatusIcon(bool isAnyLoading, int completedCount, bool isActive) {
    if (isAnyLoading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isActive ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    if (completedCount == 2) {
      return Stack(
        children: [
          Positioned(
            top: -2,
            child: Icon(Icons.check, size: 14, color: const Color(0xFF10B981).withOpacity(0.7)),
          ),
          Positioned(
            top: 4,
            child: Icon(Icons.check, size: 14, color: const Color(0xFF10B981).withOpacity(0.7)),
          ),
        ],
      );
    }

    return Icon(
      Icons.check,
      size: 14,
      color: const Color(0xFF10B981).withOpacity(0.7),
    );
  }
}
