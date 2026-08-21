import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../../Chat/domain/use_cases/get_or_create_direct_chat_use_case.dart';
import '../../../Chat/presentation/pages/chat_page.dart';
import '../../../Chat/presentation/pages/new_group_page.dart';
import '../bloc/users_bloc.dart';

/// A searchable list of every registered user. Tapping one opens (or creates)
/// a direct chat with them.
class NewChatPage extends StatelessWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = di.sl<FirebaseAuth>().currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return BlocProvider(
      create: (_) => di.sl<UsersBloc>()..add(UsersLoadRequested(myUid)),
      child: _NewChatView(myUid: myUid),
    );
  }
}

class _NewChatView extends StatefulWidget {
  final String myUid;
  const _NewChatView({required this.myUid});

  @override
  State<_NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends State<_NewChatView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _startDirectChat(RegisteredUserEntity user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await di.sl<GetOrCreateDirectChatUseCase>()(
      GetOrCreateDirectChatParams(myUid: widget.myUid, otherUid: user.userId),
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss the spinner

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (chat) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatPage(chat: chat, myUid: widget.myUid),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) =>
                  context.read<UsersBloc>().add(UsersSearchChanged(v)),
              decoration: const InputDecoration(
                hintText: 'Search by name or @username',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          ListTile(
            leading: const UserAvatar(
              name: '',
              radius: 24,
              fallbackIcon: Icons.group_add,
            ),
            title: const Text(
              'New group',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewGroupPage()),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoading || state is UsersInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UsersError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                  );
                }
                final loaded = state as UsersLoaded;
                if (loaded.filtered.isEmpty) {
                  return Center(
                    child: Text(
                      loaded.all.isEmpty
                          ? 'No other users yet'
                          : 'No matches',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: loaded.filtered.length,
                  itemBuilder: (context, index) {
                    final user = loaded.filtered[index];
                    return ListTile(
                      leading: UserAvatar(
                        name: user.name,
                        photoUrl: user.profilePic,
                        radius: 24,
                        showPresence: true,
                        isOnline:
                            isUserPresent(user.isOnline, user.lastActiveAt),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('@${user.username}'),
                      onTap: () => _startDirectChat(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
