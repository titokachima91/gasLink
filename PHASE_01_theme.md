# PHASE 01 — Theme Overhaul

**Status:** ⏳ Not started  
**Priority:** 🔴 High  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

The app is entirely orange-based (`Colors.orange` in `lib/core/theme.dart`). The fix requires:

1. Creating a proper theme architecture (colours, theme preferences, Riverpod controller)
2. Replacing all `Colors.orange` references
3. Adding light/dark mode toggle

---

## 🎯 Goal

- Replace `Colors.orange` with a consistent Forest Green design system
- Support light/dark mode via `theme_preferences.dart` + Riverpod
- Update `lib/core/theme.dart` with `buildAppTheme()`

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Current theme location | `lib/core/theme.dart` — uses `Colors.orange` only |
| Brand colour preference | Forest Green `#2D6A4F` (light) / `#121212` (dark) |
| Toast/notification colour | Same Forest Green as primary |

---

## 🔜 Implementation Steps

1. **Create `lib/core/app_colors.dart`** — permanent colour palette
2. **Create `lib/core/theme_preferences.dart`** — persistent theme selection via shared_preferences
3. **Rewrite `lib/core/theme.dart`** — three themes (light/dark/system) with `buildAppTheme()`
4. **Add Riverpod `ThemeController`** (`lib/core/theme_controller.dart`)
5. **Wire into `app.dart`** — wrap MaterialApp with correct theme

---

## 🔜 Next Steps

- Replace all `Colors.orange` in screens with `AppColors.primary`
- Add dark mode test
- Run `flutter analyze` to verify no warnings
