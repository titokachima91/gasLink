# Phase 01 — Theme Overhaul (Implementation)

> **Status:** ✅ Complete
> **Completed:** 2026-11-10
> **Branch:** `harden-source-of-truth`
> **Plan:** [`plan.md`](plan.md)
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)

---

## 📋 Summary

The app now has a full Forest Green light/dark/system theme system. The theme is
persisted across restarts, every role can change it, and all screens and shared
widgets resolve colors from the active theme instead of hardcoded orange, white,
black, or grey values.

| Result | Status |
|---|---|
| Forest Green palette | ✅ Complete |
| Light / Dark / System modes | ✅ Complete |
| Persisted theme selection | ✅ Complete |
| Theme picker for every role | ✅ Complete |
| Semantic status colors extension | ✅ Complete |
| Screen/widget color migration | ✅ Complete |
| Legacy-color guard test | ✅ Complete |
| `flutter analyze` | ✅ 0 errors, 0 warnings (51 pre-existing info lints) |
| `flutter test` | ✅ 30/30 passed |

---

## 🏗️ Architecture

### Startup and persistence

`lib/main.dart`:

1. Initializes Flutter, Firebase, notifications, and the saved session.
2. Reads the saved `ThemeMode` with `ThemePreferences.readThemeMode()`.
3. Mounts the app inside a root `ProviderScope`, overriding
   `initialThemeModeProvider` with the persisted value.

`lib/app.dart`:

- `GasLinkApp` is a `ConsumerWidget`.
- `MaterialApp` receives `theme`, `darkTheme`, and `themeMode` from the
  controller.
- `themeMode` changes rebuild the app immediately.

`lib/core/theme_controller.dart`:

- `themeControllerProvider` is a `StateNotifierProvider<ThemeController, ThemeMode>`.
- `setMode(ThemeMode)` updates state and writes the preference.
- `toggle()` switches between light and dark.
- `initialThemeModeProvider` supplies the value loaded before `runApp`.

`lib/core/theme_preferences.dart`:

- Uses `shared_preferences` with the key `theme_mode`.
- Stores `ThemeMode.name` and safely falls back to `ThemeMode.system`.

### Theme construction

`lib/core/theme.dart` exposes `buildAppTheme(Brightness brightness)`. Light and
dark share the brand palette but use different backgrounds, surfaces, and text
colors.

- Light primary: `#2D6A4F`
- Light background: `#F8F9FA`
- Light surface: `#FFFFFF`
- Dark primary: `#52B788`
- Dark background: `#0F1512`
- Dark surface: `#1B211E`
- Dark app bar: `#163B2A`
- Dark text: `#E8EDEA`
- Dark muted text: `#B8C2BC`

The themes also configure app bar, dialog, bottom sheet, card, divider, button,
and input decoration styles so screens inherit consistency by default.

### Semantic status tokens

`lib/core/theme_status_colors.dart` defines `GasLinkStatusColors`, a
`ThemeExtension` with light and dark variants for:

- `success` / `onSuccess` / `successContainer` / `onSuccessContainer`
- `warning` / `onWarning` / `warningContainer` / `onWarningContainer`
- `info` / `onInfo` / `infoContainer` / `onInfoContainer`

The extension is registered in both themes, so status colors stay readable in
light and dark mode.

### Context helpers

`lib/core/theme_ext.dart` adds:

```dart
context.colors      // Material ColorScheme
context.gasColors   // GasLinkStatusColors
context.isDark      // active brightness
```

These helpers are used across the screens and widgets. They replaced the legacy
pattern of resolving colors from `Theme.of(context)` inline and made the
migration consistent.

### Theme picker

`lib/widgets/theme_mode_button.dart` provides an app-bar icon that opens a
System / Light / Dark picker and writes through the controller.

It is available from:

- Login
- Consumer home
- Vendor dashboard
- Admin panel
- Vendor Settings (plus an inline `SegmentedButton`)

---

## 🎨 Screen Migration

All Dart files under `lib/screens` and `lib/widgets` were migrated. The legacy
orange brand, forced light scaffolds, white cards on light backgrounds, black
body text, and grey borders/fills were replaced with theme roles.

| Legacy value | Replacement |
|---|---|
| `Colors.orange` / shades | `context.colors.primary` |
| Orange soft backgrounds | `context.colors.primaryContainer` |
| `Color(0xFFF8F9FA)` scaffold | `Theme.of(context).scaffoldBackgroundColor` |
| `Colors.white` cards/sheets | `context.colors.surface` |
| `Colors.black87` | `context.colors.onSurface` |
| `Colors.black54` | `context.colors.onSurfaceVariant` |
| `Colors.grey` text/icons | `context.colors.onSurfaceVariant` |
| Grey borders | `context.colors.outlineVariant` |
| Grey fills | `context.colors.surfaceContainerLow` |
| `Colors.red*` | `context.colors.error` / `errorContainer` |
| `Colors.green*` | `context.gasColors.success` / `successContainer` |
| `Colors.amber*` | `context.gasColors.warning` / `warningContainer` |
| `Colors.blue*` | `context.gasColors.info` / `infoContainer` |
| White text/icons on colored bars | `context.colors.onPrimary` / status `on*` colors |

### Intentional exceptions

`Colors.white` is still used where the widget sits on a guaranteed dark-green
app bar, drawer header, gradient hero, or colored chip. Examples:

- App bar titles and icons
- `UserAccountsDrawerHeader` text
- Vendor badge hero text and progress indicator
- White circular avatar backgrounds on dark hero cards
- `Colors.transparent` for unselected segmented controls
- `Colors.white70` / `Colors.white30` for muted text and tracks on dark headers

These are deliberately white-on-dark and do not change with the surface theme.

---

## 🧹 Migration Process

The migration was performed in batches so analyzer feedback stayed manageable:

1. Audited all hardcoded colors in `lib/screens` and `lib/widgets`.
2. Added the semantic extension and context helpers.
3. Ran a codemod over screens/widgets to replace the legacy palette.
4. Removed only the `const` keywords that became invalid because a themed color
   now resolves at build time (203 in the first pass, 9 after the contrast
   fixes).
5. Fixed contrast issues found by review:
   - Selected category pills now use `onPrimary` instead of white.
   - Selected weight chips use `onPrimary`.
   - The cylinder icon shadow, ring, and label now use theme colors.
   - Logout button uses `onError`.
   - Unavailable vendor buy buttons use `onSurface`.
6. Removed the two pre-existing analyzer warnings (unused `_isLoading`, unused
   import).
7. Added a guard test that fails if legacy colors return.

The blindly wrong earlier explanation for the blank screen ("remove `const` from
`runApp`") was discarded. The actual root cause was a missing root
`ProviderScope`, which is now part of `main.dart`.

---

## 🧪 Verification

### Analyzer

```text
0 errors
0 warnings
51 info-level lints (pre-existing style lints)
```

### Tests

`flutter test` → **30/30 passed**, including:

- App starts inside `ProviderScope` and renders the login screen.
- App renders in dark mode when the persisted mode is dark.
- Light/dark themes have the correct brightness, scaffold, app bar, and text
  colors.
- Both themes register `GasLinkStatusColors` and the light/dark tokens differ.
- Screens and widgets contain no `Colors.orange`, `Colors.black87`,
  `Colors.black54`, `Colors.grey`, or `Color(0xFFF8F9FA)`.
- Theme controller changes mode and persists it.
- Auth, session persistence, cylinder FIFO, and utils suites still pass.

### Runtime smoke

Widget smoke tests mount the full `GasLinkApp` in both light and dark mode and
verify that the login screen renders without provider or theme exceptions. The
app bar resolves to the Forest Green light color or the dark app-bar color as
expected.

### Visual spot-check

Temporary golden renders were generated for Login, Settings, Admin, and
`ProductListTile` in light and dark mode. The pass checked app bars, input
fields, cards, segmented controls, status chips, the logout button, and the
cylinder icon. Issues found during this pass were fixed:

- Selected category/weight controls now use `onPrimary`.
- The cylinder icon uses theme-aware shadow, ring, and label colors.
- The light warning token was darkened to meet contrast.
- Error colors now have distinct light/dark pairs.
- The browse warning icon on the app bar is no longer low-contrast.

The temporary visual harness and golden images were removed after inspection.

---

## ⚠️ Problems Encountered and Resolved

| Problem | Resolution |
|---|---|
| Blank screen with `No ProviderScope found` | Added a root `ProviderScope` in `main.dart`; removed the incorrect `const` theory from the old record |
| Theme preference was only a placeholder | Implemented real `shared_preferences` reads/writes |
| `const` widgets contained runtime theme colors | Analyzer-driven removal of only the affected `const` keywords |
| Selected controls used white on dark-mode light-green primary | Switched to `onPrimary` |
| Some cards and sheets stayed white in dark mode | Replaced with `surface` / `scaffoldBackgroundColor` |
| Status colors had no dark variant | Added `GasLinkStatusColors` `ThemeExtension` |
| Legacy colors could silently return | Added a repository-level guard test |

---

## ✅ Exit Criteria

- [x] Forest Green replaces the legacy orange palette.
- [x] Light, dark, and system modes work.
- [x] Theme selection survives restart.
- [x] Picker available from every role.
- [x] Screens and widgets use theme roles.
- [x] Status colors have light and dark tokens.
- [x] No legacy orange/black/grey/light-hex colors in UI files.
- [x] Analyzer has zero errors and warnings.
- [x] All tests pass.
- [x] Documentation updated (`ROADMAP.md`, `PROGRESS.md`, this file).

---

## 🔜 Follow-up

The theme overhaul is closed. The next phase is the Admin Panel; see
`ROADMAP.md`. Any future UI work must use the context helpers and keep the
legacy-color guard test green.
