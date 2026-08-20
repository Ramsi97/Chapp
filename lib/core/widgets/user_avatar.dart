import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular avatar that shows the user's photo when available, or their
/// initials on the shared brand gradient otherwise. Optionally overlays a
/// green presence dot. Reused across the chat list, chat header and profiles.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final bool showPresence;
  final bool isOnline;

  /// Overrides the initials with an icon (e.g. group / camera placeholders).
  final IconData? fallbackIcon;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 26,
    this.showPresence = false,
    this.isOnline = false,
    this.fallbackIcon,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    Widget placeholder = Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.avatarGradient,
      ),
      child: fallbackIcon != null
          ? Icon(fallbackIcon, color: Colors.white, size: radius)
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    Widget avatar = placeholder;
    if (hasPhoto) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => placeholder,
        ),
      );
    }

    if (!showPresence || !isOnline) return avatar;

    final dot = diameter * 0.28;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
