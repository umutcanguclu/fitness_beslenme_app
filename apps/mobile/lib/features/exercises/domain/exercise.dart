import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.nameEn,
    required this.nameTr,
    required this.muscleGroup,
    required this.equipment,
    required this.type,
    this.level,
    this.mechanic,
    this.images = const [],
    this.instructionsEn,
  });

  final String id;
  final String nameEn;
  final String nameTr;
  final List<String> muscleGroup;
  final List<String> equipment;
  final String type;
  final String? level;
  final String? mechanic;
  final List<String> images;
  final String? instructionsEn;

  String nameFor(String languageCode) => languageCode == 'tr' ? nameTr : nameEn;

  String? get primaryImage => images.isEmpty ? null : images.first;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameTr: (json['nameTr'] as String?) ?? json['nameEn'] as String,
        muscleGroup: (json['muscleGroup'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        equipment: (json['equipment'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        type: (json['type'] as String?) ?? 'strength',
        level: json['level'] as String?,
        mechanic: json['mechanic'] as String?,
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        instructionsEn: json['instructionsEn'] as String?,
      );
}

final exerciseCatalogProvider = FutureProvider<List<Exercise>>((ref) async {
  final raw = await rootBundle.loadString('assets/exercises.json');
  final list = json.decode(raw) as List<dynamic>;
  return list
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
});
