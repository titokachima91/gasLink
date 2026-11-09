# Phase 01 — Theme Overhaul (Implementation)

## 📋 Status

❌ **Not started** — This phase has not been implemented yet.

---

## 📁 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/core/app_colors.dart` | Create | Permanent colour palette |
| `lib/core/theme_preferences.dart` | Create | Persistent theme selection via shared_preferences |
| `lib/core/theme.dart` | Rewrite | `buildAppTheme()` with Forest Green |
| `lib/core/theme_controller.dart` | Create | Riverpod StateNotifier |

---

## 🚀 Steps Taken

| Step | Action | Status |
|------|--------|--------|
| 1 | Create `app_colors.dart` | ⏳ Pending |
| 2 | Create `theme_preferences.dart` | ⏳ Pending |
| 3 | Rewrite `theme.dart` | ⏳ Pending |
| 4 | Create `theme_controller.dart` | ⏳ Pending |
| 5 | Wire into `app.dart` | ⏳ Pending |

---

## 🔍 Code Evidence (Planned)

### app_colors.dart
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

### theme.dart
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
  );
}
```

### theme_controller.dart
```dart
final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);
  void toggle() => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
}
```

---

## ⚠️ Problems Encountered

None yet — this is a planned phase.

---

## 🔄 Pivots Taken

None yet.

---

## ✅ Accomplishments

None yet.

---

## ⏭ Next Steps

- Create `app_colors.dart`
- Create `theme_preferences.dart`
- Rewrite `theme.dart`
- Create `theme_controller.dart`
- Wire into `app.dart`
- Test on all screens
