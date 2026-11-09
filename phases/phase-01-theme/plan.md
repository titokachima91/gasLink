# Phase 01 — Theme Overhaul

## 📝 Issue Description

The app is entirely orange-based (`Colors.orange` in `lib/core/theme.dart`). The fix requires:

1. Creating a proper theme architecture (colours, theme preferences, Riverpod controller)
2. Replacing all `Colors.orange` references
3. Adding light/dark mode toggle

## 🎯 Goal

- Replace `Colors.orange` with a consistent Forest Green design system
- Support light/dark mode via `theme_preferences.dart` + Riverpod
- Update `lib/core/theme.dart` with `buildAppTheme()`

## 🔀 Proposed Solution

1. **Create `lib/core/app_colors.dart`** — permanent colour palette
   ```dart
   class AppColors {
     static const primary = Color(0xFF2D6A4F);
     static const primaryLight = Color(0xFF52B788);
     static const background = Color(0xFFF8F9FA);
     static const surface = Color(0xFFFFFFFF);
     static const onPrimary = Colors.white;
     static const error = Color(0xFFD9534F);
     static const onBackground = Colors.black87;
   }
   ```

2. **Create `lib/core/theme_preferences.dart`** — persistent theme selection
   ```dart
   class ThemePreferences {
     static const key = 'theme_mode';
     Future<ThemeMode> getThemeMode() async {
       // Read from shared_preferences
     }
     Future<void> setThemeMode(ThemeMode mode) async {
       // Write to shared_preferences
     }
   }
   ```

3. **Rewrite `lib/core/theme.dart`** — three themes (light/dark/system) with `buildAppTheme()`
   ```dart
   ThemeData buildAppTheme(ThemeMode mode) {
     final isDark = mode == ThemeMode.dark;
     return ThemeData(
       useMaterial3: true,
       colorScheme: ColorScheme.fromSeed(
         seedColor: AppColors.primary,
         brightness: isDark ? Brightness.dark : Brightness.light,
       ),
       appBarTheme: const AppBarTheme(
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
         elevation: 0,
       ),
       filledButtonTheme: FilledButtonThemeData(
         style: FilledButton.styleFrom(
           backgroundColor: AppColors.primary,
           foregroundColor: AppColors.onPrimary,
           minimumSize: const Size.fromHeight(52),
         ),
       ),
       cardTheme: CardThemeData(color: AppColors.surface),
     );
   }
   ```

4. **Add Riverpod `ThemeController`** (`lib/core/theme_controller.dart`)
   ```dart
   final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
     return ThemeController();
   });
   
   class ThemeController extends StateNotifier<ThemeMode> {
     ThemeController() : super(ThemeMode.system);
     void toggle() => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
   }
   ```

5. **Wire into `app.dart`** — wrap MaterialApp with correct theme

## 📊 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-------------|
| Breaking existing UI | Medium | High | Test on all screens after theme switch |
| Riverpod setup | Low | High | Use existing Riverpod structure |
| Theme state loss on restart | Low | Medium | `theme_preferences.dart` persists choice |

## ⏱ Estimated Effort

**Estimated: 2–3 hours**
- app_colors.dart: 30 min
- theme_preferences.dart: 30 min
- theme.dart rewrite: 45 min
- theme_controller.dart: 30 min
- app.dart wiring: 30 min
- Testing: 30 min
