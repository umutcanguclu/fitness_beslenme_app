import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/chat_api.dart';
import '../models/chat.dart';
import '../storage/token_storage.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatApi chatApi;
  final TokenStorage tokenStorage;
  final String threadId;
  final String currentUserId;
  final String otherPartyName;

  const ChatRoomScreen({
    super.key,
    required this.chatApi,
    required this.tokenStorage,
    required this.threadId,
    required this.currentUserId,
    required this.otherPartyName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  String? _error;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  WebSocketChannel? _socket;
  StreamSubscription? _socketSub;
  Timer? _reconnectTimer;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _load();
    _markRead();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _socketSub?.cancel();
    _socket?.sink.close();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    final tokens = await widget.tokenStorage.read();
    if (tokens == null) return;
    final wsBase = apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsBase/ws/chat?threadId=${widget.threadId}&token=${tokens.accessToken}');
    try {
      final channel = WebSocketChannel.connect(uri);
      _socket = channel;
      _socketSub = channel.stream.listen(
        _onWsMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
      if (mounted) setState(() => _wsConnected = true);
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    setState(() => _wsConnected = false);
    _socketSub?.cancel();
    _socket?.sink.close();
    _socket = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _connectWebSocket();
    });
  }

  void _onWsMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      if (json['type'] == 'message') {
        final msg = ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
        if (!_messages.any((m) => m.id == msg.id)) {
          if (!mounted) return;
          setState(() => _messages = [..._messages, msg]);
          _scrollToBottom();
          if (msg.senderId != widget.currentUserId) _markRead();
        }
      }
    } catch (_) {/* ignore malformed */}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await widget.chatApi.listMessages(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markRead() async {
    try {
      await widget.chatApi.markRead(widget.threadId);
    } catch (_) {/* silent */}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await widget.chatApi.sendMessage(widget.threadId, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, msg];
        _inputCtrl.clear();
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherPartyName),
        bottom: _wsConnected
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Container(
                  width: double.infinity,
                  color: theme.colorScheme.errorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('Bağlantı yok — yeniden deneniyor…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.onErrorContainer)),
                ),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _messages.isEmpty
                        ? Center(
                            child: Text('Henüz mesaj yok',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant)))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) {
                              final m = _messages[i];
                              final mine = m.senderId == widget.currentUserId;
                              return _Bubble(message: m, mine: mine);
                            },
                          ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = mine ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final fg = mine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final time = _formatTime(message.sentAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.body, style: TextStyle(color: fg, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: TextStyle(
                          color: fg.withValues(alpha: 0.7), fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
