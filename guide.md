# GasLink — Project Guide

> **Last updated:** 11/09/2026  
> **Branch:** `harden-source-of-truth`  
> **Primary reference:** `PROGRESS.md` is the authoritative master file for this project.

---

## 📖 How to Use This Project

This project documents GasLink — a Flutter + Firebase application for LPG gas distribution in Dar es Salaam, Tanzania.

### Reference Hierarchy

| File | Role | Update Frequency |
|------|------|------------------|
| **`PROGRESS.md`** | **Master reference** — authoritative status, verified working items, gaps, next steps | Every 2 weeks or when major changes occur |
| `phases/plan.md` | Per-phase implementation plan — what the issue is and how to fix | When starting a new phase or when requirements change |
| `phases/implementation.md` | Per-phase implementation record — what was done, each step, problems/pivots, what was accomplished | **After** each phase is implemented |
| `PHASE_*.md` | **REMOVED** — redundant; all content moved to `progress.md` + `phases/` |

---

## 📋 Phase Structure

Each phase in `phases/<phase-name>/` contains two files:

### `plan.md` — The Plan

What the issue is, why we need to fix it, and how we plan to do it.

| Section | Purpose |
|---------|---------|
| Issue Description | What's broken or missing |
| Why It Matters | Business/technical impact |
| Proposed Solution | Approach |
| Steps | Detailed implementation steps |
| Risk | What could go wrong |
| Estimated Effort | Time to complete |

### `implementation.md` — The Record

What was done after the build.

| Section | Purpose |
|---------|---------|
| Status | ✅ Done / ❌ Not started / ⚠️ Partly done |
| What Was Accomplished | Summary of work |
| Step-by-Step | Each step with outcome |
| Problems Encountered | Issues or bugs found |
| Pivots Taken | When we changed direction |
| Code Evidence | Files modified, key code snippets |
| Next Step | What remains for this phase |

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

### Current Gaps (priority order)

| Priority | Item | Reference |
|----------|------|-----------|
| 🔴 | Theme Overhaul | `lib/core/theme.dart` (still `Colors.orange`) |
| 🔴 | Admin Panel | `lib/screens/role_router.dart` (11-line stub) |
| 🔴 | Vendor verified Role | `lib/models/vendor.dart` (no `verified` field) |
| 🟡 | Analytics Service | No file exists |
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
## Rollback Strategy
