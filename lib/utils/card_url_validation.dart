import '../services/card_service.dart';
import '../widgets/cards/factory/card_registry.dart';
import '../widgets/cards/factory/definitions/index.dart';

class ValidatedCardUrl {
  const ValidatedCardUrl({
    required this.type,
    required this.url,
    this.rawType = '',
  });

  final String type;
  final String url;
  final String rawType;
}

String extractUrlFromInput(String input) {
  if (input.isEmpty) return '';

  var url = input.trim();

  if (input.contains('<iframe')) {
    final doubleQuotePattern = RegExp(r'src="([^"]+)"');
    var match = doubleQuotePattern.firstMatch(input);
    match ??= RegExp(r"src='([^']+)'").firstMatch(input);
    final extracted = match?.group(1);
    if (extracted != null && extracted.isNotEmpty) {
      url = extracted;
    }
  } else if (input.contains('data-url=')) {
    final doubleQuotePattern = RegExp(r'data-url="([^"]+)"');
    var match = doubleQuotePattern.firstMatch(input);
    match ??= RegExp(r"data-url='([^']+)'").firstMatch(input);
    final extracted = match?.group(1);
    if (extracted != null && extracted.isNotEmpty) {
      url = extracted;
    }
  }

  if (url.startsWith('//')) {
    url = 'https:$url';
  }
  if (!url.startsWith(RegExp(r'^https?://', caseSensitive: false))) {
    url = 'https://$url';
  }
  return url;
}

bool isValidUrl(String urlString) {
  try {
    final uri = Uri.parse(urlString);
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final hostname = uri.host;
    if (hostname.isEmpty) return false;
    if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(hostname)) return false;
    final parts = hostname.split('.');
    if (parts.any((part) => part.isEmpty)) return false;
    final hasNonNumericPart = parts.any(
      (part) => !RegExp(r'^\d+$').hasMatch(part),
    );
    if (!hasNonNumericPart) return false;
    if (parts.length < 2) return false;
    if (RegExp(r'^\d+$').hasMatch(parts.last)) return false;
    return true;
  } catch (_) {
    return false;
  }
}

String? _detectTypeLocally(String urlString) {
  try {
    final url =
        urlString.startsWith(RegExp(r'^https?://', caseSensitive: false))
        ? urlString
        : 'https://$urlString';
    final host = Uri.parse(url).host.toLowerCase();
    if (host.contains('linkedin.com')) return 'LINKEDIN';
    if (host.contains('github.com')) return 'GITHUB';
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return 'TWITTER';
    }
    if (host.contains('scholar.google')) return 'SCHOLAR';
    if (host.contains('openreview.net')) return 'OPENREVIEW';
    if (host.contains('huggingface.co')) return 'HUGGINGFACE';
    if (host.contains('medium.com')) return 'MEDIUM';
    if (host.contains('substack.com')) return 'SUBSTACK';
    if (host.contains('behance.net')) return 'BEHANCE';
    if (host.contains('discord.com') || host.contains('discord.gg')) {
      return 'DISCORD';
    }
    if (host.contains('facebook.com')) return 'FACEBOOK';
    if (host.contains('instagram.com')) return 'INSTAGRAM';
    if (host.contains('open.spotify.com') || host.contains('spotify.com')) {
      return 'SPOTIFY';
    }
    if (host.contains('t.me') || host.contains('telegram.org')) {
      return 'TELEGRAM';
    }
    if (host.contains('tiktok.com')) return 'TIKTOK';
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return 'YOUTUBE';
    }
    if (host.contains('bilibili.com') || host.contains('b23.tv')) {
      return 'BILIBILI';
    }
    if (host.contains('reddit.com')) return 'REDDIT';
    if (host.contains('threads.net')) return 'THREADS';
    if (host.contains('bsky.app')) return 'BLUESKY';
    return null;
  } catch (_) {
    return null;
  }
}

String _resolveCardType(String rawType) {
  final upper = rawType.trim().toUpperCase();
  if (upper.isEmpty) return 'LINK';
  final registry = CardRegistry();
  if (registry.isRegistered(upper)) return upper;
  if (isSocialCard(upper)) return upper;
  return 'LINK';
}

Future<ValidatedCardUrl> validateCardUrlInput(
  String rawInput, {
  CardService? cardService,
}) async {
  final inputUrl = extractUrlFromInput(rawInput).trim();
  if (inputUrl.isEmpty) {
    throw Exception('URL cannot be empty');
  }
  if (!isValidUrl(inputUrl)) {
    throw Exception('Please enter a valid URL');
  }

  final service = cardService ?? CardService();
  try {
    final response = await service.validateUrl(url: inputUrl);
    final rawType = response['type']?.toString().trim().toUpperCase() ?? 'LINK';
    final type = _resolveCardType(rawType);
    return ValidatedCardUrl(
      type: type,
      url: response['url']?.toString() ?? inputUrl,
      rawType: response['type']?.toString() ?? '',
    );
  } catch (_) {
    final detected = _detectTypeLocally(inputUrl) ?? 'LINK';
    if (detected == 'LINKEDIN' && !inputUrl.contains('/in/')) {
      throw Exception(
        'LinkedIn profile URL should be in format: linkedin.com/in/username',
      );
    }
    return ValidatedCardUrl(type: detected, url: inputUrl);
  }
}

String platformNameForType(String type) {
  final upper = type.toUpperCase();
  for (final def in socialCards) {
    if (def.type.toUpperCase() == upper) return def.name;
  }
  return upper;
}

String stripUrlScheme(String url) =>
    url.replaceFirst(RegExp(r'^https?://'), '');
