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

## 🚀 Getting Started

1. **Read `PROGRESS.md`** — understand current state
2. **Pick a priority phase** — start with Theme Overhaul (Phase 1)
3. **Read `phases/phase-01-theme/plan.md`** — understand the plan
4. **Implement** the changes
5. **Write `phases/phase-01-theme/implementation.md`** — document what you did
6. **Update `PROGRESS.md`** — move phase from ❌ to ✅

---

> **Reminder:** `PROGRESS.md` is the master. When in doubt, always read `PROGRESS.md` first.
