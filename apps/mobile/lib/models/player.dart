class Player {
  final String id;
  final String clubId;
  final String fullName;
  final String position;          // 'goalkeeper' | 'defender' | 'midfielder' | 'forward'
  final String? detailedPosition; // 'cb', 'lb', 'cm', 'st', ...
  final String preferredFoot;     // 'left' | 'right' | 'both'
  final num? heightCm;
  final num? weightKg;
  final int? jerseyNumber;
  final String employmentStatus;  // 'amateur' | 'pro' | ...
  final DateTime? birthDate;

  const Player({
    required this.id,
    required this.clubId,
    required this.fullName,
    required this.position,
    this.detailedPosition,
    required this.preferredFoot,
    this.heightCm,
    this.weightKg,
    this.jerseyNumber,
    required this.employmentStatus,
    this.birthDate,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        clubId: json['clubId'] as String,
        fullName: (json['fullName'] as String?) ?? '—',
        position: (json['position'] as String?) ?? 'midfielder',
        detailedPosition: json['detailedPosition'] as String?,
        preferredFoot: (json['preferredFoot'] as String?) ?? 'right',
        heightCm: json['heightCm'] as num?,
        weightKg: json['weightKg'] as num?,
        jerseyNumber: json['jerseyNumber'] as int?,
        employmentStatus: (json['employmentStatus'] as String?) ?? 'amateur',
        birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      );
}

class TeamPlayer {
  final String teamId;
  final Player player;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  const TeamPlayer({
    required this.teamId,
    required this.player,
    this.joinedAt,
    this.leftAt,
  });

  factory TeamPlayer.fromJson(Map<String, dynamic> json) => TeamPlayer(
        teamId: json['teamId'] as String,
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
        joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'] as String) : null,
        leftAt: json['leftAt'] != null ? DateTime.tryParse(json['leftAt'] as String) : null,
      );
}
