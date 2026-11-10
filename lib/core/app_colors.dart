import 'package:flutter/material.dart';

/// Permanent colour palette for GasLink — Forest Green design system.
///
/// Primary color: #2D6A4F (a deep forest green)
/// Light variant: #52B788 (for hover/accent)
/// Dark variant: #121212 (for dark mode)
/// Surface: #FFFFFFFF (white)
/// On-colors: for text/icon contrast
/// Error: #D9534F (standard red for errors)
/// Success: #38A169 (green for success states)
/// Warning: #F57F17 (orange/yellow for warnings)
class AppColors {
  /// Primary forest green color used throughout the app.
  static const Color primary = Color(0xFF2D6A4F);

  /// Light variant of primary, used for hover states.
  static const Color primaryLight = Color(0xFF52B788);

  /// Dark variant of primary, used in dark mode.
  static const Color primaryDark = Color(0xFF121212);

  /// Background color for light mode.
  static const Color background = Color(0xFFF8F9FA);

  /// Surface color for cards and containers.
  static const Color surface = Color(0xFFFFFFFF);

  /// Card background color.
  static const Color card = Color(0xFFF0F5F0);

  /// Background color for dark mode.
  static const Color darkBackground = Color(0xFF0F1512);

  /// Surface color for cards and containers in dark mode.
  static const Color darkSurface = Color(0xFF1B211E);

  /// Card background color in dark mode.
  static const Color darkCard = Color(0xFF232B27);

  /// Dark app bar color for dark mode.
  static const Color appBarDark = Color(0xFF163B2A);

  /// Text color on primary backgrounds.
  static const Color onPrimary = Colors.white;

  /// Text color on background/surface.
  static const Color onBackground = Colors.black87;

  /// Text color on surface.
  static const Color onSurface = Colors.black87;

  /// Text color on dark backgrounds/surfaces.
  static const Color onDarkSurface = Color(0xFFE8EDEA);

  /// Muted text/icons in dark mode.
  static const Color onDarkSurfaceVariant = Color(0xFFB8C2BC);

  /// Error color for error states in light mode.
  static const Color error = Color(0xFFC62828);

  /// Error background color.
  static const Color errorBackground = Color(0xFFFDF2F2);

  /// Success color for success states.
  static const Color success = Color(0xFF38A169);

  /// Warning color for warning states.
  static const Color warning = Color(0xFFF57F17);
}