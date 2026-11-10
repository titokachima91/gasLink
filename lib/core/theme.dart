import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'theme_status_colors.dart';

/// Generates the GasLink [ThemeData] for the given [Brightness].
///
/// Light and dark variants share the Forest Green brand palette but use
/// different backgrounds, surfaces and text colors for readable contrast.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final accent = isDark ? AppColors.primaryLight : AppColors.primary;
  final background = isDark ? AppColors.darkBackground : AppColors.background;
  final surface = isDark ? AppColors.darkSurface : AppColors.surface;
  final card = isDark ? AppColors.darkCard : AppColors.card;
  final onSurface = isDark ? AppColors.onDarkSurface : AppColors.onSurface;
  final onSurfaceVariant = isDark
      ? AppColors.onDarkSurfaceVariant
      : const Color(0xFF5F6B64);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    onPrimary: isDark ? const Color(0xFF06281B) : AppColors.onPrimary,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    error: isDark ? const Color(0xFFFFB4AB) : AppColors.error,
    onError: isDark ? const Color(0xFF690005) : Colors.white,
    errorContainer: isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
    onErrorContainer:
        isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    extensions: <ThemeExtension<dynamic>>[
      isDark ? GasLinkStatusColors.dark : GasLinkStatusColors.light,
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.appBarDark : AppColors.primary,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 0,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surface,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 2,
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF35403A) : const Color(0xFFE3E8E4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: isDark ? const Color(0xFF06281B) : AppColors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: isDark ? const Color(0xFF06281B) : AppColors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    ),
  );
}
