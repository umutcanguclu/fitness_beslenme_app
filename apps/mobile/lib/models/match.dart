class Match {
  final String id;
  final String teamId;
  final String opponent;
  final DateTime date;
  final bool isHome;
  final String? competition;
  final int? scoreUs;
  final int? scoreThem;
  final String? notes;

  const Match({
    required this.id,
    required this.teamId,
    required this.opponent,
    required this.date,
    required this.isHome,
    this.competition,
    this.scoreUs,
    this.scoreThem,
    this.notes,
  });

  bool get hasScore => scoreUs != null && scoreThem != null;
  bool get isPast => date.isBefore(DateTime.now());

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        opponent: json['opponent'] as String,
        date: DateTime.parse(json['date'] as String),
        isHome: (json['isHome'] as bool?) ?? false,
        competition: json['competition'] as String?,
        scoreUs: (json['scoreUs'] as num?)?.toInt(),
        scoreThem: (json['scoreThem'] as num?)?.toInt(),
        notes: json['notes'] as String?,
      );
}
