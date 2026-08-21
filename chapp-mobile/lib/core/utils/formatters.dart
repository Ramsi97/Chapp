import 'package:intl/intl.dart';

/// Freshness window: Firestore has no `onDisconnect`, so we treat a user as
/// "online" only if they flagged online recently. A hard-killed app stops
/// refreshing this and drops offline on its own within the window.
const Duration _presenceWindow = Duration(minutes: 2);
const Duration _typingWindow = Duration(seconds: 6);

/// True if [lastActiveAt] is recent enough to show the user as online.
bool isUserPresent(bool isOnline, DateTime lastActiveAt) {
  if (!isOnline) return false;
  return DateTime.now().difference(lastActiveAt) < _presenceWindow;
}

/// "online" / "last seen 5m ago" / "last seen Sep 15".
String formatPresence(bool isOnline, DateTime lastActiveAt) {
  if (isUserPresent(isOnline, lastActiveAt)) return 'online';
  final diff = DateTime.now().difference(lastActiveAt);
  if (diff < const Duration(minutes: 1)) return 'last seen just now';
  if (diff < const Duration(hours: 1)) return 'last seen ${diff.inMinutes}m ago';
  if (diff < const Duration(days: 1)) return 'last seen ${diff.inHours}h ago';
  if (diff < const Duration(days: 7)) return 'last seen ${diff.inDays}d ago';
  return 'last seen ${DateFormat.MMMd().format(lastActiveAt)}';
}

/// Compact stamp for the chat list ("now", "2m", "14:05", "Mon", "9/15/25").
String formatChatListTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff < const Duration(minutes: 1)) return 'now';
  if (diff < const Duration(hours: 1)) return '${diff.inMinutes}m';
  final sameDay = now.year == time.year &&
      now.month == time.month &&
      now.day == time.day;
  if (sameDay) return DateFormat.Hm().format(time);
  if (diff < const Duration(days: 7)) return DateFormat.E().format(time);
  return DateFormat.yMd().format(time);
}

/// Clock time shown inside a message bubble ("14:05").
String formatMessageTime(DateTime time) => DateFormat.Hm().format(time);

/// Whether [typingAt] is recent enough to mean "typing right now".
bool isTypingFresh(DateTime? typingAt) {
  if (typingAt == null) return false;
  return DateTime.now().difference(typingAt) < _typingWindow;
}

/// Day-separator label between message groups ("Today"/"Yesterday"/date).
String formatDaySeparator(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(day.year, day.month, day.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat.EEEE().format(day);
  return DateFormat.yMMMd().format(day);
}
