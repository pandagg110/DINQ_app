import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/deep_search_enrich_models.dart';
import '../../../services/connector_service.dart';
import '../../../services/message_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/search_service.dart';
import '../../../services/shortlist_service.dart';
import '../../../stores/deep_search_enrich_store.dart';
import '../../../stores/search_store.dart';
import '../../../stores/user_store.dart';
import '../../../utils/api_error.dart';
import '../../../utils/credit_feedback.dart';
import '../../../utils/top_toast_util.dart';
import '../deep_search/deep_search_results_helpers.dart';
import '../../common/asset_icon.dart';
import '../../credits/credits_exhausted_sheet.dart';
import 'enrich_contact_email_modal.dart';
import 'enrich_icons.dart';
import 'enrich_tool_log_timeline.dart';
import 'shortlist_folder_modal.dart';

// ── Colors aligned with EnrichProfileView.tsx ──────────────────────────────
abstract final class _C {
  static const textPrimary = Color(0xFF2A2826);
  static const textDark = Color(0xFF2D2B2A);
  static const textBody = Color(0xFF716E6A);
  static const textMuted = Color(0xFF9E9A94);
  static const textSecondary = Color(0xFF6B6862);
  static const textDot = Color(0xFFC5C2BC);
  static const border = Color(0xFFEAE7E0);
  static const borderLight = Color(0xFFE5E3DE);
  static const borderBtn = Color(0xFFEAEAEA);
  static const bgSkeleton = Color(0xFFF5F4F0);
  static const bgMatch = Color(0xFFFAF9F7);
  static const bgPanel = Color(0xFFFAFAF8);
  static const bgShortlist = Color(0xFFF3F1EC);
  static const bgBtnDark = Color(0xFF2D2B2A);
  static const divider = Color(0xFFF0EEEA);
  static const dotFill = Color(0xFFD6D3CD);
  static const btnShadow = Color.fromRGBO(45, 43, 42, 0.05);
}

const _sourceLineRe = r'^Source\s*\[\d+\]$';

String stripBold(String text) =>
    text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');

String parseUniversity(String raw) {
  if (!raw.startsWith('{')) return raw;
  final fields = <String>[];
  for (final key in ['name', 'degree', 'field', 'period']) {
    final re = RegExp('["\']$key["\']\\s*:\\s*(?:"([^"]*)"|\'([^\']*)\')');
    final m = re.firstMatch(raw);
    final val = m?.group(1) ?? m?.group(2);
    if (val != null && val.isNotEmpty) fields.add(val);
  }
  return fields.isNotEmpty ? fields.join(', ') : raw;
}

/// 对齐 Web `EnrichProfileView.tsx` isMaskedEmail / usableEmails。
bool isMaskedEmail(String email) {
  final local = email.split('@').first;
  return local.isNotEmpty && RegExp(r'^\*+$').hasMatch(local);
}

List<String> usableEmails(String raw) =>
    parseEmails(raw).where((e) => !isMaskedEmail(e)).toList();

const _maxRevealedEmails = 5;

/// 对齐 Web `pickDiverse`：按来源轮询取邮箱，避免单一来源占满列表。
List<String> pickDiverseEmails(Map<String, List<String>> bySource, int max) {
  final buckets = bySource.values.toList();
  final out = <String>[];
  for (var round = 0; out.length < max; round++) {
    var added = false;
    for (final bucket in buckets) {
      if (round < bucket.length) {
        out.add(bucket[round]);
        added = true;
        if (out.length >= max) break;
      }
    }
    if (!added) break;
  }
  return out;
}

String _socialLabel(String type) {
  const map = {
    'google_scholar': 'Google Scholar',
    'linkedin': 'LinkedIn',
    'github': 'GitHub',
    'openreview': 'OpenReview',
    'twitter': 'Twitter',
    'huggingface': 'Hugging Face',
  };
  return map[type] ?? type.replaceAll('_', ' ');
}

String _hostnameFromUrl(String url) {
  try {
    return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
  } catch (_) {
    return url;
  }
}

/// 对齐 Web `EnrichProfileView.tsx` renderOneLiner (96-108)。
List<InlineSpan> _renderOneLinerParts(String text, {TextStyle? base}) {
  final style = base ?? const TextStyle(fontSize: 14, color: _C.textBody);
  const marker = '**';
  final spans = <InlineSpan>[];
  var start = 0;
  while (start < text.length) {
    final open = text.indexOf(marker, start);
    if (open < 0) {
      final tail = text.substring(start);
      if (tail.isNotEmpty) {
        spans.add(TextSpan(text: tail, style: style));
      }
      break;
    }
    if (open > start) {
      spans.add(TextSpan(text: text.substring(start, open), style: style));
    }
    final close = text.indexOf(marker, open + marker.length);
    if (close < 0) {
      final tail = text.substring(open);
      if (tail.isNotEmpty) {
        spans.add(TextSpan(text: tail, style: style));
      }
      break;
    }
    final bold = text.substring(open + marker.length, close);
    if (bold.isNotEmpty) {
      spans.add(
        TextSpan(
          text: bold,
          style: style.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }
    start = close + marker.length;
  }
  return spans;
}

TextSpan _oneLinerSpan(String text, {TextStyle? base}) {
  return TextSpan(children: _renderOneLinerParts(text, base: base));
}

Widget renderOneLiner(String text, {TextStyle? style}) {
  return RichText(
    text: _oneLinerSpan(text, base: style),
    softWrap: true,
    overflow: TextOverflow.visible,
  );
}

/// 对齐 Web `<p>` 内联：badge + renderOneLiner(person.one_liner)。
Widget renderMatchContextBlock({
  required String text,
  int? matchPct,
  TextStyle? style,
}) {
  const defaultStyle = TextStyle(
    fontSize: 14,
    height: 1.625,
    color: _C.textBody,
  );
  final base = style ?? defaultStyle;
  return RichText(
    text: TextSpan(
      style: base,
      children: [
        if (matchPct != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MatchBadge(match: matchPct),
            ),
          ),
        ..._renderOneLinerParts(text, base: base),
      ],
    ),
    softWrap: true,
    overflow: TextOverflow.visible,
  );
}

/// 对齐 Web `EnrichProfileView.tsx`。
class EnrichProfileView extends StatefulWidget {
  const EnrichProfileView({
    super.key,
    required this.entry,
    this.isMobile = false,
    this.pinActionsToBottom = false,
    this.onRefresh,
    this.confidencePct,
    this.selectedRowId,
    this.shortlistMode = false,
  });

  final EnrichEntry entry;
  final bool isMobile;

  /// 移动端整页模式：操作按钮（Get email/Shortlist/私信）固定在页面底部，
  /// 其余内容自带滚动区。为 true 时本组件占满可用高度，外层不要再包滚动容器。
  final bool pinActionsToBottom;
  final Future<void> Function()? onRefresh;
  final int? confidencePct;
  final String? selectedRowId;
  final bool shortlistMode;

  @override
  State<EnrichProfileView> createState() => _EnrichProfileViewState();
}

class _EnrichProfileViewState extends State<EnrichProfileView> {
  bool _logsExpanded = false;
  bool _refreshing = false;
  EnrichStatus? _prevStatus;

  @override
  void didUpdateWidget(covariant EnrichProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final status = widget.entry.status;
    if (_prevStatus != EnrichStatus.done && status == EnrichStatus.done) {
      _logsExpanded = false;
    }
    if (status == EnrichStatus.streaming) _logsExpanded = false;
    _prevStatus = status;
  }

  Future<void> _handleRefresh() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null ||
        widget.entry.requestParams == null ||
        widget.entry.status == EnrichStatus.streaming ||
        _refreshing) {
      return;
    }
    setState(() {
      _refreshing = true;
      _logsExpanded = false;
    });
    try {
      await onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDone = entry.status == EnrichStatus.done;
    final isError = entry.status == EnrichStatus.error;
    final isStreamingStatus = entry.status == EnrichStatus.streaming;
    final isFinished = isDone || isError;
    final hasLogs =
        entry.toolLogs.isNotEmpty || (entry.errorMessage?.isNotEmpty ?? false);
    final showFullLogs = _logsExpanded;
    final canRefresh =
        widget.onRefresh != null &&
        entry.requestParams != null &&
        !isStreamingStatus &&
        !_refreshing;

    // Search 详情与 shortlist 一致：completed 后隐藏顶部 Searching 条。
    final shouldShowLogs = hasLogs && !isDone;
    final logSection = shouldShowLogs
        ? SizedBox(
            width: double.infinity,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: _C.border),
                borderRadius: BorderRadius.circular(8),
                color: _C.bgPanel,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_logsExpanded)
                    InkWell(
                      onTap: () => setState(() => _logsExpanded = true),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            if (isStreamingStatus)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: _C.textMuted,
                                ),
                              )
                            else
                              EnrichSvgIcon(
                                isError
                                    ? EnrichIcons.alertCircle
                                    : EnrichIcons.check,
                                size: 14,
                                color: isError
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF22C55E),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isError
                                    ? (entry.errorMessage ?? 'Search failed')
                                    : isFinished
                                    ? 'Search completed'
                                    : _latestLogMessage(entry),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isError
                                      ? const Color(0xFFDC2626)
                                      : _C.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isFinished)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: canRefresh ? _handleRefresh : null,
                                icon: _refreshing
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const EnrichSvgIcon(
                                        EnrichIcons.refresh,
                                        size: 14,
                                      ),
                              ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () =>
                                  setState(() => _logsExpanded = true),
                              icon: const EnrichSvgIcon(
                                EnrichIcons.chevronDown,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showFullLogs)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            12,
                            isFinished ? 68 : 40,
                            12,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: EnrichToolLogTimeline(
                                toolLogs: entry.toolLogs,
                                errorMessage: entry.errorMessage,
                                hasMore: isDone,
                              ),
                            ),
                          ),
                        ),
                        if (isFinished) ...[
                          Positioned(
                            top: 4,
                            right: 32,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: canRefresh ? _handleRefresh : null,
                              icon: const EnrichSvgIcon(
                                EnrichIcons.refresh,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _logsExpanded = false),
                            icon: const EnrichSvgIcon(
                              EnrichIcons.chevronUp,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    final pinActions = widget.isMobile && widget.pinActionsToBottom;
    final profile = _ProfileSection(
      entry: entry,
      isMobile: widget.isMobile,
      confidencePct: widget.confidencePct,
      selectedRowId: widget.selectedRowId,
      pinActions: pinActions,
      pinnedHeader: pinActions && shouldShowLogs ? logSection : null,
      shortlistMode: widget.shortlistMode,
    );

    if (pinActions) {
      // 滚动区 + 底部按钮栏都由 _ProfileSection 负责
      return profile;
    }

    if (widget.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          logSection,
          if (shouldShowLogs) const SizedBox(height: 16),
          profile,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: profile,
    );
  }

  String _latestLogMessage(EnrichEntry entry) {
    if (entry.toolLogs.isEmpty) return 'Searching with Dinq Search AI';
    final log = entry.toolLogs.last;
    return log.message.isNotEmpty ? log.message : log.tool;
  }
}

class _ProfileSection extends StatefulWidget {
  const _ProfileSection({
    required this.entry,
    required this.isMobile,
    this.confidencePct,
    this.selectedRowId,
    this.pinActions = false,
    this.pinnedHeader,
    this.shortlistMode = false,
  });

  final EnrichEntry entry;
  final bool isMobile;
  final int? confidencePct;
  final String? selectedRowId;

  /// 操作按钮固定底部：内容区自带滚动，按钮栏常驻页面底部
  final bool pinActions;

  /// pinActions 模式下插入滚动区顶部的组件（如工具日志区）
  final Widget? pinnedHeader;
  final bool shortlistMode;

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  final _searchService = SearchService();
  final _shortlistService = ShortlistService();
  final _connectorService = ConnectorService();
  final _profileService = ProfileService();
  final _messageService = MessageService();
  final Map<String, String> _favoriteMap = {};
  bool _emailConnected = false;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadEmailConnection();
  }

  Future<void> _loadFavorites() async {
    try {
      final items = await _shortlistService.listFavorites();
      if (!mounted) return;
      final map = <String, String>{};
      for (final item in items) {
        final rowId = item.field['row_id']?.toString();
        if (rowId != null && rowId.isNotEmpty) map[rowId] = item.id;
      }
      setState(() => _favoriteMap.addAll(map));
    } catch (_) {}
  }

  Future<void> _loadEmailConnection() async {
    try {
      final accounts = await _connectorService.getAccounts();
      if (!mounted) return;
      setState(() {
        _emailConnected = accounts.any(
          (a) =>
              a.status == 'active' &&
              (a.platform == 'gmail' ||
                  a.platform == 'microsoft' ||
                  a.platform == 'imap'),
        );
      });
    } catch (_) {}
  }

  Future<void> _handleRevealEmail() async {
    final person = widget.entry.person;
    final rowId = widget.selectedRowId;
    if (person == null || rowId == null) return;
    final store = context.read<DeepSearchEnrichStore>();
    final entry = store.entryFor(rowId);
    if (entry != null &&
        entry.emailRevealAttempted &&
        usableEmails(entry.revealedEmail ?? '').isNotEmpty) {
      return;
    }
    store.startEmailReveal(rowId);
    try {
      final sessionId = context.read<SearchStore>().deepSearchSessionId ?? '';
      final bySource = <String, List<String>>{};
      final seen = <String>{};

      void addEmails(String source, List<dynamic>? emails) {
        for (final raw in emails ?? const <dynamic>[]) {
          final email = raw.toString();
          if (email.isEmpty || isMaskedEmail(email) || seen.contains(email)) {
            continue;
          }
          seen.add(email);
          bySource.putIfAbsent(source, () => []).add(email);
        }
      }

      await for (final event in _searchService.profileEmailStream(
        name: stripBold(person.name),
        sessionId: sessionId,
        company: person.company != null ? stripBold(person.company!) : null,
        personalHomepage: person.personalHomepage,
        sources: person.socialLinks
            ?.map((l) => {'url': l.url, 'description': l.type})
            .toList(),
      )) {
        final type = event['type']?.toString();
        if (type == 'error') {
          throw Exception(event['message']?.toString() ?? 'stream error');
        }
        if (type == 'result') {
          final emails = event['emails'];
          addEmails(
            event['source']?.toString() ?? '',
            emails is List ? emails : null,
          );
        }
        if (type == 'done') {
          final emails = event['emails'];
          addEmails('verified', emails is List ? emails : null);
        }
      }

      final finalEmails = pickDiverseEmails(bySource, _maxRevealedEmails);
      store.completeEmailReveal(
        rowId,
        finalEmails.isNotEmpty ? finalEmails.join(', ') : null,
      );
      if (!mounted) return;
      if (finalEmails.isNotEmpty) {
        TopToastUtil.showSuccess(
          context: context,
          title: '邮箱获取成功',
          description: '积分已扣除',
        );
      }
    } catch (error) {
      if (!mounted) return;
      if (isInsufficientCreditsError(error)) {
        await showCreditsExhaustedSheet(
          context,
          reason: CreditsExhaustedReason.email,
        );
      } else {
        TopToastUtil.showError(
          context: context,
          title: '未找到邮箱，请重试',
          description: '',
        );
      }
      store.failEmailReveal(rowId);
    } finally {
      if (mounted) {
        refreshCreditsAfterMutation(context.read<UserStore>());
      }
    }
  }

  void _showConnectPrompt() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect email account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect your email to send this cold email from your own address.',
                  style: TextStyle(fontSize: 14, color: _C.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: _C.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE5E2DC)),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/me/integration');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Go to Integration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get email / Shortlist / 私信按钮区；person 未就绪或 error 时为 null
  Widget? _buildActionButtons() {
    final entry = widget.entry;
    final person = entry.person;
    final hasPerson = person != null && person.name.trim().isNotEmpty;
    if (!hasPerson || entry.status == EnrichStatus.error) return null;
    final rowId = widget.selectedRowId;
    final favoriteId = rowId != null ? _favoriteMap[rowId] : null;
    final isFavorited = favoriteId != null;
    final isRevealing = entry.emailRevealing;
    final emailRevealed = entry.emailRevealAttempted;
    final revealedEmail = entry.revealedEmail;
    final emailRevealError = entry.emailRevealError;
    final revealedEmails = revealedEmail == null
        ? const <String>[]
        : usableEmails(revealedEmail);
    final hasEmails = revealedEmails.isNotEmpty;
    final revealState = isRevealing
        ? 'loading'
        : emailRevealed && hasEmails
        ? 'send'
        : emailRevealed && emailRevealError
        ? 'retry'
        : emailRevealed
        ? 'not-found'
        : 'get';
    final dinqDomain = _dinqDomain(person.personalHomepage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.shortlistMode)
          _EmailActionButton(
            state: revealState,
            onPressed: (isRevealing || revealState == 'not-found')
                ? null
                : () {
                    if (revealState == 'send') {
                      if (_emailConnected) {
                        EnrichContactEmailModal.show(
                          context,
                          recipientEmail: revealedEmails.join(', '),
                          recipientName: person.name,
                          favoriteId: favoriteId,
                          recipientTitle: [
                            person.position,
                            person.location,
                          ].whereType<String>().map(stripBold).join(' • '),
                        );
                      } else {
                        _showConnectPrompt();
                      }
                    } else {
                      _handleRevealEmail();
                    }
                  },
          )
        else
          Row(
            children: [
              Expanded(
                child: _EmailActionButton(
                  state: revealState,
                  onPressed: (isRevealing || revealState == 'not-found')
                      ? null
                      : () {
                          if (revealState == 'send') {
                            if (_emailConnected) {
                              EnrichContactEmailModal.show(
                                context,
                                recipientEmail: revealedEmails.join(', '),
                                recipientName: person.name,
                                favoriteId: favoriteId,
                                recipientTitle:
                                    [person.position, person.location]
                                        .whereType<String>()
                                        .map(stripBold)
                                        .join(' • '),
                              );
                            } else {
                              _showConnectPrompt();
                            }
                          } else {
                            _handleRevealEmail();
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShortlistButton(
                  isFavorited: isFavorited,
                  onPressed: () => _handleBookmark(rowId, person, favoriteId),
                ),
              ),
            ],
          ),
        // 站内私信：仅对「在 dinq 注册且有主页」的用户展示（personalHomepage
        // 指向 dinq.me/<domain>）。对齐 web ProfileSection 私信入口。
        if (!widget.shortlistMode && dinqDomain != null) ...[
          const SizedBox(height: 8),
          _MessageButton(
            loading: _isStartingChat,
            onPressed: _isStartingChat ? null : () => _startChat(dinqDomain),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final person = entry.person;
    final hasPerson = person != null && person.name.trim().isNotEmpty;
    // 对齐 Web：首屏等待 person；流式阶段各区块数据未到也显示骨架。
    final isAwaitingPerson =
        !hasPerson &&
        entry.status != EnrichStatus.done &&
        entry.status != EnrichStatus.error;
    final isStreaming = entry.status == EnrichStatus.streaming;
    bool sectionSkeleton(bool hasData) => !hasData && isStreaming;
    final revealedEmail = entry.revealedEmail;
    final oneLiner = person?.oneLiner;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // space-y-4 block: avatar + social + buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(person: person, isAwaiting: isAwaitingPerson),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (person?.name != null &&
                          person!.name.trim().isNotEmpty)
                        Text.rich(
                          _oneLinerSpan(
                            person.name,
                            base: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (isAwaitingPerson)
                        const _SkeletonLine(widthFactor: 0.6, height: 24),
                      if (person?.position != null || person?.company != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: EnrichSvgIcon(
                                  EnrichIcons.briefcase,
                                  size: 14,
                                  color: _C.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: _PositionCompany(person: person)),
                            ],
                          ),
                        ),
                      if (person?.university != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const EnrichSvgIcon(
                                EnrichIcons.graduationCap,
                                size: 14,
                                color: _C.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: renderOneLiner(
                                  parseUniversity(person!.university!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _C.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (person?.location != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const EnrichSvgIcon(
                                EnrichIcons.mapPin,
                                size: 14,
                                color: _C.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: renderOneLiner(
                                  person!.location!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _C.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isAwaitingPerson) ...[
                        const SizedBox(height: 4),
                        const _SkeletonLine(widthFactor: 0.55, height: 16),
                        const SizedBox(height: 4),
                        const _SkeletonLine(widthFactor: 0.42, height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if ((person?.socialLinks?.isNotEmpty ?? false) ||
                (person?.personalHomepage?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final link in person?.socialLinks ?? const [])
                    _SocialChip(type: link.type, url: link.url),
                  if (person?.personalHomepage != null &&
                      person!.personalHomepage!.isNotEmpty)
                    _SocialChip(
                      type: 'homepage',
                      url: person.personalHomepage!,
                    ),
                ],
              ),
            ],
            // 获取 email 后展示邮箱列表（每行可复制，>2 折叠），对齐设计稿
            if (revealedEmail != null &&
                usableEmails(revealedEmail).isNotEmpty) ...[
              const SizedBox(height: 16),
              _EmailListCard(emails: usableEmails(revealedEmail)),
            ],
            // pinActions 模式下按钮移到页面底部常驻栏，不再内联
            if (!widget.pinActions)
              if (_buildActionButtons() case final actions?) ...[
                const SizedBox(height: 16),
                actions,
              ],
          ],
        ),

        // space-y-6 gap before match context — 对齐 Web ProfileSection
        if (person?.oneLiner != null ||
            (person?.researchAreas?.isNotEmpty ?? false) ||
            isStreaming) ...[
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                title: widget.shortlistMode
                    ? 'Candidate summary'
                    : 'Match context',
              ),
              if (oneLiner != null)
                Container(
                  width: double.infinity,
                  // Web: px-3 py-2.5 rounded-lg bg-[#faf9f7]
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _C.bgMatch,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: renderMatchContextBlock(
                    text: oneLiner,
                    matchPct: widget.shortlistMode
                        ? null
                        : widget.confidencePct,
                  ),
                ),
              if (isStreaming) const _SkeletonBlock(),
              if (person?.researchAreas != null &&
                  person!.researchAreas!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: person.researchAreas!
                        .take(3)
                        .map(
                          (area) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _C.bgSkeleton,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              area,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _C.textBody,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (isStreaming)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: const [
                      _SkeletonLine(width: 80, height: 24),
                      SizedBox(width: 6),
                      _SkeletonLine(width: 96, height: 24),
                      SizedBox(width: 6),
                      _SkeletonLine(width: 64, height: 24),
                    ],
                  ),
                ),
            ],
          ),
        ],

        if (person?.educationHistory != null &&
            person!.educationHistory!.isNotEmpty)
          _EducationSection(items: person.educationHistory!)
        else if (sectionSkeleton(person?.educationHistory?.isNotEmpty != true))
          const _EducationSkeleton(),

        if (person?.workExperience != null &&
            person!.workExperience!.isNotEmpty)
          _WorkSection(items: person.workExperience!)
        else if (sectionSkeleton(person?.workExperience?.isNotEmpty != true))
          const _WorkSkeleton(),

        if (person?.keyPublications != null &&
            person!.keyPublications!.isNotEmpty)
          _PublicationsSection(
            publications: person.keyPublications!,
            isMobile: widget.isMobile,
          )
        else if (sectionSkeleton(person?.keyPublications?.isNotEmpty != true))
          const _PublicationsSkeleton(),

        if (person?.news != null && person!.news!.isNotEmpty)
          _PersonNewsSection(news: person.news!)
        else if (sectionSkeleton(person?.news?.isNotEmpty != true))
          const _RecentActivitySkeleton(),
      ],
    );

    if (!widget.pinActions) return content;

    // 整页模式：内容区滚动，操作按钮栏固定在页面底部
    final actions = _buildActionButtons();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.pinnedHeader != null) ...[
                  widget.pinnedHeader!,
                  const SizedBox(height: 16),
                ],
                content,
              ],
            ),
          ),
        ),
        if (actions != null)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _C.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: actions,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleBookmark(
    String? rowId,
    EnrichResultPerson person,
    String? favoriteId,
  ) async {
    if (rowId == null) return;
    if (favoriteId != null) {
      await _shortlistService.removeFavorite(favoriteId);
      setState(() => _favoriteMap.remove(rowId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from shortlist')));
      }
      return;
    }
    final projectId = await showShortlistFolderModal(context);
    if (projectId == null || !mounted) return;
    final item = await _shortlistService.createFavorite(
      projectId: projectId,
      title: stripBold(person.name),
      field: {
        'row_id': rowId,
        'name': stripBold(person.name),
        if (person.company != null) 'company': stripBold(person.company!),
        if (person.position != null) 'title': stripBold(person.position!),
      },
    );
    setState(() => _favoriteMap[rowId] = item.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to folder')));
    }
  }

  /// 从 personalHomepage 解析 dinq 主页 domain（形如 dinq.me/xxx）。
  /// 只有指向 dinq.me 单段路径、且非保留路径时才视为「已注册且有主页」的用户。
  static const _reservedDomains = {
    'invite',
    'integration',
    'api-playground',
    'api',
    'search',
    'settings',
    'signin',
    'u',
  };

  String? _dinqDomain(String? homepage) {
    if (homepage == null || homepage.isEmpty) return null;
    final normalized = homepage.startsWith('http')
        ? homepage
        : 'https://$homepage';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;
    if (!uri.host.toLowerCase().endsWith('dinq.me')) return null;
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length != 1) return null;
    final domain = segs.first;
    if (_reservedDomains.contains(domain.toLowerCase())) return null;
    return domain;
  }

  /// 站内私信：先按 domain 解析出 user_id 再创建私聊会话（对齐 profile_page._startChat）。
  /// 未登录跳登录；成功后进入会话详情页。
  Future<void> _startChat(String domain) async {
    if (_isStartingChat) return;
    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) {
      context.push('/signin');
      return;
    }
    setState(() => _isStartingChat = true);
    try {
      final userData = await _profileService.getUserData(domain);
      if (userData.userId.isEmpty) {
        if (mounted) _snack('This user cannot be messaged');
        return;
      }
      final resp = await _messageService.createPrivateConversation(
        userData.userId,
      );
      final conv = resp['conversation'];
      final convId =
          (conv is Map ? (conv['id'] ?? conv['conversation_id']) : resp['id'])
              ?.toString() ??
          '';
      if (!mounted) return;
      if (convId.isNotEmpty) {
        context.push('/admin/inbox/$convId');
      } else {
        _snack('Failed to open conversation');
      }
    } catch (e) {
      if (mounted) _snack(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton({required this.loading, this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF1F1F1F);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.borderBtn),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: fg,
                ),
              const SizedBox(width: 6),
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailActionButton extends StatelessWidget {
  const _EmailActionButton({required this.state, this.onPressed});

  final String state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = state == 'not-found';
    final bg = isDisabled ? _C.bgSkeleton : _C.bgBtnDark;
    final fg = isDisabled ? _C.textMuted : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      elevation: isDisabled ? 0 : 0,
      shadowColor: _C.btnShadow,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: isDisabled
                ? null
                : const [
                    BoxShadow(
                      color: _C.btnShadow,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state == 'loading') ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                const SizedBox(width: 6),
                Text(
                  'Revealing...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ] else if (state == 'retry') ...[
                EnrichSvgIcon(EnrichIcons.refresh, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ] else if (state == 'not-found') ...[
                EnrichSvgIcon(EnrichIcons.mail, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  'Email not found',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ] else if (state == 'send') ...[
                EnrichSvgIcon(EnrichIcons.mail, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  'Send email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ] else ...[
                EnrichSvgIcon(EnrichIcons.mail, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  'Get email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortlistButton extends StatelessWidget {
  const _ShortlistButton({required this.isFavorited, required this.onPressed});

  final bool isFavorited;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isFavorited ? _C.bgShortlist : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.borderBtn),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EnrichSvgIcon(
                isFavorited ? EnrichIcons.bookmarkFilled : EnrichIcons.bookmark,
                size: 14,
                color: const Color(0xFF1F1F1F),
              ),
              const SizedBox(width: 6),
              Text(
                isFavorited ? 'Shortlisted' : 'Shortlist',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.person, required this.isAwaiting});

  final EnrichResultPerson? person;
  final bool isAwaiting;

  @override
  Widget build(BuildContext context) {
    final imageUrl = person?.imageUrl;
    final name = person?.name;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _C.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) =>
              _initialsAvatar(name, isAwaiting: isAwaiting),
        ),
      );
    }
    return _initialsAvatar(name, isAwaiting: isAwaiting);
  }

  Widget _initialsAvatar(String? name, {required bool isAwaiting}) {
    if (isAwaiting && (name == null || name.trim().isEmpty)) {
      return const _SkeletonLine(width: 80, height: 80, borderRadius: 40);
    }
    final initials = name != null && name.trim().isNotEmpty
        ? toInitials(stripBold(name))
        : '?';
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: _C.bgSkeleton,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _C.textMuted,
        ),
      ),
    );
  }
}

class _PositionCompany extends StatelessWidget {
  const _PositionCompany({required this.person});
  final EnrichResultPerson? person;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (person?.position != null)
            _oneLinerSpan(
              person!.position!,
              base: const TextStyle(fontSize: 14, color: _C.textSecondary),
            ),
          if (person?.position != null && person?.company != null)
            const TextSpan(
              text: ' · ',
              style: TextStyle(fontSize: 14, color: _C.textDot),
            ),
          if (person?.company != null)
            _oneLinerSpan(
              person!.company!,
              base: const TextStyle(fontSize: 14, color: _C.textMuted),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.type, required this.url});
  final String type;
  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final label = type == 'homepage' ? 'Homepage' : _socialLabel(type);
    final asset = type == 'homepage' ? null : enrichSocialIconAsset(type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: _C.borderLight),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (asset != null)
                AssetIcon(asset: asset, size: 14)
              else
                const EnrichSvgIcon(
                  EnrichIcons.externalLink,
                  size: 14,
                  color: _C.textSecondary,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: _C.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.match});
  final int match;

  @override
  Widget build(BuildContext context) {
    final style = matchBadgeStyle(match);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border(
          top: BorderSide(color: style.border),
          left: BorderSide(color: style.border),
          right: BorderSide(color: style.border),
        ),
      ),
      child: Text(
        '$match%',
        style: TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: style.foreground,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: _C.divider, height: 1, thickness: 1),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.isFirst,
    required this.isLast,
    required this.iconAsset,
    this.period,
  });

  final String title;
  final String subtitle;
  final String? period;
  final bool isFirst;
  final bool isLast;
  final String iconAsset;

  static const _itemHeight = 72.0; // h-18
  static const _titleHeight = 48.0; // h-12

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 8, // w-2
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 20, // top-5
                  left: 0,
                  child: Container(
                    width: 8, // w-2
                    height: 8, // h-2
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst ? Colors.white : _C.dotFill,
                      border: isFirst ? Border.all(color: _C.textMuted) : null,
                    ),
                  ),
                ),
                if (!isLast)
                  Positioned(
                    top: 28, // top-5 + mt-2
                    left: 3, // left-[3px]
                    bottom: -8, // span into space-y-2 gap
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(1, constraints.maxHeight),
                          painter: _DashedLinePainter(),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8), // gap-2
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _titleHeight,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _C.border)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isFirst ? _C.textMuted : _C.border,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28, // w-7
                                  height: 28, // h-7
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _C.bgSkeleton,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: EnrichSvgIcon(
                                    iconAsset,
                                    size: 14,
                                    color: _C.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8), // gap-2
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _C.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (period != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Center(
                              child: Text(
                                period!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _C.textMuted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8), // pl-2
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 32 / 12, // leading-8
                        color: _C.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.dotFill
      ..strokeWidth = 1;
    const dashHeight = 4.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EducationSection extends StatelessWidget {
  const _EducationSection({required this.items});
  final List<EnrichEducationHistory> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'Education'),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? 8 : 0),
              child: _TimelineRow(
                title: items[i].institution,
                subtitle: [
                  items[i].degree,
                  items[i].field,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                period: items[i].period,
                isFirst: i == 0,
                isLast: i == items.length - 1,
                iconAsset: EnrichIcons.graduationCap,
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkSection extends StatelessWidget {
  const _WorkSection({required this.items});
  final List<EnrichWorkExperience> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'Work experience'),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? 8 : 0),
              child: _TimelineRow(
                title: items[i].organization,
                subtitle: items[i].role ?? items[i].details ?? '',
                period: items[i].period,
                isFirst: i == 0,
                isLast: i == items.length - 1,
                iconAsset: EnrichIcons.briefcase,
              ),
            ),
        ],
      ),
    );
  }
}

class _PublicationCard extends StatefulWidget {
  const _PublicationCard({required this.publication, required this.isMobile});

  final EnrichPublication publication;
  final bool isMobile;

  @override
  State<_PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<_PublicationCard> {
  bool _hovered = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.publication.title));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _openUrl() async {
    final url = widget.publication.url;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActions = widget.isMobile || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _hovered ? const Color(0xFFD6D3CD) : _C.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Text(
              widget.publication.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _C.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showActions)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_copied)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                'Copied',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _C.textMuted,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: _copy,
                              icon: const EnrichSvgIcon(
                                EnrichIcons.copy,
                                size: 14,
                              ),
                              color: _C.textMuted,
                            ),
                          if (widget.publication.url != null)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: _openUrl,
                              icon: const EnrichSvgIcon(
                                EnrichIcons.externalLink,
                                size: 14,
                              ),
                              color: _C.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicationsSection extends StatelessWidget {
  const _PublicationsSection({
    required this.publications,
    required this.isMobile,
  });

  final List<EnrichPublication> publications;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(title: 'Publications'),
          for (final pub in publications)
            _PublicationCard(publication: pub, isMobile: isMobile),
        ],
      ),
    );
  }
}

class _PersonNewsSection extends StatelessWidget {
  const _PersonNewsSection({required this.news});
  final List<EnrichNewsItem> news;

  @override
  Widget build(BuildContext context) {
    final activities = news
        .where(
          (item) => !RegExp(
            _sourceLineRe,
            caseSensitive: false,
          ).hasMatch(item.description),
        )
        .toList();
    final sources = news
        .where(
          (item) =>
              RegExp(
                _sourceLineRe,
                caseSensitive: false,
              ).hasMatch(item.description) &&
              (item.url?.isNotEmpty ?? false),
        )
        .toList();
    if (activities.isEmpty && sources.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Recent activity'),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                for (var i = 0; i < activities.length; i++)
                  _NewsActivityItem(
                    item: activities[i],
                    showConnector:
                        !(i == activities.length - 1 && sources.isEmpty),
                  ),
                if (sources.isNotEmpty) _NewsOthersGroup(sources: sources),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsActivityItem extends StatelessWidget {
  const _NewsActivityItem({required this.item, required this.showConnector});

  final EnrichNewsItem item;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final hasUrl = item.url != null && item.url!.isNotEmpty;
    final domain = hasUrl ? _hostnameFromUrl(item.url!) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -24,
            top: 0,
            child: SizedBox(
              width: 24,
              height: 20,
              child: Center(
                child: hasUrl
                    ? const EnrichSvgIcon(
                        EnrichIcons.globe,
                        size: 14,
                        color: _C.textMuted,
                      )
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _C.dotFill,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),
          if (showConnector)
            Positioned(
              left: -12,
              top: 20,
              bottom: -12,
              child: Container(width: 1, color: _C.border),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: hasUrl
                    ? () => launchUrl(
                        Uri.parse(item.url!),
                        mode: LaunchMode.externalApplication,
                      )
                    : null,
                child: renderOneLiner(item.description),
              ),
              if (hasUrl && domain != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _DomainTag(url: item.url!, domain: domain),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsOthersGroup extends StatelessWidget {
  const _NewsOthersGroup({required this.sources});
  final List<EnrichNewsItem> sources;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -24,
          top: 0,
          child: SizedBox(
            width: 24,
            height: 20,
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _C.dotFill,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Others',
              style: TextStyle(fontSize: 14, color: _C.textBody),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _C.border),
                borderRadius: BorderRadius.circular(8),
                color: _C.bgPanel,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < sources.length; i++)
                    _OthersSourceRow(
                      url: sources[i].url!,
                      domain: _hostnameFromUrl(sources[i].url!),
                      isLast: i == sources.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DomainTag extends StatelessWidget {
  const _DomainTag({required this.url, required this.domain});
  final String url;
  final String domain;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(8),
          color: _C.bgPanel,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Favicon(domain: domain),
            const SizedBox(width: 6),
            Text(
              domain,
              style: const TextStyle(fontSize: 12, color: _C.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OthersSourceRow extends StatelessWidget {
  const _OthersSourceRow({
    required this.url,
    required this.domain,
    required this.isLast,
  });

  final String url;
  final String domain;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: _C.border)),
          ),
          child: Row(
            children: [
              _Favicon(domain: domain),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  domain,
                  style: const TextStyle(fontSize: 12, color: _C.textBody),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Favicon extends StatelessWidget {
  const _Favicon({required this.domain});
  final String domain;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        'https://icons.duckduckgo.com/ip3/$domain.ico',
        width: 14,
        height: 14,
        errorBuilder: (_, _, _) => const EnrichSvgIcon(
          EnrichIcons.globe,
          size: 14,
          color: _C.textMuted,
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatefulWidget {
  const _SkeletonLine({
    this.width,
    this.widthFactor,
    this.height = 16,
    this.borderRadius = 4,
  });

  final double? width;
  final double? widthFactor;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<_SkeletonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final factor = widget.widthFactor ?? 1;
        final resolvedWidth =
            widget.width ??
            (constraints.maxWidth.isFinite
                ? constraints.maxWidth * factor
                : 200 * factor);

        return FadeTransition(
          opacity: Tween<double>(begin: 0.5, end: 1).animate(_controller),
          child: Container(
            width: resolvedWidth,
            height: widget.height,
            decoration: BoxDecoration(
              color: _C.bgSkeleton,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 12),
        _SkeletonLine(widthFactor: 0.75),
        SizedBox(height: 8),
        _SkeletonLine(widthFactor: 0.5),
      ],
    );
  }
}

class _EducationSkeleton extends StatelessWidget {
  const _EducationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Education'),
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonLine(width: 28, height: 28, borderRadius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonLine(widthFactor: 0.55),
                        SizedBox(height: 6),
                        _SkeletonLine(widthFactor: 0.38),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkSkeleton extends StatelessWidget {
  const _WorkSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Work experience'),
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonLine(width: 28, height: 28, borderRadius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonLine(widthFactor: 0.48),
                        SizedBox(height: 6),
                        _SkeletonLine(widthFactor: 0.32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PublicationsSkeleton extends StatelessWidget {
  const _PublicationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Publications'),
          SizedBox(height: 4),
          _SkeletonLine(widthFactor: 1),
          SizedBox(height: 6),
          _SkeletonLine(widthFactor: 0.9),
        ],
      ),
    );
  }
}

class _RecentActivitySkeleton extends StatelessWidget {
  const _RecentActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Recent activity'),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                for (final w in [0.75, 0.9, 0.5])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 18),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0DDD8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(child: _SkeletonLine(widthFactor: w)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 邮箱列表卡：每行 email + 复制按钮；超过 2 个折叠为 "Show N more emails"。
class _EmailListCard extends StatefulWidget {
  const _EmailListCard({required this.emails});

  final List<String> emails;

  @override
  State<_EmailListCard> createState() => _EmailListCardState();
}

class _EmailListCardState extends State<_EmailListCard> {
  static const _collapsedCount = 2;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final emails = widget.emails;
    if (emails.isEmpty) return const SizedBox.shrink();
    final hiddenCount = emails.length - _collapsedCount;
    final visible = _expanded || hiddenCount <= 0
        ? emails
        : emails.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _EmailRow(email: visible[i]),
        ],
        if (hiddenCount > 0) ...[
          const SizedBox(height: 8),
          Material(
            color: _C.bgMatch,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show fewer emails'
                          : 'Show $hiddenCount more emails',
                      style: const TextStyle(fontSize: 14, color: _C.textMuted),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: _C.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _C.bgMatch,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const EnrichSvgIcon(EnrichIcons.mail, size: 16, color: _C.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: _C.textPrimary),
            ),
          ),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: email));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy_outlined, size: 16, color: _C.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
