import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../common/asset_icon.dart';
import 'factory/card_registry.dart';
import 'factory/card_definition.dart';
import 'factory/definitions/index.dart';
import 'package:flutter_portal/flutter_portal.dart';

class CardRenderer extends StatefulWidget {
  const CardRenderer({super.key, required this.card, this.editable = false});

  final CardItem card;
  final bool editable;

  @override
  State<CardRenderer> createState() => _CardRendererState();
}

class _CardRendererState extends State<CardRenderer> {
  bool _hasPrintedJson = false;
  bool _isDrag = false;
  Timer? _dragEndTimer; // 用于跟踪延迟任务，防止连续点击导致状态异常

  @override
  void initState() {
    super.initState();
    _printCardJson();
  }

  @override
  void dispose() {
    _dragEndTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CardRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果卡片 ID 或数据发生变化，重新打印
    if (oldWidget.card.id != widget.card.id ||
        oldWidget.card.data.type != widget.card.data.type ||
        oldWidget.card.data.status != widget.card.data.status) {
      _hasPrintedJson = false;
      _printCardJson();
    }
  }

  /// 获取跳转 URL
  String? _getJumpUrl() {
    switch (widget.card.data.type.toUpperCase()) {
      case 'IMAGE':
        return widget.card.data.metadata['link']?.toString();
      default:
        return widget.card.data.metadata['url']?.toString() ??
            widget.card.data.metadata['link']?.toString();
    }
  }

  /// 打印卡片 JSON 信息用于调试
  void _printCardJson() {
    if (_hasPrintedJson) return;
    _hasPrintedJson = true;

    try {
      final jsonMap = widget.card.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final cardState = cardStore.cardStates[widget.card.id];
    // 只有在 cardState 明确设置为 loading 时才显示加载状态
    // 如果 status 是 PROCESSING 且 cardState.loading 为 true，才显示加载状态
    final isLoading = cardState?.loading ?? false;
    // 如果 status 是 PROCESSING 但没有 cardState，可能是数据源类型，显示加载
    final isProcessing =
        widget.card.data.status == 'PROCESSING' &&
        widget.card.data.type.toLowerCase() == 'datasource';
    final showLoading = isLoading || isProcessing;
    final isFailed = !showLoading && widget.card.data.status == 'FAILED';
    final viewMode = cardStore.viewMode;
    final jumpUrl = _getJumpUrl();

    // 检查卡片是否被选中
    final isSelected =
        widget.editable && cardStore.isCardSelected(widget.card.id);

    // 根据选中状态设置边框样式
    final borderColor = isSelected
        ? const Color(0xFF3B82F6) // 蓝色高亮
        : const Color(0xFFE5E7EB); // 默认灰色
    final borderWidth = isSelected ? 2.0 : 1.0;

    // 卡片内容
    final cardContent = Container(
      width: double.infinity,
      height:widget.card.data.type.toUpperCase() == 'TITLE' ? 100 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF3B82F6).withOpacity(0.2) // 选中时蓝色阴影
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 主要内容 - 只有在加载状态时才隐藏
          if (!isLoading)
            Positioned.fill(
              child: _buildContent(context, viewMode, isSelected),
            ),

          // 加载状态
          if (showLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing with AI...',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 失败状态
          if (isFailed)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Oops!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The card didn\'t go through...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (widget.editable) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            cardStore.regenerateCard(cardId: widget.card.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF171717),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Listener(
      onPointerUp: (event) {
        _dragEndTimer?.cancel();

        // 延迟一下，确保不是拖拽过程中的短暂抬起
        _dragEndTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _isDrag = false;
            });
          }
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 卡片主体内容
          Column(
            mainAxisSize: widget.card.data.type.toUpperCase() == 'TITLE'
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              // 根据卡片类型决定是否使用 Expanded
              widget.card.data.type.toUpperCase() == 'TITLE'
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTapUp: (details) {
                          setState(() {
                            _isDrag = false;
                          });
                        },
                        onTap: () {
                          // 在编辑模式下，点击卡片切换选中状态
                          if (widget.editable) {
                            cardStore.toggleCardSelection(widget.card.id);
                          } else {
                            // 非编辑模式下，点击跳转链接
                            if (jumpUrl != null && jumpUrl.isNotEmpty) {
                              launchUrl(
                                Uri.parse(jumpUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          }
                        },
                        child: cardContent,
                      ),
                    )
                  : Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTapUp: (details) {
                            setState(() {
                              _isDrag = false;
                            });
                          },
                          onTap: () {
                            // 在编辑模式下，点击卡片切换选中状态
                            if (widget.editable) {
                              cardStore.toggleCardSelection(widget.card.id);
                            } else {
                              // 非编辑模式下，点击跳转链接
                              if (jumpUrl != null && jumpUrl.isNotEmpty) {
                                launchUrl(
                                  Uri.parse(jumpUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          child: cardContent,
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),

          // 编辑模式下的按钮 - 放在 Stack 外层，避免被 ClipRRect 裁剪
          if (widget.editable && isSelected) ...[
            _isDrag
                ? const SizedBox.shrink()
                : Positioned(
                    top: -1,
                    left: -1,
                    child: PortalTarget(
                      visible: true,
                      portalFollower: Material(
                        color: Colors.transparent, // 添加 Material widget
                        child: Transform.translate(
                          offset: const Offset(0, 0), // 偏移到卡片外部
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              debugPrint('删除按钮被点击');
                              cardStore.removeCard(widget.card.id);
                            },
                            child: Image.asset(
                              'assets/icons/delete-card-btn.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      anchor: const Aligned(
                        follower: Alignment.center,
                        target: Alignment.center,
                      ),

                      // offset: Offset(-20, -20),
                      child: const SizedBox(width: 1, height: 1),
                    ),
                  ),
            _isDrag
                ? const SizedBox.shrink()
                : Positioned(
                    top: -1,
                    right: -1,
                    child: PortalTarget(
                      visible: true,
                      portalFollower: Material(
                        color: Colors.transparent, // 添加 Material widget
                        child: Transform.translate(
                          offset: const Offset(0, 0), // 偏移到卡片外部
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              debugPrint('编辑按钮被点击');
                              // cardStore.removeCard(widget.card.id);
                            },
                            child: Image.asset(
                              'assets/icons/edit.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      anchor: const Aligned(
                        follower: Alignment.center,
                        target: Alignment.center,
                      ),

                      // offset: Offset(-20, -20),
                      child: const SizedBox(width: 1, height: 1),
                    ),
                  ),

            Align(
              alignment: Alignment.bottomCenter,
              child: _buildCardToolbar(context, cardStore, viewMode),
            ),
            //   // 工具栏 - 底部居中，选中时显示
          ],
        ],
      ),
    );
  }

  Widget _buildCardToolbar(
    BuildContext context,
    CardStore cardStore,
    ViewMode viewMode,
  ) {
    final registry = CardRegistry();
    final definition = registry.getDefinition(widget.card.data.type);

    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 可以在这里添加更多工具栏按钮
          // 例如：编辑、复制、设置等
          if (definition != null)
            GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTapDown: (details) {
                _dragEndTimer?.cancel();
                setState(() {
                  _isDrag = true;
                });
              },
              onTapUp: (details) {
                setState(() {
                  _isDrag = false;
                });
              },
              child: Image.asset(
                'assets/icons/move.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ViewMode viewMode,
    bool isSelected,
  ) {
    final type = widget.card.data.type.toUpperCase();
    final size = viewMode == ViewMode.mobile
        ? widget.card.layout.mobile.size
        : widget.card.layout.desktop.size;
    debugPrint('typetypetype: $type');
    return _buildCardByType(
      type,
      size,
      viewMode,
      isSelected && !_isDrag,
      context,
    );
  }

  Widget _buildCardByType(
    String type,
    String size,
    ViewMode viewMode,
    bool isSelected,
    BuildContext context,
  ) {
    final registry = CardRegistry();
    final cardStore = context.read<CardStore>();

    // 处理 datasource 类型（小写） - 显示加载状态
    if (type == 'DATASOURCE' || type == 'datasource') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    // 从注册表获取卡片定义
    final definition = registry.getDefinition(type);
    if (definition != null) {
      // 在渲染前先适配卡片数据
      final adaptedCard = registry.adapt(widget.card, viewMode);
      // 使用注册表中的定义来渲染
      return definition.render(
        CardRenderParams(
          card: adaptedCard,
          size: size,
          editable: false,
          isSelected: isSelected,
          onUpdate: (data) {
            // 更新卡片数据
            final updatedData = CardData(
              id: widget.card.data.id,
              type: widget.card.data.type,
              title: widget.card.data.title,
              description: widget.card.data.description,
              metadata: data,
              status: widget.card.data.status,
            );
            cardStore.updateCardData(widget.card.id, updatedData);
          },
        ),
      );
    }

    // 如果没有找到定义，使用默认渲染（向后兼容）
    return _buildDefaultCard();
  }

  Widget _buildLinkCard() {
    final title = widget.card.data.metadata['title']?.toString() ?? 'Link';
    final url = widget.card.data.metadata['url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/link-image.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            url,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCard() {
    // 尝试从 metadata 中获取更多信息
    final displayTitle =
        widget.card.data.metadata['title']?.toString() ??
        widget.card.data.title;
    final displayDescription =
        widget.card.data.metadata['description']?.toString() ??
        widget.card.data.description;

    // 如果 metadata 中有 url，尝试显示为链接卡片
    final url = widget.card.data.metadata['url']?.toString() ?? '';
    if (url.isNotEmpty && displayTitle.isEmpty) {
      return _buildLinkCard();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (displayTitle.isNotEmpty)
            Text(
              displayTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          if (displayDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              displayDescription,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ],
          if (displayTitle.isEmpty && displayDescription.isEmpty) ...[
            Text(
              widget.card.data.type,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.card.data.metadata.isEmpty
                  ? 'No content available'
                  : 'Type: ${widget.card.data.type}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
