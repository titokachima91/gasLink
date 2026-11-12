# GasLink — Master Progress Report

> **Last updated:** 2026-11-12
> **Branch:** `harden-source-of-truth`
> **Project state:** Working Flutter + Firebase application for LPG gas distribution in Dar es Salaam, Tanzania.
> **Documentation:** [`ROADMAP.md`](ROADMAP.md) is the high-level project plan; `phases/<phase>/` holds per-phase plans and implementation records. This file is the authoritative status tracker.
> **Build:** [`BUILD.md`](BUILD.md) is the release-build and troubleshooting runbook for this Mac.
> **Theme:** Phase 1 complete — see `phases/phase-01-theme/implementation.md`.
> **Admin console:** Phase 2 complete — see `phases/phase-02-admin-panel/implementation.md`.
> **Vendor verification:** Phase 3 complete — see `phases/phase-03-vendor-verified/implementation.md`.
> **Vendor settings:** Phase 4 complete — see `phases/phase-04-vendor-settings/implementation.md`.
> **Notifications & polish:** Phase 5 complete — see `phases/phase-05-notifications/implementation.md`.
> **App polish:** Phase 5B complete — see `phases/phase-05b-app-polish/implementation.md`.
> **Consumer completeness:** Phase 5C complete — see `phases/phase-05c-consumer-completeness/implementation.md`.
> **Vendor growth:** Phase 5D complete — see `phases/phase-05d-vendor-growth/implementation.md`.
> **Current phase:** Phase 5E **approved** — UX refinements & selectable language (implementation starting). Phase 6 is parked — the Firebase project is on the free Spark plan; 6A needs Blaze.

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
| Notifications & Polish | ✅ **Complete** — tap-through routing, in-app banners, offline banners, store-toggle semantics |
| App Polish & First Impressions | ✅ **Complete** — landing page, guest/consumer split, catalogue & service fixes, restyled screens, audience-aware ads |
| Vendor Catalogue Consistency | ✅ **Complete** — merged inventory view; consumers see everything vendors manage |
| Auth Flow & Consumer Completeness | ✅ **Complete (5C)** — dedicated login/register with consent, consumer settings/profile, home reorder, polished history/cylinders |
| Vendor Polish & Growth Hooks | ✅ **Complete (5D)** — vendor restyles, GasPlan kwa Waajiriwa teaser, referral foundation |
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
| 23 | Notification routing | Role-aware tap-through: admin → order detail, vendor → orders, consumer → live tracker; cold-start + background taps |
| 24 | In-app banners | Foreground order notifications show a MaterialBanner with a View action |
| 25 | Offline visibility | `OfflineBanner` on consumer home, vendor dashboard, and admin shell via `connectivity_plus` |
| 26 | Accessibility | Semantics on the vendor OPEN/CLOSED toggle; tooltips on admin and vendor app bar actions |
| 27 | Catalogue fix | `CatalogService` merged view; brand editor doc ids fixed + legacy cleanup; dashboard stock reads top-level |
| 28 | Service-count fix | `normalizeOfferedServices` maps legacy entries; badge Tier 1 rows computed from real data |
| 29 | Guest separation | `SessionGate.requireConsumer` gates all order CTAs; guest home shows sign-in banner instead of tracker/gauges |
| 30 | Landing page | Hero, value props, how-it-works, districts, ads, login/register/guest entry |
| 31 | Ad framework | Audience-aware `AdSlot`, `AdvertiseScreen` request form, admin review queue |
| 32 | Launcher branding | GasLink logo replaces the default Flutter icon on Android/iOS/web/macOS; bundled as an asset |
| 33 | Landing rebalance | Details first; compact login/register/guest links on top; logout returns to the landing page |
| 34 | Home & dashboard rearrange | Consumer home section headers + richer vendor cards; vendor dashboard KPI grid, quick actions, empty states |

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

### Phase 5 Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | 58/58 passing |
| Phase 5 tests | 4 new tests: payload parsing, role routing, offline banner show/hide, dark mode |
| Tap-through | Handled via FCM APIs; live-device QA recommended before pilot |

### Phase 5B Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 49 pre-existing info lints |
| `flutter test` | 75/75 passing |
| Phase 5B tests | 12 new: catalog merge, service normalizer, session gate, landing, ad slot |
| Logic safety | `cylinder_fifo.dart`, `OrderService`, and `AuthService` flows untouched |
| Guest gating | All order CTAs route through `SessionGate` |

### Post-5B follow-ups (commits `31654dc`, `cbae13e`)

| Change | Evidence |
|---|---|
| Blended login moved out of landing | Landing now has only small entry links; login/register are dedicated screens (Phase 5C) |
| Order manager header fix | Bounded phone button + ellipsis on ODA header |
| Dashboard KPI fix | Metric cards no longer misuse `Expanded` inside the grid |
| Launcher icons | Logo applied to Android/iOS/web/macOS icons |
| Landing rebalance + home/dashboard rearrange | Section headers, quick actions grid, richer vendor cards |
| Verification | `flutter analyze` 0 errors / 0 warnings; `flutter test` 75/75; APK builds cleanly |

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
| Notification routing | lib/core/notification_routing.dart | Role-aware order tap destinations |
| Offline banner | lib/widgets/offline_banner.dart | Injectable connectivity stream |
| Design kit | lib/widgets/app_ui.dart | Cards, section headers, pills, empty states, skeletons |
| Landing page | lib/screens/auth/landing_screen.dart | Visitor first impression |
| Session gate | lib/core/session_gate.dart | Guest vs consumer enforcement |
| Catalogue service | lib/services/catalog_service.dart | Merged vendor catalogue |
| Ad framework | lib/widgets/ad_slot.dart, lib/services/ad_service.dart | Audience-aware slots + requests |
| Admin models | lib/models/admin_models.dart | Audit log, consumer/product/cylinder/settings/dashboard projections |
| Analytics service | lib/services/analytics_service.dart | KPI definitions, trends, demand mix, CSV export |
| Analytics models | lib/models/analytics.dart | Reporting value objects and fixed timezone/currency |
| Admin UI kit | lib/screens/admin/widgets/admin_ui.dart | Cards, badges, filters, empty/error/loading states, formatters |
| Formatters | lib/utils/formatters.dart | TZS, percent, date/time, duration, initials |
| Admin tests | test/admin_console_test.dart | Guard, lifecycle, responsive shell, dark mode |
| Analytics tests | test/analytics_test.dart | KPI math, trend range, breakdowns, CSV |
| Verification tests | test/vendor_verified_test.dart | Model round-trip, verified-only filter, badge rendering |
| Vendor settings tests | test/vendor_settings_test.dart | Commission model, order stamping, image validation, billing card |
| Notification routing tests | test/notification_routing_test.dart | Payload parsing and role mapping |
| Offline banner tests | test/offline_banner_test.dart | Show/hide with injected connectivity |
| Phase 5B tests | test/catalog_service_test.dart, test/service_normalizer_test.dart, test/session_gate_test.dart, test/landing_screen_test.dart, test/ad_slot_test.dart | Fixes, guest gate, landing, ads |
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

### ✅ Phase 5 — Notifications & Polish (complete)
- Shipped and verified: role-aware notification tap-through, in-app banners,
  offline banners, accessibility semantics.
- Record: `phases/phase-05-notifications/implementation.md`.
- Follow-ups: deep links, server-side notification preferences, full
  screen-reader audit.

### ✅ Phase 5B — App Polish & First Impressions (complete)
- Shipped and verified: catalogue/service/guest fixes, landing page, design
  kit, screen restyles, audience-aware ads with request + review flow.
- Record: `phases/phase-05b-app-polish/implementation.md`.
- Follow-ups: admin campaign creation form, ad image banners, legacy
  subcollection cleanup reminder for vendors.

### ✅ Phase 5C — Auth Flow Polish & Consumer Completeness (complete)
- Dedicated branded Login/Register with required Terms acceptance and optional
  ads consent (persisted per user), plus static Terms/Privacy pages.
- Consumer Settings (account, theme, notifications, ads, language, legal,
  support, sign out) and Profile (identity, member-since, quick links).
- Home order: Oda Zangu → Mitungi Yangu → Kikadirio cha Gesi → services → ad →
  items → vendors.
- Polished order history and cylinder Smart Hub headers/empty states.
- Record: `phases/phase-05c-consumer-completeness/implementation.md`.
- Verification: analyzer 0 errors / 0 warnings, 79/79 tests passing.
- Commits: `0e1f469`, `4123e28`, `5e5a374`, `64def5b`, `f536788`.

### ✅ Phase 5D — Vendor Polish & Growth Hooks (complete)
- Vendor drawer, dashboard, badge hub, inventory, order manager and profile
  restyled with the shared design kit; verification status card added.
- GasPlan kwa Waajiriwa teaser lives only in Consumer Settings → Vipengele;
  interest form writes to `ajira_interest`; share-with-HR via `share_plus`.
- Referral foundation: deterministic codes on users/vendors, `referrals`
  collection, shared card on consumer home, vendor dashboard and settings;
  consumer → vendor invite form; rewards marked coming soon.
- Record: `phases/phase-05d-vendor-growth/implementation.md`.
- Verification: analyzer 0 errors / 0 warnings, 85/85 tests passing, release
  APK built with `share_plus 10.1.4` and the Feb 2025 FlutterFire set
  (BoM 33.8.0; Kotlin 1.9 compatible, Flutter/AGP unchanged).
- Commits: `1fd5630`, `dd2f629`, `ec45524`, `f09d678`, plus the FlutterFire
  compatibility pin.

### 🚧 Phase 5E — UX Refinements & Selectable Language (approved)
- Plan: `phases/phase-05e-ux-refinements/plan.md` — **plan only, no code.**
- **A. Home hierarchy:** move the referral card before “Unataka kufanya nini?”
  so the service grid and stock list stay adjacent. Stock list shows 10 items
  and adds 10 per **“View more”** tap. On the vendor dashboard, the referral
  card moves below Incoming Orders.
- **B. Guest routing & back:** remove the dead-end Profile/Settings guard page;
  guests go straight to login/register. Audit back navigation so login returns
  to landing, guest home returns to landing, and vendor/admin roots prompt
  before exiting.
- **C. Consents & About:** Terms and **marketing consent** stay at registration
  only. Marketing consent covers push notifications, messages, tips and offers
  — not in-app ad slots. Remove the Ads switch and main Terms row from consumer
  settings; add an **About** screen with readable Terms and Privacy copies.
- **D. Language:** replace the bilingual `“Swahili / English”` UI with a real
  selectable locale (Kiswahili / English, more later), persisted and applied
  app-wide in four migration batches.
- Resolved: stock list +10, vendor referral below orders, Terms under About,
  marketing opt-in default off, dead-end page removed, default language =
  system locale with Swahili fallback.

### ⏸️ Phase 6 — Scale & Security Hardening (parked)
- Plan: `phases/phase-06-scale-security/plan.md`.
- **Parked 12 Nov 2026:** the Firebase project is on the free **Spark** plan.
  The prerequisite **6A identity bridge** (phone+PIN exchanged for a Firebase
  custom token via a callable function) requires **Blaze**.
- When resumed: Firestore/Storage rules, server-side admin checks, pagination,
  daily analytics rollups, and billing design.
- Known launch blocker: there is currently no `firestore.rules`; the pilot is
  not safe for untrusted public use until 6A–6B ship.
- Multi-country/multi-currency configuration, rider dispatch, payments,
  payouts, and settlement remain later work.

---

## 🔜 Immediate Next Steps

1. **Pilot testing:** install the 5D release APK and exercise consumer,
   vendor, and admin flows on real devices (see `BUILD.md` for the Wi-Fi
   serving command).
2. **Implement Phase 5E** in order: home hierarchy → guest routing
   → registration-only consents → localization batches D1–D4.
3. **Phase 6 is parked** until the Firebase project moves to Blaze: identity
   bridge, Firestore/Storage rules, server-side admin checks, pagination,
   analytics rollups, and billing design.
4. Replace the temporary hardcoded admin login with Firebase Auth + custom
   claims when Phase 6 resumes.
5. Production launch checklist: release keystore, legal review of
   Terms/Privacy, support channels, and store listings.
