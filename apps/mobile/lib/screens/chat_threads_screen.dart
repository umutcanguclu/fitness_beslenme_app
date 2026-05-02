import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/chat_api.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import '../util/labels.dart';
import 'chat_room_screen.dart';

class ChatThreadsScreen extends StatefulWidget {
  final ChatApi chatApi;
  final TokenStorage tokenStorage;
  final User currentUser;
  const ChatThreadsScreen({
    super.key,
    required this.chatApi,
    required this.tokenStorage,
    required this.currentUser,
  });

  @override
  State<ChatThreadsScreen> createState() => _ChatThreadsScreenState();
}

class _ChatThreadsScreenState extends State<ChatThreadsScreen> {
  Future<List<ChatThreadSummary>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = widget.chatApi.listThreads();
    });
  }

  Future<void> _open(ChatThreadSummary t) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatRoomScreen(
        chatApi: widget.chatApi,
        tokenStorage: widget.tokenStorage,
        threadId: t.id,
        currentUserId: widget.currentUser.id,
        otherPartyName: t.otherPartyName,
      ),
    ));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<ChatThreadSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final msg = snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : snap.error.toString();
              return ListView(padding: const EdgeInsets.all(24), children: [Text(msg)]);
            }
            final list = snap.data ?? const <ChatThreadSummary>[];
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64),
                  const SizedBox(height: 16),
                  Text('Henüz mesaj yok',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    widget.currentUser.isCoach
                        ? 'Bir oyuncuya gir → bottom sheet → "Mesaj gönder" ile sohbet başlat.'
                        : 'Antrenörün sana mesaj atınca burada görünür.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _ThreadTile(thread: list[i], onTap: () => _open(list[i])),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThreadSummary thread;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMsg = thread.lastMessage;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          thread.otherPartyName.characters.first.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(thread.otherPartyName)),
          Text(roleLabel(thread.otherPartyRole),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      subtitle: lastMsg != null
          ? Text(lastMsg.body, maxLines: 1, overflow: TextOverflow.ellipsis)
          : Text('Henüz mesaj yok',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      trailing: thread.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${thread.unreadCount}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )),
            )
          : Text(_relativeTime(thread.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
      onTap: onTap,
    );
  }
}

String _relativeTime(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
  if (diff.inHours < 24) return '${diff.inHours}s';
  if (diff.inDays < 7) return '${diff.inDays}g';
  return formatDate(d);
}
