class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['threadId'] as String,
        senderId: json['senderId'] as String,
        body: json['body'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}

class ChatThreadSummary {
  final String id;
  final String clubId;
  final String coachId;
  final String playerId;
  final String otherPartyName;
  final String otherPartyRole; // 'coach' | 'player'
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ChatThreadSummary({
    required this.id,
    required this.clubId,
    required this.coachId,
    required this.playerId,
    required this.otherPartyName,
    required this.otherPartyRole,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatThreadSummary.fromJson(Map<String, dynamic> json) => ChatThreadSummary(
        id: json['id'] as String,
        clubId: json['clubId'] as String,
        coachId: json['coachId'] as String,
        playerId: json['playerId'] as String,
        otherPartyName: json['otherPartyName'] as String,
        otherPartyRole: json['otherPartyRole'] as String,
        lastMessage: json['lastMessage'] != null
            ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        unreadCount: (json['unreadCount'] as num).toInt(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class ChatThread {
  final String id;
  final String clubId;
  final String coachId;
  final String playerId;

  const ChatThread({
    required this.id,
    required this.clubId,
    required this.coachId,
    required this.playerId,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        clubId: json['clubId'] as String,
        coachId: json['coachId'] as String,
        playerId: json['playerId'] as String,
      );
}
