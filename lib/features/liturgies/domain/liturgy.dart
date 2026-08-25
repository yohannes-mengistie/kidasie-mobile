final class Liturgy {
  const Liturgy({
    required this.id,
    required this.slug,
    required this.name,
    required this.nameAm,
    required this.contentVersion,
    required this.hasContent,
    this.audio,
  });

  final int id;
  final String slug;
  final String name;
  final String nameAm;
  final int contentVersion;
  final bool hasContent;
  final LiturgyAudio? audio;

  bool get hasAudio => audio != null;

  factory Liturgy.fromJson(Map<String, dynamic> json) => Liturgy(
    id: json['id'] as int,
    slug: json['slug'] as String,
    name: json['name'] as String,
    nameAm: json['name_am'] as String,
    contentVersion: json['content_version'] as int,
    hasContent: json['has_content'] as bool? ?? true,
    audio: json['audio'] is Map<String, dynamic>
        ? LiturgyAudio.fromJson(json['audio'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'name_am': nameAm,
    'content_version': contentVersion,
    'has_content': hasContent,
    'audio': audio?.toJson(),
  };
}

final class LiturgyAudio {
  const LiturgyAudio({
    required this.url,
    required this.durationMs,
    required this.sizeBytes,
    required this.mimeType,
    required this.sha256,
  });

  final String url;
  final int durationMs;
  final int sizeBytes;
  final String mimeType;
  final String sha256;

  factory LiturgyAudio.fromJson(Map<String, dynamic> json) => LiturgyAudio(
    url: json['url'] as String,
    durationMs: json['duration_ms'] as int,
    sizeBytes: json['size_bytes'] as int,
    mimeType: json['mime_type'] as String,
    sha256: json['sha256'] as String,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'duration_ms': durationMs,
    'size_bytes': sizeBytes,
    'mime_type': mimeType,
    'sha256': sha256,
  };
}
