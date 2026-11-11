# GasLink — Project Guide

> **Last updated:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Primary reference:** `PROGRESS.md` is the authoritative master file for this project.

---

## 📖 How to Use This Project

This is a **documentation-first project**: plan before code, record after code.

1. Read `PROGRESS.md` to understand the current state.
2. Create or update `plan.md` before starting a phase.
3. Build the phase.
4. Write `implementation.md` after the phase.

### Reference Hierarchy

| File | Role | When to Update |
|------|------|----------------|
| **`PROGRESS.md`** | **Master reference** — authoritative status, verified working items, gaps, next steps | Every 2 weeks or when major changes occur |
| **`ROADMAP.md`** | Project-wide roadmap and phase status | When priorities or phase status change |
| `phases/<phase-name>/plan.md` | Per-phase implementation plan — what the issue is, why it matters, how to fix | When starting a new phase |
| `phases/<phase-name>/implementation.md` | Per-phase implementation record — what was done, steps taken, problems/pivots | **After** each phase is implemented |

**Rule:** `PROGRESS.md` is the master. If `implementation.md` says one thing but `PROGRESS.md` says another, `PROGRESS.md` wins.

---

## 🔑 Key Reference Points

### Verified Working (already done)

| # | Feature | Reference |
|---|---------|-----------|
| 1 | Auth Persistence | `lib/services/auth_service.dart` |
| 2 | Session Persistence | `lib/services/admin_pin_service.dart` |
| 3 | Admin PIN Integration | `lib/services/auth_service.dart` + `lib/services/admin_pin_service.dart` |
| 4 | Home Screen Gauge (collective) | `lib/screens/consumer/consumer_home_screen.dart` + `lib/utils/cylinder_fifo.dart` |
| 5 | Cylinder Smart Hub (collective) | `lib/screens/consumer/consumer_cylinder_screen.dart` + `lib/utils/cylinder_fifo.dart` |
| 6 | Order Statuses | `lib/core/constants.dart` |
| 7 | Role Router | `lib/screens/role_router.dart` |
| 8 | Circle FIFO | `lib/utils/cylinder_fifo.dart` |
| 9 | Theme System | `lib/core/theme.dart`, `lib/core/theme_controller.dart`, `lib/core/theme_ext.dart` |
| 10 | Admin Console | `lib/screens/admin/`, `lib/services/admin_service.dart`, `lib/core/admin_guard.dart` |
| 11 | Operational Analytics | `lib/services/analytics_service.dart`, `lib/models/analytics.dart` |
| 12 | Admin Inventory & Audit | `lib/screens/admin/admin_inventory_screen.dart`, `lib/screens/admin/admin_audit_log_screen.dart` |
| 13 | Vendor Verification | `lib/models/vendor.dart`, `lib/services/admin_service.dart`, `lib/widgets/verified_badge.dart` |
| 14 | Vendor Settings & Commission | `lib/screens/vendor/vendor_settings_screen.dart`, `lib/services/vendor_image_service.dart`, `storage.rules` |
| 15 | Notifications & Offline | `lib/core/notification_routing.dart`, `lib/widgets/offline_banner.dart` |
| 16 | Landing, Design Kit & Ads | `lib/screens/auth/landing_screen.dart`, `lib/widgets/app_ui.dart`, `lib/widgets/ad_slot.dart` |
| 17 | Guest vs Consumer | `lib/core/session_gate.dart`, `lib/services/auth_service.dart` |
| 18 | Vendor Catalogue | `lib/services/catalog_service.dart`, `lib/utils/service_normalizer.dart` |

### Planned (awaiting owner approval — **not started, zero code written**)

- Phase 5C: `phases/phase-05c-consumer-completeness/plan.md`
- Phase 5D: `phases/phase-05d-vendor-growth/plan.md`

### Current Gaps (priority order)

| Priority | Item | Reference |
|----------|------|-----------|
| 🛑 | Phase 5C — Auth flow & consumer completeness (not started) | `phases/phase-05c-consumer-completeness/plan.md` (awaiting approval) |
| 🛑 | Phase 5D — Vendor polish & growth hooks (not started) | `phases/phase-05d-vendor-growth/plan.md` (awaiting approval) |
| 🟡 | Phase 6 — Scale/security hardening | Firestore rules, server-side admin checks, analytics rollups, pagination, subscription billing |

---

## 🛡 Rollback Strategy

### Best Rollback Option (Simple)

**`git revert <commit-hash>`** — creates a new commit that undoes the changes. Safe, doesn't destroy history.

### File-Level Rollback (if you only broke one file)

**`git checkout <commit-hash> -- <file>`** — restores a specific file from a previous commit.

### Full Rollback (if everything is broken)

**`git reset --hard <commit-hash>`** — resets to a specific commit. **Destroys uncommitted changes.** Only use if you're sure.

### Pick a Rollback Point

```bash
# See all commits
git log --oneline

# Undo the most recent commit
git revert HEAD

# Restore a file from a previous commit
git checkout e835912 -- lib/app.dart
```

**Keep a few commits as checkpoints.** The git history is your backup. Push to remote before making risky changes.

---

> **Reminder:** `PROGRESS.md` is the master. When in doubt, always read `PROGRESS.md` first.


## 🚀 Workflow Summary

1. Read `PROGRESS.md`
   → Check Summary Status and Current Gaps.
2. Pick the first incomplete phase.
3. Read `phases/<phase-name>/plan.md` → Understand the plan.
4. Implement → Write code, no docs.
5. Write `phases/<phase-name>/implementation.md` → Document what you did.
6. Update `PROGRESS.md` → Move the phase from 🚧 to ✅ in Summary Status.
7. Commit and push → `git add -A && git commit -m "..." && git push`.

---

## 🏷 Checkpoints

Record phase rollback points here after each push.

| Checkpoint | Commit | Remote | Notes |
|---|---|---|---|
| Phase 1 + docs baseline | `4c89d66` | `origin/harden-source-of-truth` | Pre-Phase 2 rollback point |
| Phase 2 code | `5bed4fb` | `origin/harden-source-of-truth` | Admin & Operations Console + analytics |
| Phase 2 docs | `0ca4080` | `origin/harden-source-of-truth` | Implementation record and status updates (pushed) |
| Phase 2 push point | `20174c7` | `origin/harden-source-of-truth` | Pre-Phase 3 rollback point |
| Phase 3 code | `645126d` | `origin/harden-source-of-truth` | Vendor verified role + tests (pushed) |
| Phase 3 docs | `4a93d24` | `origin/harden-source-of-truth` | Implementation record and status updates (pushed) |
| Phase 3 push point | `7d53a0f` | `origin/harden-source-of-truth` | Pre-Phase 4 rollback point |
| Phase 4 code | `2aeb359` | `origin/harden-source-of-truth` | Vendor settings, commission, photo upload (pushed) |
| Phase 4 docs | `c72ee3b` | `origin/harden-source-of-truth` | Implementation record and status updates (pushed) |
| Phase 4 push point | `dcaed5a` | `origin/harden-source-of-truth` | Pre-Phase 5 rollback point |
| Phase 5 code | `04f539a` | `origin/harden-source-of-truth` | Notification routing, banners, offline, a11y (pushed) |
| Phase 5 docs | `0f6ea00` | `origin/harden-source-of-truth` | Implementation record and status updates (pushed) |
| Phase 5B fixes A–C | `5c7ae57` | `origin/harden-source-of-truth` | Catalogue, service count, guest split (pushed) |
| Phase 5B design + landing | `2f30d8b` | `origin/harden-source-of-truth` | Design kit, landing page (pushed) |
| Phase 5B restyles | `5e2c6d2` | `origin/harden-source-of-truth` | Vendor detail, home, dashboard (pushed) |
| Phase 5B ads | `c1f44a8` | `origin/harden-source-of-truth` | Ad slots, AdvertiseScreen, admin review (pushed) |
| Phase 5B docs | `5e30bb5` | `origin/harden-source-of-truth` | Implementation record and status updates (pushed) |
| Phase 5B push point | `aa48414` | `origin/harden-source-of-truth` | Pre-auth-flow-fix rollback point |
| Auth flow + layout fixes | `31654dc` | `origin/harden-source-of-truth` | Blended login, order header, dashboard KPIs (pushed) |
| Launcher + rearrange | `cbae13e` | `origin/harden-source-of-truth` | Logo icons, landing rebalance, home/dashboard restructure (pushed) — **current head** |
---
