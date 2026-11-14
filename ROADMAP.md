# GasLink — Project Roadmap

> ⚠️ **Current planning lives in [`PROJECT_BIBLE.md`](PROJECT_BIBLE.md)** and
> **[`HANDOFF.md`](HANDOFF.md)**. This roadmap is historical through 12 Nov 2026.
> Current source includes Phase 5E D1/D2 and the Phase 5F SMS/AI gateway
> foundation; D3/D4 localization and OTP wiring remain; Phase 6 is parked on
> Spark/Blaze.
>
> **Last updated:** 2026-11-12
> **Branch:** `harden-source-of-truth`
> **Master status:** [`PROGRESS.md`](PROGRESS.md)
> **Build runbook:** [`BUILD.md`](BUILD.md)
> **Current focus:** Phase 5E approved — UX refinements & selectable language (implementation starting); Phase 6 parked (Firebase project is on Spark)
> **Phase 1:** ✅ Theme overhaul complete
> **Phase 2:** ✅ Admin & Operations Console complete
> **Phase 3:** ✅ Vendor verified role complete
> **Phase 4:** ✅ Vendor settings & profile complete
> **Phase 5:** ✅ Notifications & polish complete
> **Phase 5B:** ✅ App polish & first impressions complete
> **Phase 5C:** ✅ Auth flow & consumer completeness complete
> **Phase 5D:** ✅ Vendor polish & growth hooks complete

This roadmap is the high-level project plan. Detailed implementation records live in
`phases/<phase>/plan.md` and `phases/<phase>/implementation.md`.

---

## 📍 Where We Are

| Layer | Status |
|---|---|
| App startup / Riverpod scope | ✅ Complete |
| Light / Dark / System `ThemeMode` wiring | ✅ Complete |
| Theme persistence (`shared_preferences`) | ✅ Complete |
| Theme picker (login, consumer, vendor, admin, settings) | ✅ Complete |
| Light + dark design tokens | ✅ Complete |
| Screen-level theme migration | ✅ Complete |
| Theme QA / guardrails | ✅ Complete (automated guard + startup smoke) |
| Admin & Operations Console | ✅ Complete — Phase 2 |
| Vendor verification | ✅ Complete — Phase 3 |
| Vendor settings & commission | ✅ Complete — Phase 4 |
| Notifications & polish | ✅ Complete — Phase 5 |
| App polish & first impressions | ✅ Complete — Phase 5B |
| Auth flow & consumer completeness | ✅ Complete — Phase 5C |
| Vendor polish & growth hooks | ✅ Complete — Phase 5D |

---

## ✅ Phase 1 — Theme Overhaul (COMPLETE)

Record: [`phases/phase-01-theme/implementation.md`](phases/phase-01-theme/implementation.md)

- Forest Green palette with light/dark/system modes.
- Theme preference persists across restarts.
- Semantic success/warning/info tokens registered for both brightnesses.
- Every screen and shared widget uses `context.colors` / `context.gasColors`.
- Legacy-color guard test and startup smoke check pass.
- `flutter analyze` has zero errors and warnings; `flutter test` passes.

---

## ✅ Phase 2 — Admin & Operations Console (COMPLETE)

Record: [`phases/phase-02-admin-panel/implementation.md`](phases/phase-02-admin-panel/implementation.md)

The admin stub has been replaced with a responsive operations console:

- Admin shell with responsive navigation.
- Operational dashboard.
- Vendor lifecycle and KYC review.
- Global orders oversight.
- Consumer lookup.
- Inventory visibility.
- Operational analytics with CSV export.
- Admin settings, audit trail, and admin route guard.

### Milestones

| Milestone | Deliverable | Status |
|---|---|---|
| **A. Foundation** | Shell, routing, `AdminService`, audit model, guard | ✅ |
| **B. Vendors** | List, filters, detail, KYC review, lifecycle actions | ✅ |
| **C. Operations** | Orders list/detail/cancel; consumers list/detail | ✅ |
| **D. Analytics** | KPIs, trends, vendor scorecards, demand mix, CSV export | ✅ |
| **E. Visibility** | Inventory overview, settings, final admin polish | ✅ |
| **F. Hardening** | Empty/error states, tests, docs, light/dark QA | ✅ |

Analytics is a first-class part of Phase 2, not a later standalone phase. Its
metric definitions, timezone (`Africa/Dar_es_Salaam`), and currency (TZS) are
fixed in code so reporting stays consistent as the product scales.

Verification at close: `flutter analyze` 0 errors / 0 warnings; `flutter test`
41/41 passing, including 11 new admin/analytics tests.

---

## ✅ Phase 3 — Vendor Verified Role (COMPLETE)

Record: [`phases/phase-03-vendor-verified/implementation.md`](phases/phase-03-vendor-verified/implementation.md)

- `Vendor` stores `verified`, `verifiedAt`, and `verifiedBy`.
- Admins verify active vendors or remove verification with a required reason.
- `verify_vendor` and `unverify_vendor` are written to the audit trail.
- Consumer badges render only when the stored flag is true.
- The consumer "Verified only" filter uses the real field instead of phone
  presence.

Verification at close: `flutter analyze` 0 errors / 0 warnings; `flutter test`
45/45 passing, including 4 new Phase 3 tests.

---

## ✅ Phase 4 — Vendor Settings & Profile (COMPLETE)

Record: [`phases/phase-04-vendor-settings/implementation.md`](phases/phase-04-vendor-settings/implementation.md)

- Admin-controlled commission model: percentage or monthly subscription,
  editable per vendor with audit trail.
- Orders stamp the vendor's model; subscription vendors pay no per-order cut.
- Vendor settings screen with read-only billing terms, profile shortcut,
  theme, notifications, about, and sign-out.
- Secure shop photo upload via Firebase Storage with picker, preview, and
  size/type rules.

Verification at close: `flutter analyze` 0 errors / 0 warnings; `flutter test`
54/54 passing, including 9 new Phase 4 tests.

---

## ✅ Phase 5 — Notifications & Polish (COMPLETE)

Record: [`phases/phase-05-notifications/implementation.md`](phases/phase-05-notifications/implementation.md)

- Role-aware tap-through routing for order notifications.
- In-app banner for foreground notifications with a "View" action.
- Background tap and cold-start message handling via the global navigator.
- Offline banner on consumer home, vendor dashboard, and admin shell.
- Accessibility polish on the vendor store status toggle.

Verification at close: `flutter analyze` 0 errors / 0 warnings; `flutter test`
58/58 passing, including 4 new Phase 5 tests.

---

## ✅ Phase 5B — App Polish & First Impressions (COMPLETE)

Record: [`phases/phase-05b-app-polish/implementation.md`](phases/phase-05b-app-polish/implementation.md)

- Fixed the vendor/consumer catalogue split and the corrupted brand doc ids.
- Fixed the extra-services count (weighing consent no longer counts).
- Guests browse read-only; ordering and tracking require an account.
- Landing page for visitors with login/register/guest entry points.
- Design kit + restyled vendor detail (all sizes visible), consumer home,
  and vendor dashboard (KPI grid + empty states).
- Audience-aware, dismissible ad slots plus a stakeholder request screen and
  an admin review queue.

Verification at close: `flutter analyze` 0 errors / 0 warnings; `flutter test`
75/75 passing, including 12 new Phase 5B tests. No business logic changed —
cylinder hub, FIFO measurement, and order flows are untouched.

---

## ✅ Phase 5C — Auth Flow Polish & Consumer Completeness (COMPLETE)

Record: [`phases/phase-05c-consumer-completeness/implementation.md`](phases/phase-05c-consumer-completeness/implementation.md)

Dedicated branded login/register with required Terms acceptance and optional
ads consent, consumer Settings/Profile screens, polished history and cylinder
hub, and the planned home reorder. Analyzer 0 errors / 0 warnings, 79/79 tests
passing. No business logic changed.

## ✅ Phase 5D — Vendor Polish & Growth Hooks (COMPLETE)

Record: [`phases/phase-05d-vendor-growth/implementation.md`](phases/phase-05d-vendor-growth/implementation.md)

Vendor drawer/dashboard/badge/inventory/orders/profile restyles, verification
status card, GasPlan kwa Waajiriwa teaser (Settings → Features only, writes
`ajira_interest`), and the consumer/vendor referral foundation with
deterministic codes and the `referrals` collection. Rewards are explicitly
"coming soon". Analyzer 0 errors / 0 warnings, 85/85 tests passing, release APK
built with `share_plus 10.1.4` and the Feb 2025 FlutterFire set (BoM 33.8.0) on
the unchanged Flutter 3.24.5 / AGP 8.3 / Kotlin 1.9.22 toolchain.

## 🚧 Phase 5E — UX Refinements & Selectable Language (APPROVED)

Plan: [`phases/phase-05e-ux-refinements/plan.md`](phases/phase-05e-ux-refinements/plan.md)

Plan only — no code written. Covers the referral-card position before
“Unataka kufanya nini?”, a progressive stock list (10 items, +10 per “View
more”), guest Profile/Settings routing to login/register, a full back-navigation
audit, registration-only Terms and push-marketing consent, Terms kept under
About, and the migration from bilingual labels to a real selectable locale
(Kiswahili / English).

---

## 🔜 Later Phases

### ⏸️ Phase 6 — Scale & Security Hardening (parked)

Plan: [`phases/phase-06-scale-security/plan.md`](phases/phase-06-scale-security/plan.md)

**Parked 12 Nov 2026** — the Firebase project is on the free Spark plan.
The prerequisite identity bridge needs Cloud Functions and custom tokens
(Blaze).

- **6A identity bridge:** phone+PIN login exchanged for a Firebase custom token
  so rules can identify the caller.
- Firestore security rules and Storage path ownership.
- Cloud Functions for server-side admin checks and audit logs.
- Pagination and daily analytics rollups.
- Billing design; multi-country/multi-currency, rider dispatch, payments,
  payouts, and settlement remain later work.

---

## 🧭 Working Agreement

- `PROGRESS.md` remains the authoritative status file.
- Each phase gets a `plan.md` before code and an `implementation.md` after.
- Do not mix unrelated phases in one change set.
- Every UI change must be checked in light and dark mode.
- Keep `flutter analyze` free of errors and `flutter test` green.
- Record a rollback commit before starting a large phase.
