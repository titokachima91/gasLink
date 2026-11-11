# GasLink — Project Roadmap

> **Last updated:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Master status:** [`PROGRESS.md`](PROGRESS.md)
> **Current focus:** Phase 6 — Scale & Security Hardening
> **Phase 1:** ✅ Theme overhaul complete
> **Phase 2:** ✅ Admin & Operations Console complete
> **Phase 3:** ✅ Vendor verified role complete
> **Phase 4:** ✅ Vendor settings & profile complete
> **Phase 5:** ✅ Notifications & polish complete

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

## 🔜 Later Phases

### Phase 6 — Scale & Security Hardening

- Firestore security rules and Cloud Functions for server-side admin checks.
- Daily analytics rollups and scheduled exports.
- Multi-country/multi-currency configuration.
- Rider dispatch, payments, payouts, and settlement.

---

## 🧭 Working Agreement

- `PROGRESS.md` remains the authoritative status file.
- Each phase gets a `plan.md` before code and an `implementation.md` after.
- Do not mix unrelated phases in one change set.
- Every UI change must be checked in light and dark mode.
- Keep `flutter analyze` free of errors and `flutter test` green.
- Record a rollback commit before starting a large phase.
