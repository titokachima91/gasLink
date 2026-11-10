# GasLink — Project Roadmap

> **Last updated:** 2026-11-10
> **Branch:** `harden-source-of-truth`
> **Master status:** [`PROGRESS.md`](PROGRESS.md)
> **Current focus:** Phase 2 — Admin & Operations Console
> **Phase 1:** ✅ Theme overhaul complete

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
| Admin & Operations Console | 🚧 In progress — Phase 2 |

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

## 🚧 Phase 2 — Admin & Operations Console

Plan: [`phases/phase-02-admin-panel/plan.md`](phases/phase-02-admin-panel/plan.md)

Replace the admin stub with a professional operations console:

- Admin shell with responsive navigation.
- Operational dashboard.
- Vendor lifecycle and KYC review.
- Global orders oversight.
- Consumer lookup.
- Inventory visibility.
- Operational analytics with CSV export.
- Admin settings, audit trail, and admin route guard.

### Milestones

| Milestone | Deliverable |
|---|---|
| **A. Foundation** | Shell, routing, `AdminService`, audit model, guard |
| **B. Vendors** | List, filters, detail, KYC review, lifecycle actions |
| **C. Operations** | Orders list/detail/cancel; consumers list/detail |
| **D. Analytics** | KPIs, trends, vendor scorecards, demand mix, CSV export |
| **E. Visibility** | Inventory overview, settings, final admin polish |
| **F. Hardening** | Empty/error states, tests, docs, light/dark QA |

Analytics is a first-class part of Phase 2, not a later standalone phase. Its
metric definitions, timezone (`Africa/Dar_es_Salaam`), and currency (TZS) are
fixed in code so reporting stays consistent as the product scales.

---

## 🔜 Later Phases

### Phase 3 — Vendor Verified Role

- Add `verified` to the vendor model.
- Set/clear verification from the admin console.
- Show a verified badge on consumer-facing vendor cards and details.

### Phase 4 — Vendor Settings & Profile

- Commission model toggle (subscription vs percentage).
- Profile management.
- Image upload.

### Phase 5 — Notifications & Polish

- Push notification routing polish.
- Offline/error states.
- Performance and accessibility pass.

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
