import 'liturgy.dart';

final class LiturgyContent {
  const LiturgyContent({required this.liturgy, required this.sections});

  final Liturgy liturgy;
  final List<LiturgySection> sections;

  factory LiturgyContent.fromJson(Map<String, dynamic> json) {
    final liturgyJson = json['liturgy'];

    if (liturgyJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid liturgy content');
    }

    final sectionsJson = json['sections'];

    return LiturgyContent(
      liturgy: Liturgy.fromJson(liturgyJson),
      sections: sectionsJson is List
          ? List.unmodifiable(
              sectionsJson.map((item) {
                if (item is! Map<String, dynamic>) {
                  throw const FormatException('Invalid section');
                }

                return LiturgySection.fromJson(item);
              }),
            )
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'liturgy': liturgy.toJson(),
    'sections': sections.map((section) => section.toJson()).toList(),
  };
}

final class LiturgySection {
  const LiturgySection({
    required this.id,
    required this.liturgyId,
    required this.order,
    required this.title,
    required this.titleAm,
    required this.verses,
    this.audioUrl,
    this.audioDurationMs,
    this.audioSizeBytes,
    this.audioMimeType,
    this.audioSha256,
  });

  final int id;
  final int liturgyId;
  final int order;
  final String title;
  final String titleAm;
  final String? audioUrl;
  final int? audioDurationMs;
  final int? audioSizeBytes;
  final String? audioMimeType;
  final String? audioSha256;
  final List<Verse> verses;

  factory LiturgySection.fromJson(Map<String, dynamic> json) {
    final versesJson = json['verses'];

    return LiturgySection(
      id: json['id'] as int,
      liturgyId: json['liturgy_id'] as int,
      order: json['order'] as int,
      title: json['title'] as String,
      titleAm: json['title_am'] as String,
      audioUrl: json['audio_url'] as String?,
      audioDurationMs: json['audio_duration_ms'] as int?,
      audioSizeBytes: json['audio_size_bytes'] as int?,
      audioMimeType: json['audio_mime_type'] as String?,
      audioSha256: json['audio_sha256'] as String?,
      verses: versesJson is List
          ? List.unmodifiable(
              versesJson.map((item) {
                if (item is! Map<String, dynamic>) {
                  throw const FormatException('Invalid verse');
                }

                return Verse.fromJson(item);
              }),
            )
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'liturgy_id': liturgyId,
    'order': order,
    'title': title,
    'title_am': titleAm,
    'audio_url': audioUrl,
    'audio_duration_ms': audioDurationMs,
    'audio_size_bytes': audioSizeBytes,
    'audio_mime_type': audioMimeType,
    'audio_sha256': audioSha256,
    'verses': verses.map((verse) => verse.toJson()).toList(),
  };
}

final class Verse {
  const Verse({
    required this.id,
    required this.order,
    required this.textGeez,
    required this.textAm,
    required this.textEn,
    required this.role,
    this.startMs,
    this.endMs,
    this.sourcePage,
    this.sourcePart,
    this.sourceKind,
    this.sourceNote,
    this.sourceNeedsReview = false,
  });

  final int id;
  final int order;
  final String textGeez;
  final String textAm;
  final String textEn;
  final String role;
  final int? startMs;
  final int? endMs;
  final int? sourcePage;
  final String? sourcePart;
  final String? sourceKind;
  final String? sourceNote;
  final bool sourceNeedsReview;

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as int,
      order: json['order'] as int,
      textGeez: json['text_geez'] as String,
      textAm: json['text_am'] as String,
      textEn: json['text_en'] as String,
      role: json['role'] as String,
      startMs: json['start_ms'] as int?,
      endMs: json['end_ms'] as int?,
      sourcePage: json['source_page'] as int?,
      sourcePart: json['source_part'] as String?,
      sourceKind: json['source_kind'] as String?,
      sourceNote: json['source_note'] as String?,
      sourceNeedsReview: json['source_needs_review'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'text_geez': textGeez,
    'text_am': textAm,
    'text_en': textEn,
    'role': role,
    'start_ms': startMs,
    'end_ms': endMs,
    'source_page': sourcePage,
    'source_part': sourcePart,
    'source_kind': sourceKind,
    'source_note': sourceNote,
    'source_needs_review': sourceNeedsReview,
  };
}
