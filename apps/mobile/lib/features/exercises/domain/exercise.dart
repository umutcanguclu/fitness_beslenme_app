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
  });

  final String id;
  final String nameEn;
  final String nameTr;
  final List<String> muscleGroup;
  final List<String> equipment;
  final String type;

  String nameFor(String languageCode) => languageCode == 'tr' ? nameTr : nameEn;

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
      );
}

final exerciseCatalogProvider = FutureProvider<List<Exercise>>((ref) async {
  final raw = await rootBundle.loadString('assets/exercises.json');
  final list = json.decode(raw) as List<dynamic>;
  return list
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
});
