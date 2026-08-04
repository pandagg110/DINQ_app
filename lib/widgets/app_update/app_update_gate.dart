import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _currentVersion = '';
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

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    final result = await _checker.check();
    _checking = false;
    if (!mounted || result == null) return;

    final dismissed =
        result.updateType == AppUpdateType.optional &&
        result.latestVersionCode == _dismissedVersionCode;
    setState(() {
      _error = null;
      _update = result.shouldShowPrompt && !dismissed ? result : null;
    });

    // 版本号仅作展示，不阻塞门禁弹窗。
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _currentVersion = packageInfo.version);
    } catch (_) {}
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

  String _requiredVersion(AppUpdateInfo update) {
    if (update.latestVersion.isNotEmpty) return update.latestVersion;
    if (update.minimumVersion.isNotEmpty) return update.minimumVersion;
    return '';
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
                    currentVersion:
                        _currentVersion.isEmpty ? '—' : _currentVersion,
                    requiredVersion: _requiredVersion(update),
                    opening: _opening,
                    error: _error,
                    onDismiss: forced ? null : _dismiss,
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
