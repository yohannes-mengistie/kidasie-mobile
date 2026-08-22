final class Liturgy {
  const Liturgy({
    required this.id,
    required this.slug,
    required this.name,
    required this.nameAm,
    required this.contentVersion,
  });

  final int id;
  final String slug;
  final String name;
  final String nameAm;
  final int contentVersion;

  factory Liturgy.fromJson(Map<String, dynamic> json) => Liturgy(
    id: json['id'] as int,
    slug: json['slug'] as String,
    name: json['name'] as String,
    nameAm: json['name_am'] as String,
    contentVersion: json['content_version'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'name_am': nameAm,
    'content_version': contentVersion,
  };
}
