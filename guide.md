# GasLink — Project Guide

> **Last updated:** 2026-11-10
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
| **`ROADMAP.md`** | Project-wide roadmap and Phase 1 completion checklist | When priorities or phase status change |
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

### Current Gaps (priority order)

| Priority | Item | Reference |
|----------|------|-----------|
| 🚧 | Admin & Operations Console (includes analytics) | `lib/screens/admin/`, `lib/services/admin_service.dart` |
| 🔴 | Vendor verified Role | `lib/models/vendor.dart` (no `verified` field) |
| 🟡 | Vendor Settings | No file exists |

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
| Phase 1 + docs baseline | _pending_ | `origin/harden-source-of-truth` | Pre-Phase 2 rollback point |
| Phase 2 complete | _pending_ | `origin/harden-source-of-truth` | Admin & Operations Console |
---
