import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../services/meta_video_service.dart';
import '../usage/ai_quota_service.dart';

/// Video understanding via Muse Spark (Meta Model API, Responses API).
/// Accepts direct public mp4 URLs; YouTube watch pages are resolved to
/// playable media separately.
class VideoEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Summarizes the footage and its embedded speech, with timestamped
  /// chapters for jumping back into the parts worth practicing.
  Future<String> describeVideo(
    Session session,
    String videoUrl,
    String language,
  ) async {
    await AiQuotaService.consume(session, 'import');
    final video = MetaVideoService(
      apiKey: session.serverpod.getPassword('metaApiKey') ?? '',
    );
    final result = await video.describeVideo(videoUrl, language: language);
    return jsonEncode({...result, 'provider': 'meta'});
  }
}
