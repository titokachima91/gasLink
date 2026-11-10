# Phase 01 — Theme Overhaul (Completion Plan)

> **Status:** ✅ Complete (2026-11-10)
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)
> **This phase ends when:** every screen is theme-driven and light/dark/system are
> visually verified across all roles.

---

## ✅ Already Completed

### Foundation (T0)

- `lib/main.dart` wraps the app in `ProviderScope`; fixes blank-screen crash.
- Theme preference loaded before `runApp` and injected through
  `initialThemeModeProvider`.
- `lib/app.dart` uses `theme`, `darkTheme`, and `themeMode`.
- `lib/core/theme_controller.dart` persists `ThemeMode` changes.
- `lib/core/theme_preferences.dart` stores the selection in
  `shared_preferences`.
- `lib/core/theme.dart` builds distinct light and dark `ThemeData`.
- `lib/widgets/theme_mode_button.dart` provides the System/Light/Dark picker.
- Picker available from login, consumer home, vendor dashboard, admin panel, and
  vendor Settings.
- `test/theme_test.dart` covers startup, light/dark values, and persistence.

### Current Visual State

- Login, Settings, admin, and main app bars are mostly theme-aware.
- Consumer home headings/background partially migrated.
- Most content screens still use the legacy orange palette and hardcoded light
  colors. The toggle changes app chrome but not those screens yet.

---

## 🎯 Remaining Work

### T1 — Semantic tokens

- [x] Add success / warning / info light+dark tokens (`theme_status_colors.dart`)
- [x] Add `context.colors` and `context.gasColors` extensions
- [x] Register token extension in both themes
- [x] Update `AppColors` documentation

### T2 — Consumer flows

- [x] `consumer_home_screen.dart`
- [x] `consumer_order_screen.dart`
- [x] `consumer_cylinder_screen.dart`
- [x] `consumer_order_dialog.dart`
- [x] `consumer_order_history_screen.dart`
- [x] `vendor_detail_screen.dart`
- [x] `vendor_search_screen.dart`
- [x] `brand_shop_screen.dart`
- [x] `browse_screen.dart`
- [x] `item_vendors_screen.dart`
- [x] `search_delegate.dart`

### T3 — Vendor flows

- [x] `vendor_dashboard_screen.dart`
- [x] `vendor_order_screen.dart`
- [x] `inventory_screen.dart`
- [x] `vendor_profile_screen.dart`
- [x] `vendor_badge_screen.dart`
- [x] `vendor_drawer.dart`
- [x] `add_product_dialog.dart`

### T4 — Cross-cutting UI

- [x] `login_screen.dart`
- [x] `register_screen.dart`
- [x] `settings_screen.dart` (final pass)
- [x] `admin_vendor_screen.dart` (final pass)
- [x] `widgets/product_list_tile.dart`
- [x] `widgets/gas_cylinder_icon.dart`
- [x] `screens/vendor_list_screen.dart`

### T5 — QA & guardrails

- [x] No `Colors.orange` in `lib/screens` / `lib/widgets`
- [x] No hardcoded `#F8F9FA` scaffolds
- [x] All cards/text/borders theme-driven
- [x] Automated guard + startup smoke; optional device-level visual pass
      recommended for live-data screens
- [x] Contrast pass on dark mode (chips, gauges, status colors)
- [x] `flutter analyze` zero errors
- [x] `flutter test` green
- [x] Add guard test/rule against legacy hardcoded colors

---

## 📋 Migration Mapping

| Legacy | Replacement |
|---|---|
| `Colors.orange` | `context.colors.primary` |
| `Colors.orange.shade50/100/200` | `context.colors.primaryContainer` |
| `Colors.orange.shade300/400` | `context.colors.primary` |
| `Colors.orange.shade700/800/900` | `context.colors.onPrimaryContainer` or `primary` |
| `Color(0xFFF8F9FA)` scaffold | `Theme.of(context).scaffoldBackgroundColor` |
| `Colors.white` card/sheet | `context.colors.surface` |
| `Colors.black87` | `context.colors.onSurface` |
| `Colors.black54` / `black45` | `context.colors.onSurfaceVariant` |
| `Colors.grey` / `grey.shade600-800` | `context.colors.onSurfaceVariant` |
| `Colors.grey.shade200/300` border | `context.colors.outlineVariant` |
| `Colors.grey.shade100/50` fill | `context.colors.surfaceContainerLow` |
| `Colors.red*` | `context.colors.error` / `errorContainer` |
| `Colors.green*` | `context.gasColors.success` / `successContainer` |
| `Colors.amber*` | `context.gasColors.warning` / `warningContainer` |
| `Colors.blue*` | `context.gasColors.info` / `infoContainer` |
| `Colors.white` text/icon on primary | Keep as `Colors.white` |
| `Colors.transparent` | Keep |

---

## ⚠️ Known Risks

| Risk | Impact | Mitigation |
|---|---|---|
| `const` widgets contain hardcoded colors | Analyzer errors after migration | Remove `const` only where needed; analyzer-driven cleanup |
| Status chips lose meaning if blindly re-colored | High | Keep semantic mapping (`context.gasColors`) |
| Dark-mode contrast regressions | Medium | QA each major screen in dark mode |
| Large diff hides behavioral regressions | Medium | Migrate by screen group; run tests after each batch |
| Some helper methods lack `context` | Medium | Pass context or move color resolution into `build` |

---

## ✅ Exit Criteria

1. Every screen in `ROADMAP.md` T2–T4 is checked off.
2. `flutter analyze` reports zero errors and no new warnings.
3. `flutter test` passes.
4. Automated theme QA passes (guard test + startup smoke); a device-level visual
   pass on live-data screens remains optional follow-up.
5. `phases/phase-01-theme/implementation.md` records the completed work.
6. `PROGRESS.md` and `ROADMAP.md` both mark the theme overhaul complete.
