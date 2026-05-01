class ExerciseSummary {
  final String id;
  final String slug;
  final String nameTr;
  final String nameEn;
  final String category;
  final String? description;
  final List<String> requiredEquipment;
  final String? thumbnailUrl;

  const ExerciseSummary({
    required this.id,
    required this.slug,
    required this.nameTr,
    required this.nameEn,
    required this.category,
    this.description,
    this.requiredEquipment = const [],
    this.thumbnailUrl,
  });

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) => ExerciseSummary(
        id: json['id'] as String,
        slug: json['slug'] as String,
        nameTr: json['nameTr'] as String,
        nameEn: json['nameEn'] as String? ?? '',
        category: json['category'] as String,
        description: json['description'] as String?,
        requiredEquipment: (json['requiredEquipment'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}
