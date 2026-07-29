import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/app_constants.dart';
import '../../../../services/auth_service.dart';
import '../../../../stores/user_store.dart';
import '../../../../utils/top_toast_util.dart';
import '../../analysis/analysis_theme.dart';

/// 对齐 Web `analysisAction.tsx`。
String? getProfileSignalAnalysisUserId(
  String platform,
  String? url, {
  String? fallbackId,
}) {
  if (url != null && url.isNotEmpty) {
    try {
      if (platform == 'github') {
        final match = RegExp(r'github\.com/([^/?#]+)', caseSensitive: false)
            .firstMatch(url);
        if (match?.group(1) != null) return match!.group(1);
      }
      if (platform == 'scholar') {
        final parsed = Uri.parse(url);
        final scholarId = parsed.queryParameters['user'];
        if (scholarId != null && scholarId.isNotEmpty) return scholarId;
      }
      if (platform == 'linkedin') {
        final match = RegExp(r'linkedin\.com/in/([^/?#]+)', caseSensitive: false)
            .firstMatch(url);
        if (match?.group(1) != null) return match!.group(1);
      }
    } catch (_) {}
  }
  if (fallbackId != null && fallbackId.isNotEmpty) return fallbackId;
  return null;
}

Future<bool> openProfileSignalAnalysisPage(
  BuildContext context,
  String platform,
  String? url, {
  String? fallbackId,
}) async {
  final userStore = context.read<UserStore>();
  if (!userStore.isLoggedIn()) return false;

  final userId = getProfileSignalAnalysisUserId(
    platform,
    url,
    fallbackId: fallbackId,
  );
  if (userId == null) return false;

  try {
    final ticketRes = await AuthService().webLoginTicket();
    final ticket = ticketRes['ticket']?.toString();
    if (ticket == null || ticket.isEmpty) return false;

    final uri = Uri.parse('$analysisBaseUrl/$platform').replace(
      queryParameters: {
        'user': userId,
        'ticket': ticket,
      },
    );
    debugPrint('Analysis web uri: $uri');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (!context.mounted) return false;
    TopToastUtil.showError(
      context: context,
      title: 'Failed to open analysis. Please try again.',
    );
    return false;
  }
}

class ProfileSignalAnalysisButton extends StatelessWidget {
  const ProfileSignalAnalysisButton({
    super.key,
    required this.platform,
    this.url,
    this.fallbackId,
    this.label = 'Analysis',
  });

  final String platform;
  final String? url;
  final String? fallbackId;
  final String label;

  @override
  Widget build(BuildContext context) {
    final userId = getProfileSignalAnalysisUserId(
      platform,
      url,
      fallbackId: fallbackId,
    );
    if (userId == null) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => openProfileSignalAnalysisPage(
          context,
          platform,
          url,
          fallbackId: fallbackId,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD8D5CF)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AnalysisTheme.actionBarChart,
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF2A2826),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2A2826),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
