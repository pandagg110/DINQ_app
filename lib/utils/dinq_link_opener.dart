import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/me/organization_detail_page.dart';
import '../pages/profile/profile_page.dart';
import '../services/domain_service.dart';
import '../stores/card_store.dart';
import '../stores/viewer_card_store.dart';

/// 从 resolve 返回的 domain 中提取主页 slug（`https://dinq.me/{slug}` → slug）。
String? extractDinqSlug(String domain) {
  final trimmed = domain.trim();
  if (trimmed.isEmpty) return null;

  Uri? uri;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    uri = Uri.tryParse(trimmed);
  } else if (trimmed.startsWith('/')) {
    uri = Uri.tryParse('https://dinq.me$trimmed');
  } else {
    uri = Uri.tryParse('https://$trimmed');
  }
  if (uri == null) return null;

  final segments =
      uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  return Uri.decodeComponent(segments.first);
}

enum InboxLinkTargetKind { personal, organization, external }

class InboxLinkTarget {
  const InboxLinkTarget._({
    required this.kind,
    required this.value,
  });

  const InboxLinkTarget.personal(String slug)
      : this._(kind: InboxLinkTargetKind.personal, value: slug);

  const InboxLinkTarget.organization(String slug)
      : this._(kind: InboxLinkTargetKind.organization, value: slug);

  const InboxLinkTarget.external(String url)
      : this._(kind: InboxLinkTargetKind.external, value: url);

  final InboxLinkTargetKind kind;
  final String value;
}

/// 根据域名识别结果决定打开目标（纯逻辑，便于单测）。
InboxLinkTarget decideInboxLinkTarget({
  required String originalUrl,
  required DomainResolveResult? result,
}) {
  if (result != null && result.type.isInAppProfile) {
    final slug = extractDinqSlug(
      result.domain.isNotEmpty ? result.domain : originalUrl,
    );
    if (slug != null && slug.isNotEmpty) {
      if (result.type == DomainResolveType.personal) {
        return InboxLinkTarget.personal(slug);
      }
      return InboxLinkTarget.organization(slug);
    }
  }
  return InboxLinkTarget.external(originalUrl);
}

/// Inbox 聊天链接：先调域名识别，personal/organization 走 App 内页，其余外跳。
Future<void> openInboxChatLink(
  BuildContext context,
  String url, {
  DomainService? domainService,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;

  final service = domainService ?? DomainService();
  DomainResolveResult? resolved;
  try {
    resolved = await service.resolve(trimmed);
  } catch (_) {
    resolved = null;
  }

  if (!context.mounted) return;

  final target = decideInboxLinkTarget(
    originalUrl: trimmed,
    result: resolved,
  );

  switch (target.kind) {
    case InboxLinkTargetKind.personal:
      await _openPersonalProfile(context, target.value);
    case InboxLinkTargetKind.organization:
      await _openOrganization(context, target.value);
    case InboxLinkTargetKind.external:
      await _openExternal(target.value);
  }
}

Future<void> _openPersonalProfile(BuildContext context, String username) async {
  final viewerCardStore = context.read<ViewerCardStore>();
  await Navigator.of(context).push<Object?>(
    MaterialPageRoute<Object?>(
      builder: (_) => ChangeNotifierProvider<CardStore>.value(
        value: viewerCardStore,
        child: ProfilePage(username: username, showAppBar: true),
      ),
    ),
  );
}

Future<void> _openOrganization(BuildContext context, String slug) async {
  await Navigator.of(context).push<Object?>(
    MaterialPageRoute<Object?>(
      builder: (_) => OrganizationDetailPage(org: {'slug': slug}),
    ),
  );
}

Future<void> _openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
