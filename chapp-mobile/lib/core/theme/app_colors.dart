import 'package:flutter/material.dart';

/// Central color tokens for the app. Everything visual should derive from
/// these (or from `Theme.of(context)`), so light/dark stay consistent.
class AppColors {
  AppColors._();

  /// Seed for the Material 3 [ColorScheme] — a blue→violet brand hue.
  static const Color seed = Color(0xFF5B6EF5);

  // Brand gradient used for avatars, the compose FAB and accents.
  static const Color gradientStart = Color(0xFF5B6EF5); // blue
  static const Color gradientEnd = Color(0xFF9B5BF5); // violet
  static const List<Color> brandGradient = [gradientStart, gradientEnd];

  // Dark surfaces (kept close to the original login/register palette).
  static const Color darkBackground = Color(0xFF0E1621);
  static const Color darkSurface = Color(0xFF1C2833);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFF6F7FB);

  static const Color online = Color(0xFF3BD671);

  /// A gradient avatar decoration shared by every avatar placeholder.
  static const LinearGradient avatarGradient = LinearGradient(
    colors: brandGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
