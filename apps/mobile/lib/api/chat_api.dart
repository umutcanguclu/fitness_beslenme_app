import 'package:dio/dio.dart';
import '../models/chat.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ChatApi {
  final ApiClient client;
  ChatApi(this.client);

  Future<List<ChatThreadSummary>> listThreads() async {
    try {
      final res = await client.dio.get('/chat/threads');
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list
          .map((e) => ChatThreadSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ChatThread> startThreadWithPlayer(String playerId) async {
    try {
      final res = await client.dio.post('/chat/threads', data: {'playerId': playerId});
      ensureOk(res);
      return ChatThread.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<ChatMessage>> listMessages(String threadId, {DateTime? before, int limit = 50}) async {
    try {
      final res = await client.dio.get('/chat/threads/$threadId/messages',
          queryParameters: {
            if (before != null) 'before': before.toIso8601String(),
            'limit': limit,
          });
      ensureOk(res);
      final list = res.data as List<dynamic>;
      final items = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return items;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ChatMessage> sendMessage(String threadId, String body) async {
    try {
      final res = await client.dio
          .post('/chat/threads/$threadId/messages', data: {'body': body});
      ensureOk(res);
      return ChatMessage.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> markRead(String threadId) async {
    try {
      final res = await client.dio.post('/chat/threads/$threadId/read');
      ensureOk(res);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
