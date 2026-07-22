import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_update_service.dart';

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
    _openUpdate = widget.openUpdate ?? _openExternal;
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

  Future<bool> _openExternal(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 360,
                      constraints: const BoxConstraints(maxHeight: 520),
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            forced ? 'Update required' : 'Update available',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            update.latestVersion.isEmpty
                                ? 'A new version of DINQ is available.'
                                : 'DINQ ${update.latestVersion} is available.',
                          ),
                          if (update.releaseNotes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Text(update.releaseNotes),
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!forced) ...[
                                TextButton(
                                  onPressed: _opening ? null : _dismiss,
                                  child: const Text('Later'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              FilledButton(
                                onPressed: _opening ? null : _updateNow,
                                child: Text(
                                  _opening ? 'Opening…' : 'Update now',
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
            ),
          ],
        ],
      ),
    );
  }
}
