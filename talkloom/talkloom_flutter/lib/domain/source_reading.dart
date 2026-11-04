class SourceReadingSegment {
  const SourceReadingSegment({
    required this.id,
    required this.original,
    required this.translation,
  });
  final int id;
  final String original;
  final String translation;
}

class SourceReadingBatch {
  const SourceReadingBatch({
    required this.mode,
    required this.language,
    required this.total,
    required this.segments,
    required this.done,
  });
  final String mode;
  final String language;
  final int total;
  final List<SourceReadingSegment> segments;
  final bool done;

  factory SourceReadingBatch.fromJson(Map<String, dynamic> data) {
    if (data['mode'] is! String ||
        data['language'] is! String ||
        data['total'] is! int ||
        data['segments'] is! List ||
        data['done'] is! bool) {
      throw const FormatException('Invalid reading response');
    }
    final total = data['total'] as int;
    if (total < 0) throw const FormatException('Invalid reading size');
    final segments = <SourceReadingSegment>[];
    final seen = <int>{};
    for (final segment in data['segments'] as List) {
      if (segment is! Map ||
          segment['id'] is! int ||
          segment['original'] is! String ||
          segment['translation'] is! String) {
        throw const FormatException('Invalid reading segment');
      }
      final id = segment['id'] as int;
      if (id < 0 || id >= total || !seen.add(id)) {
        throw const FormatException('Invalid segment order');
      }
      segments.add(
        SourceReadingSegment(
          id: id,
          original: segment['original'] as String,
          translation: segment['translation'] as String,
        ),
      );
    }
    return SourceReadingBatch(
      mode: data['mode'] as String,
      language: data['language'] as String,
      total: total,
      segments: segments,
      done: data['done'] as bool,
    );
  }
}
