import '../../../core/localization/app_language.dart';

final class Announcement {
  const Announcement({
    required this.id,
    required this.slug,
    required this.version,
    required this.titleAm,
    required this.titleEn,
    required this.bodyAm,
    required this.bodyEn,
    required this.kind,
    required this.action,
    required this.priority,
    required this.isPinned,
    required this.publishedAt,
    required this.updatedAt,
    this.expiresAt,
  });

  final int id;
  final String slug;
  final int version;
  final String titleAm;
  final String titleEn;
  final String bodyAm;
  final String bodyEn;
  final String kind;
  final AnnouncementAction action;
  final int priority;
  final bool isPinned;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final DateTime updatedAt;

  String title(AppLanguage language) => language.isEnglish ? titleEn : titleAm;

  String body(AppLanguage language) => language.isEnglish ? bodyEn : bodyAm;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final actionJson = json['action'];
    return Announcement(
      id: json['id'] as int,
      slug: json['slug'] as String,
      version: json['version'] as int,
      titleAm: json['title_am'] as String,
      titleEn: json['title_en'] as String,
      bodyAm: json['body_am'] as String,
      bodyEn: json['body_en'] as String,
      kind: json['kind'] as String,
      action: actionJson is Map<String, dynamic>
          ? AnnouncementAction.fromJson(actionJson)
          : const AnnouncementAction(type: 'none', value: ''),
      priority: json['priority'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'version': version,
    'title_am': titleAm,
    'title_en': titleEn,
    'body_am': bodyAm,
    'body_en': bodyEn,
    'kind': kind,
    'action': action.toJson(),
    'priority': priority,
    'is_pinned': isPinned,
    'published_at': publishedAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

final class AnnouncementAction {
  const AnnouncementAction({required this.type, required this.value});

  final String type;
  final String value;

  bool get isAvailable => type != 'none' && value.isNotEmpty;

  factory AnnouncementAction.fromJson(Map<String, dynamic> json) =>
      AnnouncementAction(
        type: json['type'] as String? ?? 'none',
        value: json['value'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'type': type, 'value': value};
}
