import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import 'update_required_panel.dart';

typedef OpenUpdateLink = Future<bool> Function(String url);

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

  /// 调用 GET /api/v1/app/version，按服务端 update_type 控制弹窗和 Skip。
  Future<void> _check() async {
    if (_checking) return;
    _checking = true;

    final result = await _checker.check();

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
    if (update == null || _opening) return;
    final url = update.effectiveDownloadUrl;
    if (url.isEmpty) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    var opened = false;
    try {
      opened = await _openUpdate(url);
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
    // 仅 optional 可 Skip；force 不允许关闭
    if (update == null || update.isForceUpdate) return;
    setState(() {
      _dismissedVersionCode = update.latestVersionCode;
      _update = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    // update_type == force → 不显示 Skip；optional → 显示 Skip
    final canSkip = update != null && !update.isForceUpdate;
    return PopScope(
      canPop: canSkip || update == null,
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
                    canSkip: canSkip,
                    releaseNotes: UpdateRequiredPanel.parseReleaseNotes(
                      update.releaseNotes,
                    ),
                    opening: _opening,
                    error: _error,
                    onSkip: canSkip ? _dismiss : null,
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
