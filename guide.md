# GasLink — Project Guide

> **Last updated:** 11/09/2026  
> **Branch:** `harden-source-of-truth`  
> **Primary reference:** `PROGRESS.md` is the authoritative master file for this project.

---

## 📖 How to Use This Project

This is a **documentation-first project**. We do NOT write code here. We only:
1. Read `PROGRESS.md` to understand current state
2. Create `plan.md` for new phases
3. Use `implementation.md` to record work after each phase

### Reference Hierarchy

| File | Role | When to Update |
|------|------|----------------|
| **`PROGRESS.md`** | **Master reference** — authoritative status, verified working items, gaps, next steps | Every 2 weeks or when major changes occur |
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


## 🚀 Workflow Summary


2. Pick the first incomplete phase
   → Check Summary Status and Current Gaps in PROGRESS.md
3. Read  phases/<phase-name>/plan.md → Understand the plan
4. Implement (by yourself)  → Write code, no docs
5. Write  phases/<phase-name>/implementation.md → Document what you did
6. Update PROGRESS.md       → Move phase from ❌ to ✅ in Summary Status
7. Commit                   → git add -A && git commit -m "docs: ..."
```
---
