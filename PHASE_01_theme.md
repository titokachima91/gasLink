# PHASE 01 — Theme System Overhaul

**Status:** ⏳ Not started  
**Priority:** 🟡 High  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The entire app uses a hardcoded `Colors.orange` palette. All buttons, app bars, progress indicators, and accent colors are orange. There is no light/dark toggle, no consistent palette, and no theme preferences persisted to storage.

**Evidence on disk:**
- `lib/core/theme.dart` defines `ThemeData` with `Color(0xFFF57C00)` (orange seed)
- `lib/screens/consumer/consumer_home_screen.dart` uses `Colors.orange` throughout (appBar, progress bar, category cards)
- `lib/screens/admin/admin_vendor_screen.dart` uses `Colors.orange` for appBar

---

## 🎯 Goal

- Replace `Colors.orange` with a **Forest Green palette** (`#2D6A4F` primary, matching existing design language)
- Add **light/dark toggle** with persistence
- Create `app_colors.dart` with named semantic colors (`Colors.primary`, `Colors.secondary`, `Colors.error`, etc.)
- Apply theme consistently across all screens

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Define current theme structure | ✅ Done |
| Identify all `Colors.orange` references | ✅ Done (grep: ~30+ occurrences) |

---

## ❌ What's NOT Done

- [ ] Create `lib/core/app_colors.dart` with semantic color constants
- [ ] Create `lib/core/theme_preferences.dart` (light/dark toggle + persistence)
- [ ] Rewrite `lib/core/theme.dart` with forest green palette
- [ ] Apply new theme to all screens (10+ files)
- [ ] Test light/dark mode switching

---

## 🔜 Implementation Steps

1. **Create color palette** (`lib/core/app_colors.dart`):
   ```dart
   class AppColors {
     // Forest Green palette
     static const primary = Color(0xFF2D6A4F);
     static const primaryLight = Color(0xFF40916C);
     static const primaryDark = Color(0xFF1B4332);
     static const secondary = Color(0xFFF59F00); // Amber accent
     static const background = Color(0xFFF8F9FA);
     static const surface = Color(0xFFFFFFFF);
     static const error = Color(0xFFB00020);
   }
   ```

2. **Theme preferences** (`lib/core/theme_preferences.dart`):
   - SharedPreferences key: `theme_mode`
   - Values: `light`, `dark`, `system`
   - Read on app startup, apply to `ThemeData`

3. **Rewrite `lib/core/theme.dart`**:
   - `buildAppTheme()` → `ThemeData` with forest green seed
   - `light` and `dark` variants
   - Text themes, app bar themes, button themes

4. **Apply new theme**:
   - Replace all `Colors.orange` → `AppColors.primary` or semantic colors
   - Update `lib/app.dart` to use new theme + theme preferences

---

## 🚨 Risk

- Moderate — many files use `Colors.orange` directly; will need careful replacement or a find-and-replace pass.
- Mitigation: Use `git diff HEAD` to review all changes before committing.

---

## 📅 Estimated Effort

- 1–2 days of focused work
