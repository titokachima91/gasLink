import 'package:flutter/material.dart';

import 'theme_status_colors.dart';

/// Shortcuts for resolving GasLink theme colors from a [BuildContext].
extension GasLinkThemeX on BuildContext {
  /// Material color roles (primary, surface, text, borders, errors).
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// GasLink semantic status colors (success, warning, info).
  GasLinkStatusColors get gasColors =>
      Theme.of(this).extension<GasLinkStatusColors>() ??
      GasLinkStatusColors.light;

  /// Whether the active theme is dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
