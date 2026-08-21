import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../../Users/domain/use_cases/watch_user_use_case.dart';
import '../../domain/entity/chat_entity.dart';

/// One row in the chat list. For direct chats it watches the other participant
/// so the name, avatar and presence dot stay live; group chats render straight
/// from the chat document.
class ChatTile extends StatefulWidget {
  final ChatEntity chat;
  final String myUid;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.myUid,
    required this.onTap,
  });

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  Stream<Either<Failure, RegisteredUserEntity>>? _userStream;

  @override
  void initState() {
    super.initState();
    if (!widget.chat.isGroup) {
      final otherUid = widget.chat.otherParticipant(widget.myUid);
      if (otherUid.isNotEmpty) {
        _userStream = di.sl<WatchUserUseCase>()(
          WatchUserParams(uid: otherUid),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chat.isGroup) {
      return _buildTile(
        name: widget.chat.name ?? 'Group',
        photoUrl: widget.chat.photoUrl,
        isOnline: false,
        showPresence: false,
        fallbackIcon: Icons.group,
      );
    }

    return StreamBuilder<Either<Failure, RegisteredUserEntity>>(
      stream: _userStream,
      builder: (context, snapshot) {
        final user = snapshot.data?.fold((_) => null, (u) => u);
        return _buildTile(
          name: user?.name ?? '…',
          photoUrl: user?.profilePic,
          isOnline: user != null &&
              isUserPresent(user.isOnline, user.lastActiveAt),
          showPresence: true,
        );
      },
    );
  }

  Widget _buildTile({
    required String name,
    required String? photoUrl,
    required bool isOnline,
    required bool showPresence,
    IconData? fallbackIcon,
  }) {
    final theme = Theme.of(context);
    final unread = widget.chat.unreadFor(widget.myUid);
    final hasUnread = unread > 0;

    final sentByMe = widget.chat.lastMessageSenderId == widget.myUid;
    final preview = widget.chat.lastMessageText == null
        ? 'No messages yet'
        : (sentByMe
            ? 'You: ${widget.chat.lastMessageText}'
            : widget.chat.lastMessageText!);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: widget.onTap,
      leading: UserAvatar(
        name: name,
        photoUrl: photoUrl,
        radius: 26,
        showPresence: showPresence,
        isOnline: isOnline,
        fallbackIcon: fallbackIcon,
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatChatListTime(widget.chat.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}
