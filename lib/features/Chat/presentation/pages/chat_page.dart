import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/chat_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../../Users/domain/use_cases/get_user_use_case.dart';
import '../../../Users/domain/use_cases/watch_user_use_case.dart';
import '../../../Users/presentation/pages/profile_page.dart';
import '../../domain/entity/chat_entity.dart';
import '../../domain/entity/message_entity.dart';
import '../bloc/messaging_bloc.dart';

class ChatPage extends StatefulWidget {
  final ChatEntity chat;
  final String myUid;

  const ChatPage({super.key, required this.chat, required this.myUid});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final MessagingBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  int _lastCount = 0;

  /// uid → profile, for group sender names/avatars.
  final Map<String, RegisteredUserEntity> _members = {};

  /// Live profile of the other participant (direct chats only).
  Stream<Either<Failure, RegisteredUserEntity>>? _otherUserStream;
  String _otherUid = '';

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<MessagingBloc>()
      ..add(
        MessagingStarted(
          chatId: widget.chat.id,
          myUid: widget.myUid,
          participants: widget.chat.participants,
        ),
      );

    if (widget.chat.isGroup) {
      _loadMembers();
    } else {
      _otherUid = widget.chat.otherParticipant(widget.myUid);
      if (_otherUid.isNotEmpty) {
        _otherUserStream =
            di.sl<WatchUserUseCase>()(WatchUserParams(uid: _otherUid));
      }
    }
  }

  Future<void> _loadMembers() async {
    final getUser = di.sl<GetUserUseCase>();
    for (final uid in widget.chat.participants) {
      final res = await getUser(GetUserParams(uid: uid));
      res.fold((_) {}, (user) => _members[uid] = user);
    }
    if (mounted) setState(() {});
  }

  void _onTextChanged(String value) {
    final typing = value.trim().isNotEmpty;
    if (typing && !_isTyping) {
      _isTyping = true;
      _bloc.add(const MessagingTypingChanged(true));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _bloc.add(const MessagingTypingChanged(false));
    }
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _bloc.add(MessagingMessageSent(text: text));
    _controller.clear();
    _typingTimer?.cancel();
    _stopTyping();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null) return;
    _bloc.add(
      MessagingMessageSent(type: MessageType.image, imagePath: picked.path),
    );
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<String> _typingOthers(ChatEntity? chat) {
    if (chat == null) return const [];
    return chat.participants
        .where((p) => p != widget.myUid && isTypingFresh(chat.typing[p]))
        .toList();
  }

  bool _isSeen(MessageEntity message, ChatEntity? chat) {
    if (chat == null || message.senderId != widget.myUid) return false;
    final others = chat.participants.where((p) => p != widget.myUid);
    if (others.isEmpty) return false;
    for (final other in others) {
      final lastRead = chat.lastRead[other];
      if (lastRead == null || lastRead.isBefore(message.sentAt)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: _buildHeader(context),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<MessagingBloc, MessagingState>(
                listenWhen: (prev, curr) =>
                    prev.error != curr.error && curr.error != null,
                listener: (context, state) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!)),
                  );
                },
                builder: (context, state) {
                  if (state.status == MessagingStatus.loading &&
                      state.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.messages.isEmpty) {
                    return const _EmptyConversation();
                  }
                  if (state.messages.length != _lastCount) {
                    _lastCount = state.messages.length;
                    _scrollToBottom(animate: true);
                  }
                  return _buildMessageList(context, state);
                },
              ),
            ),
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (widget.chat.isGroup) {
      return BlocBuilder<MessagingBloc, MessagingState>(
        builder: (context, state) {
          final chat = state.chat ?? widget.chat;
          final typing = _typingOthers(chat);
          final subtitle = typing.isNotEmpty
              ? _typingLabel(typing)
              : '${chat.participants.length} members';
          return Row(
            children: [
              UserAvatar(
                name: chat.name ?? 'Group',
                photoUrl: chat.photoUrl,
                radius: 20,
                fallbackIcon: Icons.group,
              ),
              const SizedBox(width: 12),
              Expanded(child: _titleColumn(chat.name ?? 'Group', subtitle)),
            ],
          );
        },
      );
    }

    return StreamBuilder<Either<Failure, RegisteredUserEntity>>(
      stream: _otherUserStream,
      builder: (context, snapshot) {
        final user = snapshot.data?.fold((_) => null, (u) => u);
        final name = user?.name ?? 'Chat';
        return BlocBuilder<MessagingBloc, MessagingState>(
          builder: (context, state) {
            final typing = _typingOthers(state.chat).isNotEmpty;
            String subtitle = '';
            if (typing) {
              subtitle = 'typing…';
            } else if (user != null) {
              subtitle = formatPresence(user.isOnline, user.lastActiveAt);
            }
            return InkWell(
              onTap: user == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfilePage(uid: _otherUid, isSelf: false),
                        ),
                      ),
              child: Row(
                children: [
                  UserAvatar(
                    name: name,
                    photoUrl: user?.profilePic,
                    radius: 20,
                    showPresence: true,
                    isOnline: user != null &&
                        isUserPresent(user.isOnline, user.lastActiveAt),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _titleColumn(name, subtitle)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _titleColumn(String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: subtitle == 'typing…' || subtitle == 'online'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  String _typingLabel(List<String> typingUids) {
    if (!widget.chat.isGroup) return 'typing…';
    final names = typingUids
        .map((uid) => _members[uid]?.name.split(' ').first ?? 'Someone')
        .toList();
    if (names.length == 1) return '${names.first} is typing…';
    return '${names.length} people are typing…';
  }

  Widget _buildMessageList(BuildContext context, MessagingState state) {
    final messages = state.messages;
    final typingOthers = _typingOthers(state.chat);

    // Interleave day separators with messages.
    final items = <_ChatItem>[];
    DateTime? lastDay;
    for (final message in messages) {
      final day = DateTime(
        message.sentAt.year,
        message.sentAt.month,
        message.sentAt.day,
      );
      if (lastDay == null || day != lastDay) {
        items.add(_DaySeparatorItem(day));
        lastDay = day;
      }
      items.add(_MessageItem(message));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length + (typingOthers.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return _TypingBubble(label: _typingLabel(typingOthers));
        }
        final item = items[index];
        if (item is _DaySeparatorItem) {
          return _DaySeparator(label: formatDaySeparator(item.day));
        }
        final message = (item as _MessageItem).message;
        final isMe = message.senderId == widget.myUid;
        return _MessageBubble(
          message: message,
          isMe: isMe,
          isGroup: widget.chat.isGroup,
          senderName: isMe ? null : _members[message.senderId]?.name,
          seen: _isSeen(message, state.chat),
          onImageTap: message.isImage && message.imageUrl != null
              ? () => _openImage(context, message.imageUrl!)
              : null,
        );
      },
    );
  }

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.photo_outlined),
                    onPressed: _sendImage,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(onPressed: _sendText, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

sealed class _ChatItem {}

class _DaySeparatorItem extends _ChatItem {
  final DateTime day;
  _DaySeparatorItem(this.day);
}

class _MessageItem extends _ChatItem {
  final MessageEntity message;
  _MessageItem(this.message);
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  const _SendButton({required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.send, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isGroup;
  final String? senderName;
  final bool seen;
  final VoidCallback? onImageTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.seen,
    this.senderName,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final chatColors = Theme.of(context).extension<ChatColors>()!;
    final bubbleColor = isMe ? chatColors.sentBubble : chatColors.receivedBubble;
    final textColor = isMe ? chatColors.sentText : chatColors.receivedText;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.76),
            padding: message.isImage
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGroup && !isMe && senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      senderName!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (message.isImage && message.imageUrl != null)
                  GestureDetector(
                    onTap: onImageTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        width: screenWidth * 0.6,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          width: screenWidth * 0.6,
                          height: screenWidth * 0.6,
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, _, _) => const SizedBox(
                          width: 120,
                          height: 120,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                if (message.text != null && message.text!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: message.isImage ? 6 : 0),
                    child: Text(
                      message.text!,
                      style: TextStyle(color: textColor, fontSize: 15.5),
                    ),
                  ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatMessageTime(message.sentAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        seen ? Icons.done_all : Icons.check,
                        size: 15,
                        color: seen
                            ? Colors.lightBlueAccent
                            : textColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final String label;
  const _TypingBubble({required this.label});

  @override
  Widget build(BuildContext context) {
    final chatColors = Theme.of(context).extension<ChatColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: chatColors.receivedBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: chatColors.receivedText.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  final String label;
  const _DaySeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'Say hello 👋',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
