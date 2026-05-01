class PlayerAvailability {
  final String id;
  final String playerId;
  final DateTime date;
  final String status; // ready/doubtful/limited/injured/ill/suspended/away
  final String? note;

  const PlayerAvailability({
    required this.id,
    required this.playerId,
    required this.date,
    required this.status,
    this.note,
  });

  factory PlayerAvailability.fromJson(Map<String, dynamic> json) => PlayerAvailability(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: json['status'] as String,
        note: json['note'] as String?,
      );
}

class InjuryRecord {
  final String id;
  final String playerId;
  final String type;     // muscle/ligament/joint/bone/tendon/concussion/other
  final String severity; // minor/moderate/major/severe
  final String bodyPart;
  final DateTime startedAt;
  final DateTime? expectedReturn;
  final DateTime? resolvedAt;
  final String? description;

  const InjuryRecord({
    required this.id,
    required this.playerId,
    required this.type,
    required this.severity,
    required this.bodyPart,
    required this.startedAt,
    this.expectedReturn,
    this.resolvedAt,
    this.description,
  });

  bool get isActive => resolvedAt == null;

  factory InjuryRecord.fromJson(Map<String, dynamic> json) => InjuryRecord(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        type: json['type'] as String,
        severity: json['severity'] as String,
        bodyPart: json['bodyPart'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        expectedReturn: json['expectedReturn'] != null
            ? DateTime.tryParse(json['expectedReturn'] as String)
            : null,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'] as String)
            : null,
        description: json['description'] as String?,
      );
}

class PerformanceTest {
  final String id;
  final String playerId;
  final String type;     // sprint_10m, vertical_jump, etc.
  final num value;
  final String unit;     // 's', 'cm', 'kg', '%', ...
  final DateTime testedAt;
  final String? notes;

  const PerformanceTest({
    required this.id,
    required this.playerId,
    required this.type,
    required this.value,
    required this.unit,
    required this.testedAt,
    this.notes,
  });

  factory PerformanceTest.fromJson(Map<String, dynamic> json) => PerformanceTest(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        type: json['type'] as String,
        value: json['value'] as num,
        unit: json['unit'] as String,
        testedAt: DateTime.parse(json['testedAt'] as String),
        notes: json['notes'] as String?,
      );
}
