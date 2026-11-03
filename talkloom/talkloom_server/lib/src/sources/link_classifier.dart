/// Where a shared link comes from and who made it. Used to categorise cached
/// analyses and a learner's sources by provider and creator.
abstract final class LinkPlatform {
  static const youtube = 'youtube';
  static const instagram = 'instagram';
  static const tiktok = 'tiktok';
  static const reddit = 'reddit';
  static const x = 'x';
  static const facebook = 'facebook';
  static const web = 'web';

  /// Content that did not arrive as a link.
  static const text = 'text';
  static const document = 'document';
  static const image = 'image';
}

class LinkClassification {
  const LinkClassification({required this.platform, this.creator});

  final String platform;

  /// Channel, account or subreddit as displayed; null when it is unknown.
  final String? creator;

  /// Lower-cased creator used for lookups, so "DW Deutsch" and "dw deutsch"
  /// land in one category.
  String? get creatorKey {
    final value = creator?.trim().toLowerCase();
    return value == null || value.isEmpty ? null : value;
  }

  /// How long an analysis stays valid. Videos do not change under a link;
  /// threads and pages do.
  Duration? get timeToLive => switch (platform) {
    LinkPlatform.youtube ||
    LinkPlatform.instagram ||
    LinkPlatform.tiktok => null,
    LinkPlatform.web => const Duration(days: 30),
    _ => const Duration(days: 14),
  };
}

abstract final class LinkClassifier {
  static const _hosts = {
    'youtube.com': LinkPlatform.youtube,
    'youtu.be': LinkPlatform.youtube,
    'instagram.com': LinkPlatform.instagram,
    'tiktok.com': LinkPlatform.tiktok,
    'reddit.com': LinkPlatform.reddit,
    'redd.it': LinkPlatform.reddit,
    'x.com': LinkPlatform.x,
    'twitter.com': LinkPlatform.x,
    'facebook.com': LinkPlatform.facebook,
    'fb.watch': LinkPlatform.facebook,
  };

  static String platformOf(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    for (final entry in _hosts.entries) {
      if (host == entry.key || host.endsWith('.${entry.key}')) {
        return entry.value;
      }
    }
    return LinkPlatform.web;
  }

  /// Classifies [url]. [transcript] is the extracted text, which carries the
  /// channel name for YouTube (`[YouTube Video: title by channel | ...]`).
  static LinkClassification classify(String url, {String? transcript}) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return const LinkClassification(platform: LinkPlatform.web);
    }
    final platform = platformOf(uri);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    String? creator;
    switch (platform) {
      case LinkPlatform.youtube:
        creator = _youTubeAuthor(transcript);
      case LinkPlatform.tiktok:
        creator = segments.firstOrNull?.startsWith('@') == true
            ? segments.first.substring(1)
            : null;
      case LinkPlatform.reddit:
        creator = segments.length >= 2 && segments.first == 'r'
            ? 'r/${segments[1]}'
            : null;
      case LinkPlatform.instagram:
      case LinkPlatform.x:
      case LinkPlatform.facebook:
        const reserved = {'p', 'reel', 'reels', 'tv', 'stories', 'share', 'i'};
        final first = segments.firstOrNull;
        creator = first != null && !reserved.contains(first) ? first : null;
      default:
        creator = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    }
    return LinkClassification(platform: platform, creator: creator);
  }

  static String? _youTubeAuthor(String? transcript) {
    if (transcript == null) return null;
    final header = RegExp(
      r'^\[YouTube Video:\s*(.*?)\s+by\s+([^\]|]*?)\s*(?:\||\])',
      multiLine: true,
    ).firstMatch(transcript);
    final author = header?.group(2)?.trim();
    return author == null || author.isEmpty ? null : author;
  }
}
