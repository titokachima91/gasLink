# GasLink — Master Progress Report

> **Last updated:** 2026-11-10
> **Branch:** `harden-source-of-truth`
> **Project state:** Working Flutter + Firebase application for LPG gas distribution in Dar es Salaam, Tanzania.
> **Documentation:** [`ROADMAP.md`](ROADMAP.md) is the high-level project plan; `phases/<phase>/` holds per-phase plans and implementation records. This file is the authoritative status tracker.
> **Theme:** Phase 1 complete — see `phases/phase-01-theme/implementation.md`.
> **Current phase:** Phase 2 — Admin & Operations Console (in progress).

---

## 📊 Summary Status

| Area | Status |
|------|--------|
| Auth & Session Persistence | ✅ **Complete** |
| Admin PIN Integration | ✅ **Complete** |
| Home Screen Gauge (collective) | ✅ **Complete** |
| Cylinder Smart Hub (collective) | ✅ **Complete** |
| Order Statuses (/7) | ✅ **Complete** |
| Role Router | ✅ **Complete** |
| Circle FIFO Logic | ✅ **Complete** |
| Theme System | ✅ **Complete** — Forest Green light/dark/system palette, persisted picker, semantic tokens, all screens migrated |
| Admin & Operations Console | 🚧 **Phase 2 in progress** — shell, vendors, orders, consumers, analytics, inventory, settings |
| Operational Analytics | 🚧 **In Phase 2** — merged into the admin console |
| Vendor verified Role | ❌ **Not done** — Phase 3 |
| Vendor Profile | ⚠️ **Exists** but no image upload (Phase 4) |
| Stock Visibility | ⚠️ **Partial** — admin inventory view lands in Phase 2 |

---

## ✅ Verified Working (Confirmed on Disk)

| # | Feature | Evidence |
|---|---------|----------|
| 1 | Auth Persistence | auth_service.dart saves session; main.dart restores via restoreSession() |
| 2 | Session Persistence | admin_pin_service.dart persists role/phone/uid |
| 3 | Admin PIN Integration | admin_pin_service.dart (savePin/getPin/clearPin); auth_service.dart adminLogin with adminPhone: '+255767304776', adminPin: '0000' |
| 4 | Home Screen Gauge | Uses calculateFifo() from cylinder_fifo.dart; groups by brand+weight |
| 5 | Cylinder Smart Hub | Uses cylinder_fifo.dart; progress bar uses capacityFraction (0-1.0) |
| 6 | Order Statuses | AppConstants.orderStatuses = 7 statuses |
| 7 | Role Router | role_router.dart routes admin-vendor-consumer |
| 8 | Circle FIFO | cylinder_fifo.dart implements FIFO; totalPercentage can exceed 100%; capacityFraction is 0-1.0 |
| 9 | Theme system | ProviderScope root, light/dark/system `ThemeMode`, persisted preference, picker on all role entry points |
| 10 | Theme migration | All `lib/screens` and `lib/widgets` use `context.colors` / `context.gasColors`; no legacy orange/black/grey/light-hex colors |
| 11 | Theme tests | test/theme_test.dart verifies startup in light/dark, theme values, status extension, persistence, and legacy-color guard |

### Hardcoded Login (Seed Credential)

- Phone: 0767304776 (or +255767304776)
- PIN: 0000
- Route: login -> auth_service.dart -> adminLogin() -> AuthService.roleAdmin

---

## 🔍 Key Code Locations

| Component | File | Notes |
|-----------|------|-------|
| FIFO calculator | lib/utils/cylinder_fifo.dart | calculateFifo(), FifoCollective, parseCycleDays() |
| Auth service | lib/services/auth_service.dart | Login, register, session restore, admin login |
| Admin PIN service | lib/services/admin_pin_service.dart | PIN persistence |
| Session data | lib/core/session_data.dart | Bulk-fetch cache |
| Consumer home screen | lib/screens/consumer/consumer_home_screen.dart | Gauge + vendor list |
| Consumer cylinder screen | lib/screens/consumer/consumer_cylinder_screen.dart | Cylinder tracking + add/edit |
| Role router | lib/screens/role_router.dart | Routes admin/vendor/consumer |
| Theme builder | lib/core/theme.dart | Light/dark `ThemeData`, Forest Green, app bar/dialog/input themes |
| Theme controller | lib/core/theme_controller.dart | Riverpod `StateNotifier<ThemeMode>` + persistence |
| Theme tokens | lib/core/app_colors.dart | Forest Green palette + dark mode tokens |
| Status tokens | lib/core/theme_status_colors.dart | Success/warning/info `ThemeExtension` for light and dark |
| Theme helpers | lib/core/theme_ext.dart | `context.colors`, `context.gasColors`, `context.isDark` |
| Theme picker | lib/widgets/theme_mode_button.dart | System/Light/Dark picker |
| Admin console | lib/screens/admin/ | Phase 2 shell and operational screens |
| Admin service | lib/services/admin_service.dart | Vendor lifecycle, orders, consumers, analytics, audit |
| Analytics | lib/services/analytics_service.dart | KPI definitions, trends, demand mix, CSV export |
| Roadmap | ROADMAP.md | Project roadmap and later phases |

---

## 🎯 Current Gaps (Priority Order)

### 🚧 Phase 2 — Admin & Operations Console
- Replacing the admin stub with a responsive operations console.
- Vendor lifecycle + KYC review with audit logging.
- Global orders, consumer lookup, inventory visibility, settings.
- Operational analytics: 7/30/90-day KPIs, trends, top vendors, demand mix,
  district performance, vendor scorecards, CSV export.
- Plan: `phases/phase-02-admin-panel/plan.md`.

### ❌ Phase 3 — Vendor Verified Role
- No verified field in Vendor model.
- Target: Add verified field, set via admin panel, display on consumer side.

### ⚠️ Phase 4 — Vendor Settings
- No vendor settings screen.
- Target: Commission toggle (subscription vs percentage), profile management,
  image upload.

---

## 🔜 Immediate Next Steps

1. Finish Phase 2 implementation and record it in
   `phases/phase-02-admin-panel/implementation.md`.
2. Update this file with verified Phase 2 evidence and test results.
3. Phase 3 — vendor verified role.
4. Phase 4 — vendor settings and profile.
