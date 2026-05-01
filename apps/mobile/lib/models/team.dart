class Team {
  final String id;
  final String clubId;
  final String name;
  final String category; // U13..U21, A_team, B_team, ...
  final String season;   // "2026-2027"
  final bool active;

  const Team({
    required this.id,
    required this.clubId,
    required this.name,
    required this.category,
    required this.season,
    required this.active,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        clubId: json['clubId'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        season: json['season'] as String,
        active: (json['active'] as bool?) ?? true,
      );
}
