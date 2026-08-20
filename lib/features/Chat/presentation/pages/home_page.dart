import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Users/presentation/pages/new_chat_page.dart';
import '../../../Users/presentation/pages/profile_page.dart';
import '../../domain/entity/chat_entity.dart';
import '../bloc/chat_list_bloc.dart';
import '../widgets/chat_tile.dart';
import 'chat_page.dart';
import 'new_group_page.dart';

/// The app's landing screen once authenticated: a live list of conversations.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = di.sl<FirebaseAuth>().currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return BlocProvider(
      create: (_) =>
          di.sl<ChatListBloc>()..add(ChatListSubscriptionRequested(myUid)),
      child: _HomeView(myUid: myUid),
    );
  }
}

class _HomeView extends StatelessWidget {
  final String myUid;
  const _HomeView({required this.myUid});

  void _openChat(BuildContext context, ChatEntity chat) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatPage(chat: chat, myUid: myUid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'New group',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewGroupPage()),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfilePage(uid: myUid, isSelf: true),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewChatPage()),
        ),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          switch (state.status) {
            case ChatListStatus.initial:
            case ChatListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ChatListStatus.error:
              return _ErrorView(message: state.error ?? 'Something went wrong');
            case ChatListStatus.loaded:
              if (state.chats.isEmpty) return const _EmptyView();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.chats.length,
                separatorBuilder: (_, _) =>
                    const Divider(indent: 84, height: 1),
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  return ChatTile(
                    chat: chat,
                    myUid: myUid,
                    onTap: () => _openChat(context, chat),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UserAvatar(
              name: '',
              radius: 40,
              fallbackIcon: Icons.forum_outlined,
            ),
            const SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
