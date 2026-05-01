class Invite {
  final String id;
  final String code;
  final String clubId;
  final String? teamId;
  final String? email;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  const Invite({
    required this.id,
    required this.code,
    required this.clubId,
    this.teamId,
    this.email,
    required this.expiresAt,
    this.acceptedAt,
  });

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
        id: json['id'] as String,
        code: json['code'] as String,
        clubId: json['clubId'] as String,
        teamId: json['teamId'] as String?,
        email: json['email'] as String?,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.tryParse(json['acceptedAt'] as String)
            : null,
      );
}

class CreatePlayerResult {
  final String playerId;
  final String fullName;
  final Invite invite;

  const CreatePlayerResult({
    required this.playerId,
    required this.fullName,
    required this.invite,
  });

  factory CreatePlayerResult.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>;
    return CreatePlayerResult(
      playerId: player['id'] as String,
      fullName: player['fullName'] as String,
      invite: Invite.fromJson(json['invite'] as Map<String, dynamic>),
    );
  }
}
