import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import 'update_required_panel.dart';

typedef OpenUpdateLink = Future<bool> Function(String url);

/// 本地联调：为 true 时启动即弹出版本更新门禁（不请求接口）。
/// 测完请改回 false。
const bool kForceAppUpdatePrompt = true;

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
    this.checker,
    this.openUpdate,
  });

  final Widget child;
  final AppUpdateChecker? checker;
  final OpenUpdateLink? openUpdate;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  late final AppUpdateChecker _checker;
  late final OpenUpdateLink _openUpdate;
  AppUpdateInfo? _update;
  int? _dismissedVersionCode;
  bool _checking = false;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checker = widget.checker ?? AppUpdateService();
    _openUpdate = widget.openUpdate ?? openAppUpdateUrl;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  AppUpdateInfo _debugForceUpdate() {
    return const AppUpdateInfo(
      platform: 'android',
      channel: distributionChannel,
      updateType: AppUpdateType.force,
      latestVersion: '1.0.1',
      latestVersionCode: 999,
      minimumVersion: '1.0.1',
      minimumVersionCode: 999,
      releaseNotes: '',
      downloadUrl: 'https://dinq.me/download/android',
    );
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;

    AppUpdateInfo? result;
    // 仅无默认 checker 时生效，避免打断注入 FakeChecker 的单测
    if (kForceAppUpdatePrompt && kDebugMode && widget.checker == null) {
      result = _debugForceUpdate();
    } else {
      result = await _checker.check();
    }

    _checking = false;
    if (!mounted || result == null) return;

    final info = result;
    final dismissed =
        info.updateType == AppUpdateType.optional &&
        info.latestVersionCode == _dismissedVersionCode;
    setState(() {
      _error = null;
      _update = info.shouldShowPrompt && !dismissed ? info : null;
    });
  }

  Future<void> _updateNow() async {
    final update = _update;
    if (update == null || update.downloadUrl.isEmpty || _opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    var opened = false;
    try {
      opened = await _openUpdate(update.downloadUrl);
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      if (!opened) {
        _error = 'Unable to open the update page. Please try again.';
      }
    });
  }

  void _dismiss() {
    final update = _update;
    if (update == null || update.isForceUpdate) return;
    setState(() {
      _dismissedVersionCode = update.latestVersionCode;
      _update = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    final forced = update?.isForceUpdate ?? false;
    return PopScope(
      canPop: !forced,
      child: Stack(
        children: [
          widget.child,
          if (update != null) ...[
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Color(0x99000000)),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: UpdateRequiredPanel(
                    canSkip: !forced,
                    releaseNotes: UpdateRequiredPanel.parseReleaseNotes(
                      update.releaseNotes,
                    ),
                    opening: _opening,
                    error: _error,
                    onSkip: forced ? null : _dismiss,
                    onUpdateNow: _updateNow,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
