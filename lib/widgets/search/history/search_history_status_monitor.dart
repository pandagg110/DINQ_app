import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../stores/chat_history_store.dart';
import '../../../stores/search_store.dart';
import '../../../stores/user_store.dart';

/// 对齐 Web `SearchHistoryStatusMonitor`：在应用工作区持续刷新后台搜索状态。
class SearchHistoryStatusMonitor extends StatefulWidget {
  const SearchHistoryStatusMonitor({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<SearchHistoryStatusMonitor> createState() =>
      _SearchHistoryStatusMonitorState();
}

class _SearchHistoryStatusMonitorState
    extends State<SearchHistoryStatusMonitor> {
  static const _refreshLimit = 20;
  static const _runningTtl = Duration(minutes: 30);
  static const _failureBackoff = <Duration>[
    Duration.zero,
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  ChatHistoryStore? _historyStore;
  SearchStore? _searchStore;
  UserStore? _userStore;
  Timer? _pollTimer;
  final Map<String, DateTime> _runningSince = {};
  final Set<String> _expiredRunningKeys = {};
  bool _refreshInFlight = false;
  bool _immediateRefreshScheduled = false;
  bool _refreshRequestedAfterFlight = false;
  bool _wasAuthenticated = false;
  int _failureCount = 0;
  DateTime? _nextPollAt;
  bool _sourceKeysInitialized = false;
  String? _lastCurrentDiscoverRouteKey;
  String? _lastForegroundRunningKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final historyStore = context.read<ChatHistoryStore>();
    final searchStore = context.read<SearchStore>();
    final userStore = context.read<UserStore>();

    if (!identical(_historyStore, historyStore)) {
      _historyStore?.removeListener(_onSourceChanged);
      _historyStore = historyStore..addListener(_onSourceChanged);
    }
    if (!identical(_searchStore, searchStore)) {
      _searchStore?.removeListener(_onSourceChanged);
      _searchStore = searchStore..addListener(_onSourceChanged);
    }
    if (!identical(_userStore, userStore)) {
      _userStore?.removeListener(_onSourceChanged);
      _userStore = userStore..addListener(_onSourceChanged);
    }

    widget.router.routeInformationProvider.removeListener(_onSourceChanged);
    widget.router.routeInformationProvider.addListener(_onSourceChanged);
    _onSourceChanged();
  }

  @override
  void didUpdateWidget(covariant SearchHistoryStatusMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.router, widget.router)) return;
    oldWidget.router.routeInformationProvider.removeListener(_onSourceChanged);
    widget.router.routeInformationProvider.addListener(_onSourceChanged);
    _onSourceChanged();
  }

  void _onSourceChanged() {
    if (!mounted) return;
    final authenticated = _userStore?.user != null;
    if (!authenticated) {
      _wasAuthenticated = false;
      _sourceKeysInitialized = false;
      _lastCurrentDiscoverRouteKey = null;
      _lastForegroundRunningKey = null;
      _pollTimer?.cancel();
      _pollTimer = null;
      _runningSince.clear();
      _expiredRunningKeys.clear();
      _failureCount = 0;
      _nextPollAt = null;
      _immediateRefreshScheduled = false;
      _refreshRequestedAfterFlight = false;
      return;
    }

    final justAuthenticated = !_wasAuthenticated;
    _wasAuthenticated = true;
    final currentDiscoverRouteKey = _currentDiscoverRouteKey;
    final foregroundRunningKey = _foregroundRunningKey;
    final sourceKeysChanged =
        !_sourceKeysInitialized ||
        currentDiscoverRouteKey != _lastCurrentDiscoverRouteKey ||
        foregroundRunningKey != _lastForegroundRunningKey;
    _sourceKeysInitialized = true;
    _lastCurrentDiscoverRouteKey = currentDiscoverRouteKey;
    _lastForegroundRunningKey = foregroundRunningKey;
    final syncResult = _syncRunningStates();
    if (justAuthenticated || sourceKeysChanged) {
      if (_refreshInFlight) {
        _refreshRequestedAfterFlight = true;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshStatuses(ignoreBackoff: true));
      });
      return;
    }
    if (syncResult.addedBackgroundRunning) {
      if (_refreshInFlight) {
        if (syncResult.becameBackgroundActive) {
          _refreshRequestedAfterFlight = true;
        }
      } else {
        _requestImmediateRefresh();
      }
      return;
    }
    if (!_refreshInFlight) _scheduleNextPoll();
  }

  String? get _currentDiscoverRouteKey {
    final segments =
        widget.router.routeInformationProvider.value.uri.pathSegments;
    if (segments.length == 2 && segments.first == 'search') {
      const toolSegments = {'advisor', 'citation', 'analyze'};
      if (!toolSegments.contains(segments[1])) return 'discover-${segments[1]}';
    }
    if (segments.length >= 3 &&
        segments.first == 'search' &&
        segments[1] == 'discover') {
      return 'discover-${segments[2]}';
    }
    return null;
  }

  String? get _foregroundRunningKey {
    final searchStore = _searchStore;
    final sessionId = searchStore?.deepSearchSessionId;
    if (searchStore?.isSearching != true ||
        sessionId == null ||
        sessionId.isEmpty) {
      return null;
    }
    return 'discover-$sessionId';
  }

  bool _isLocalOnlyRunningConversation(ConversationItem conversation) {
    final key = conversation.key;
    if (key == _foregroundRunningKey) return true;
    return key == _currentDiscoverRouteKey && !conversation.isLocalPending;
  }

  List<ConversationItem> _statusConversations(ChatHistoryStore historyStore) {
    final latestTop = historyStore.latestTopConversations;
    final byKey = <String, ConversationItem>{
      for (final conversation in latestTop ?? historyStore.conversations)
        if (conversation.type == ChatHistoryStore.searchConversationType)
          conversation.key: conversation,
    };

    // 服务端尚未确认的本地 pending 不属于 raw top 20，但仍必须保留在
    // polling 状态机中；同 key 时用合并列表中的 pending 覆盖服务端项。
    for (final conversation in historyStore.pendingDiscoverConversations) {
      byKey[conversation.key] = conversation;
    }
    return byKey.values.toList(growable: false);
  }

  ({bool addedBackgroundRunning, bool becameBackgroundActive})
  _syncRunningStates() {
    final historyStore = _historyStore;
    if (historyStore == null) {
      return (addedBackgroundRunning: false, becameBackgroundActive: false);
    }

    final now = DateTime.now();
    _pruneExpiredRunningKeys(now);
    final previousBackgroundCount = _runningSince.length;
    final seenKeys = <String>{};
    var addedBackgroundRunning = false;

    // 当前路由的未读状态不受 top-20 polling 边界限制。
    for (final conversation in historyStore.conversations) {
      if (conversation.type != ChatHistoryStore.searchConversationType) {
        continue;
      }
      if (conversation.isRead == false &&
          conversation.key == _currentDiscoverRouteKey) {
        unawaited(historyStore.markDiscoverSessionRead(conversation.id));
      }
    }

    for (final conversation in _statusConversations(historyStore)) {
      final key = conversation.key;
      seenKeys.add(key);
      final state = conversation.effectiveSearchState;

      if (state == 'running' && _isLocalOnlyRunningConversation(conversation)) {
        _runningSince.remove(key);
        _expiredRunningKeys.remove(key);
      } else if (state == 'running') {
        if (!_expiredRunningKeys.contains(key)) {
          if (!_runningSince.containsKey(key)) {
            _runningSince[key] = now;
            addedBackgroundRunning = true;
          }
        }
      } else {
        _runningSince.remove(key);
        _expiredRunningKeys.remove(key);
      }
    }

    for (final key in _runningSince.keys.toList()) {
      if (!seenKeys.contains(key)) {
        _runningSince.remove(key);
        _expiredRunningKeys.remove(key);
      }
    }
    _pruneExpiredRunningKeys(now);
    return (
      addedBackgroundRunning: addedBackgroundRunning,
      becameBackgroundActive:
          previousBackgroundCount == 0 && _runningSince.isNotEmpty,
    );
  }

  void _pruneExpiredRunningKeys([DateTime? value]) {
    final now = value ?? DateTime.now();
    for (final entry in _runningSince.entries.toList()) {
      if (now.difference(entry.value) > _runningTtl) {
        _runningSince.remove(entry.key);
        _expiredRunningKeys.add(entry.key);
      }
    }
  }

  Duration? _pollInterval() {
    _pruneExpiredRunningKeys();
    DateTime? oldest;
    for (final entry in _runningSince.entries) {
      if (oldest == null || entry.value.isBefore(oldest)) oldest = entry.value;
    }
    if (oldest == null) return null;

    final age = DateTime.now().difference(oldest);
    if (age < const Duration(seconds: 30)) {
      return const Duration(milliseconds: 2500);
    }
    if (age < const Duration(minutes: 2)) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 10);
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
    final interval = _pollInterval();
    if (interval == null) return;

    var delay = interval;
    final nextPollAt = _nextPollAt;
    if (nextPollAt != null) {
      final untilBackoffEnds = nextPollAt.difference(DateTime.now());
      if (untilBackoffEnds > delay) delay = untilBackoffEnds;
    }

    _pollTimer = Timer(delay, () {
      _pollTimer = null;
      unawaited(_refreshStatuses());
    });
  }

  void _requestImmediateRefresh() {
    if (_refreshInFlight) {
      _refreshRequestedAfterFlight = true;
      return;
    }
    if (_immediateRefreshScheduled) return;

    _immediateRefreshScheduled = true;
    scheduleMicrotask(() {
      _immediateRefreshScheduled = false;
      if (!mounted || !_wasAuthenticated) return;
      unawaited(_refreshStatuses());
    });
  }

  Future<void> _refreshStatuses({bool ignoreBackoff = false}) async {
    final historyStore = _historyStore;
    if (historyStore == null || _refreshInFlight || !_wasAuthenticated) return;
    if (!ignoreBackoff) {
      final nextPollAt = _nextPollAt;
      if (nextPollAt != null && DateTime.now().isBefore(nextPollAt)) {
        _scheduleNextPoll();
        return;
      }
    }

    _refreshInFlight = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      final serverItems = await historyStore.refreshTopConversations(
        limit: _refreshLimit,
        rethrowErrors: true,
      );
      final foregroundKey = _foregroundRunningKey;
      historyStore.clearServerConfirmedPendingDiscoverSessions(
        serverItems,
        excludedKeys: foregroundKey == null
            ? const <String>{}
            : <String>{foregroundKey},
      );
      _failureCount = 0;
      _nextPollAt = null;
    } catch (_) {
      _failureCount = (_failureCount + 1).clamp(0, _failureBackoff.length - 1);
      _nextPollAt = DateTime.now().add(_failureBackoff[_failureCount]);
    } finally {
      _refreshInFlight = false;
      if (mounted && _wasAuthenticated) {
        final syncResult = _syncRunningStates();
        final needsImmediateRefresh =
            _refreshRequestedAfterFlight || syncResult.becameBackgroundActive;
        _refreshRequestedAfterFlight = false;
        if (needsImmediateRefresh) {
          _requestImmediateRefresh();
        } else {
          _scheduleNextPoll();
        }
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _historyStore?.removeListener(_onSourceChanged);
    _searchStore?.removeListener(_onSourceChanged);
    _userStore?.removeListener(_onSourceChanged);
    widget.router.routeInformationProvider.removeListener(_onSourceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
