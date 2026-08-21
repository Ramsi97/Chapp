import 'package:flutter/material.dart';

/// Chat-specific colors that aren't part of the standard [ColorScheme].
/// Exposed as a [ThemeExtension] so message bubbles adapt to light/dark
/// automatically via `Theme.of(context).extension<ChatColors>()`.
@immutable
class ChatColors extends ThemeExtension<ChatColors> {
  final Color sentBubble;
  final Color sentText;
  final Color receivedBubble;
  final Color receivedText;
  final Color chatBackground;

  const ChatColors({
    required this.sentBubble,
    required this.sentText,
    required this.receivedBubble,
    required this.receivedText,
    required this.chatBackground,
  });

  @override
  ChatColors copyWith({
    Color? sentBubble,
    Color? sentText,
    Color? receivedBubble,
    Color? receivedText,
    Color? chatBackground,
  }) {
    return ChatColors(
      sentBubble: sentBubble ?? this.sentBubble,
      sentText: sentText ?? this.sentText,
      receivedBubble: receivedBubble ?? this.receivedBubble,
      receivedText: receivedText ?? this.receivedText,
      chatBackground: chatBackground ?? this.chatBackground,
    );
  }

  @override
  ChatColors lerp(ThemeExtension<ChatColors>? other, double t) {
    if (other is! ChatColors) return this;
    return ChatColors(
      sentBubble: Color.lerp(sentBubble, other.sentBubble, t)!,
      sentText: Color.lerp(sentText, other.sentText, t)!,
      receivedBubble: Color.lerp(receivedBubble, other.receivedBubble, t)!,
      receivedText: Color.lerp(receivedText, other.receivedText, t)!,
      chatBackground: Color.lerp(chatBackground, other.chatBackground, t)!,
    );
  }
}
