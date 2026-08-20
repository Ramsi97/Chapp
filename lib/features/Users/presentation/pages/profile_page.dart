import 'package:dartz/dartz.dart' hide State;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../../Auth/presentation/bloc/auth_bloc.dart';
import '../../../Chat/domain/use_cases/get_or_create_direct_chat_use_case.dart';
import '../../../Chat/presentation/pages/chat_page.dart';
import '../../domain/use_cases/update_presence_use_case.dart';
import '../../domain/use_cases/watch_user_use_case.dart';
import 'edit_profile_page.dart';

/// Shows a user's profile. When [isSelf] it offers edit + logout; otherwise a
/// button to start messaging them. Presence stays live via a user stream.
class ProfilePage extends StatefulWidget {
  final String uid;
  final bool isSelf;
  const ProfilePage({super.key, required this.uid, required this.isSelf});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Stream<Either<Failure, RegisteredUserEntity>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = di.sl<WatchUserUseCase>()(WatchUserParams(uid: widget.uid));
  }

  Future<void> _logout() async {
    final auth = di.sl<FirebaseAuth>();
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      await di.sl<UpdatePresenceUseCase>()(
        UpdatePresenceParams(uid: uid, isOnline: false),
      );
    }
    if (!mounted) return;
    context.read<AuthBloc>().add(AuthLogout());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _message(RegisteredUserEntity user) async {
    final myUid = di.sl<FirebaseAuth>().currentUser?.uid;
    if (myUid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await di.sl<GetOrCreateDirectChatUseCase>()(
      GetOrCreateDirectChatParams(myUid: myUid, otherUid: user.userId),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (chat) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatPage(chat: chat, myUid: myUid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelf ? 'My profile' : 'Profile'),
        actions: [
          if (widget.isSelf)
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: StreamBuilder<Either<Failure, RegisteredUserEntity>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!.fold((_) => null, (u) => u);
          if (user == null || user.userId.isEmpty) {
            return const Center(child: Text('User not found'));
          }

          final present = isUserPresent(user.isOnline, user.lastActiveAt);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                UserAvatar(
                  name: user.name,
                  photoUrl: user.profilePic,
                  radius: 56,
                  showPresence: true,
                  isOnline: present,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  formatPresence(user.isOnline, user.lastActiveAt),
                  style: TextStyle(
                    color: present
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  _InfoCard(title: 'About', body: user.bio!),
                  const SizedBox(height: 12),
                ],
                _InfoCard(title: 'Phone', body: user.phoneNumber),
                const SizedBox(height: 28),
                if (widget.isSelf)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit profile'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(user: user),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message'),
                      onPressed: () => _message(user),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
