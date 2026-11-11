# GasLink — Master Progress Report

> **Last updated:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Project state:** Working Flutter + Firebase application for LPG gas distribution in Dar es Salaam, Tanzania.
> **Documentation:** [`ROADMAP.md`](ROADMAP.md) is the high-level project plan; `phases/<phase>/` holds per-phase plans and implementation records. This file is the authoritative status tracker.
> **Theme:** Phase 1 complete — see `phases/phase-01-theme/implementation.md`.
> **Admin console:** Phase 2 complete — see `phases/phase-02-admin-panel/implementation.md`.
> **Vendor verification:** Phase 3 complete — see `phases/phase-03-vendor-verified/implementation.md`.
> **Vendor settings:** Phase 4 complete — see `phases/phase-04-vendor-settings/implementation.md`.
> **Current phase:** Phase 5 — Notifications & Polish (next).

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
| Admin & Operations Console | ✅ **Complete** — responsive shell, dashboard, vendors, orders, consumers, inventory, settings, audit, guard |
| Operational Analytics | ✅ **Complete** — 7/30/90-day KPIs, trends, scorecards, demand mix, CSV export |
| Vendor verified Role | ✅ **Complete** — explicit `verified` field, audited admin action, consumer badges, real verified-only filter |
| Vendor Settings & Profile | ✅ **Complete** — settings screen, admin-controlled commission model, secure Storage photo upload |
| Vendor Profile | ✅ **Complete** — profile management plus gallery photo upload to Firebase Storage |
| Stock Visibility | ✅ **Complete** — vendor stock writes normalized; admin inventory aggregation and out-of-stock view shipped |

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
| 12 | Admin console | `admin_shell.dart` routes admins; compact bottom navigation and wide `NavigationRail`; `AdminGuard` blocks non-admin roles |
| 13 | Vendor lifecycle | `Vendor.status` (`pending/active/suspended/rejected`), KYC review fields, reason-required reject/suspend, audited transitions |
| 14 | Global orders | Search/status/district/date filters; detail timeline; audited cancellation with reason; delivered orders protected |
| 15 | Consumers | Search/list/detail, order history, cylinder holdings, lifetime delivered value; no PIN material loaded |
| 16 | Operational analytics | `AnalyticsService` fixed definitions; 7/30/90-day KPIs, trend, status mix, top vendors, demand, districts, scorecards, CSV |
| 17 | Inventory & settings | Brand/size aggregation with out-of-stock filter and vendor offers; commission/support settings with audit trail |
| 18 | Admin test coverage | `test/admin_console_test.dart` (6) + `test/analytics_test.dart` (5); full suite 41/41 passing; analyzer 0 errors / 0 warnings |
| 19 | Vendor verification | `Vendor.verified/verifiedAt/verifiedBy`; audited `verify_vendor`/`unverify_vendor`; consumer badges gated by the flag; `verifiedOnly` filter uses the field |
| 20 | Commission model | `Vendor.commissionModel/subscriptionFee`; admin-only editor with audit; orders stamp `commission_model`; subscription vendors pay no per-order cut |
| 21 | Vendor settings | `vendor_settings_screen.dart` with billing terms, profile shortcut, theme, notifications, about, sign-out; wired from dashboard and drawer |
| 22 | Shop photo upload | `VendorImageService` uploads to Storage (`vendor_images/`) with 5 MB/image-type rules; picker + preview in profile |

### Hardcoded Login (Seed Credential)

- Phone: 0767304776 (or +255767304776)
- PIN: 0000
- Route: login -> auth_service.dart -> adminLogin() -> AuthService.roleAdmin
- **Follow-up:** replace with secure server-side admin identity before production.

### Phase 2 Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | 41/41 passing |
| Admin/analytics tests | 11 new tests (6 admin console, 5 analytics) |
| Responsive shell | 400×800 bottom navigation; 1280×900 `NavigationRail` |
| Dark mode | Admin shell renders without exceptions |
| Manual device QA | Still recommended before pilot (local macOS/web build constraints) |

### Phase 3 Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | 45/45 passing |
| Vendor verification tests | 4 new tests: model round-trip, verified-only filter, badge light/dark, icon-only badge |
| Audit coverage | `verify_vendor` and `unverify_vendor` written in the same batch as the vendor update |
| Consumer gating | Badges render only when `verified == true` on all updated discovery surfaces |

### Phase 4 Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | 54/54 passing |
| Phase 4 tests | 9 new tests: commission model, order stamping, image validation, billing card variants |
| Admin commission | Percentage/subscription editor with audit record; list chips show model |
| Storage | `storage.rules` limits writes to authenticated users, `image/*`, < 5 MB |
| Runtime storage QA | Requires Firebase anonymous auth + `firebase deploy --only storage`; client degrades with a clear error |

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
| Admin shell | lib/screens/admin/admin_shell.dart | Responsive console navigation and admin entry point |
| Admin guard | lib/core/admin_guard.dart | Central client-side admin access check |
| Admin service | lib/services/admin_service.dart | Vendor lifecycle/verification/commission, orders, consumers, inventory, settings, audit |
| Vendor model | lib/models/vendor.dart | Lifecycle, KYC, verified trust fields, commission model |
| Verified badge | lib/widgets/verified_badge.dart | Shared consumer trust badge, gated by the vendor flag |
| Vendor settings | lib/screens/vendor/vendor_settings_screen.dart | Vendor settings with billing terms, theme, notifications, sign-out |
| Image upload | lib/services/vendor_image_service.dart | Storage upload with size/type validation and rules |
| Storage rules | storage.rules | Public reads; authenticated, size/type-limited writes |
| Admin models | lib/models/admin_models.dart | Audit log, consumer/product/cylinder/settings/dashboard projections |
| Analytics service | lib/services/analytics_service.dart | KPI definitions, trends, demand mix, CSV export |
| Analytics models | lib/models/analytics.dart | Reporting value objects and fixed timezone/currency |
| Admin UI kit | lib/screens/admin/widgets/admin_ui.dart | Cards, badges, filters, empty/error/loading states, formatters |
| Formatters | lib/utils/formatters.dart | TZS, percent, date/time, duration, initials |
| Admin tests | test/admin_console_test.dart | Guard, lifecycle, responsive shell, dark mode |
| Analytics tests | test/analytics_test.dart | KPI math, trend range, breakdowns, CSV |
| Verification tests | test/vendor_verified_test.dart | Model round-trip, verified-only filter, badge rendering |
| Vendor settings tests | test/vendor_settings_test.dart | Commission model, order stamping, image validation, billing card |
| Roadmap | ROADMAP.md | Project roadmap and later phases |

---

## 🎯 Current Gaps (Priority Order)

### ✅ Phase 2 — Admin & Operations Console (complete)
- Shipped and verified: shell/navigation, dashboard, vendor lifecycle + KYC,
  global orders, consumers, inventory, settings, audit trail, analytics, guard.
- Record: `phases/phase-02-admin-panel/implementation.md`.
- Follow-ups: Firestore rules/server-side admin enforcement, pagination,
  analytics daily rollups, secure admin identity.

### ✅ Phase 3 — Vendor Verified Role (complete)
- Shipped and verified: explicit `verified` flag, audited verify/unverify
  actions, admin indicators, consumer badges, real verified-only filter.
- Record: `phases/phase-03-vendor-verified/implementation.md`.
- Follow-ups: Firestore rules for `verified`, verification expiry/re-review,
  vendor-facing verification status panel.

### ✅ Phase 4 — Vendor Settings & Profile (complete)
- Shipped and verified: vendor settings screen, admin-controlled commission
  model with audit, order commission stamping, secure Storage photo upload.
- Record: `phases/phase-04-vendor-settings/implementation.md`.
- Follow-ups: subscription billing/invoicing (Phase 6), server-side storage
  path ownership (Phase 6), Storage retention cleanup, Firebase console
  enablement (anonymous auth + storage rules deploy).

### ⚠️ Phase 5 — Notifications & Polish
- Notification routing polish, offline/error states, performance and
  accessibility pass.

---

## 🔜 Immediate Next Steps

1. Phase 5 — notifications and polish.
2. Scale/security hardening: Firestore rules, server-side admin checks, daily
   analytics rollups, order pagination, secure admin identity, subscription
   billing.
