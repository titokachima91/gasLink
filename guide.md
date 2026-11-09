# GasLink — Project Guide

> **Last updated:** 11/09/2026  
> **Branch:** `harden-source-of-truth`  
> **Primary reference:** `PROGRESS.md` is the authoritative master file for this project.

---

## 🎯 What This Project Is

GasLink is a **Flutter + Firebase** application for LPG gas distribution in Dar es Salaam, Tanzania.

The codebase is already in a working state. This is a **documentation-first project** — we do NOT write code here. We only:
1. Read `PROGRESS.md` to understand current state
2. Create `plan.md` for new phases
3. Use `implementation.md` to record work after each phase

---

## 📁 Project Structure

```
├── PROGRESS.md                              ← MASTER (read this first)
├── guide.md                                 ← This file (process explanation)
├── phases/
│   └── <phase-name>/
│       ├── plan.md                          ← Plan for this phase (read before starting)
│       └── implementation.md                ← Record of this phase work (write after)
├── lib/
│   ├── services/                            ← Auth, PIN, orders, notifications
│   ├── screens/                             ← All UI screens (consumer, vendor, admin)
│   ├── models/                              ← Data models (Vendor, Product, Order)
│   ├── utils/                               ← Utility functions (FIFO calculator)
│   └── core/                                ← Constants, theme, session data
└── ...                                    ← Other app files (android, ios, web, etc.)
```

---

## 📖 The Documentation System

This project follows a simple documentation workflow. Three files work together:

| File | Role | When to Update |
|------|------|----------------|
| **`PROGRESS.md`** | Master reference — authoritative status, verified working items, gaps, next steps | Every 2 weeks or when major changes occur |
| `phases/<name>/plan.md` | Per-phase implementation plan — what the issue is, why it matters, how to fix, risk, effort | When starting a new phase or when requirements change |
| `phases/<name>/implementation.md` | Per-phase implementation record — what was done, steps taken, problems/pivots, code evidence | **After** each phase is implemented |

### Reference Hierarchy

| File | Role |
|------|------|
| `PROGRESS.md` | **Master**. Always read this first. Contains the full project state. |
| `phases/<name>/plan.md` | Plan for a specific phase. Read before implementing that phase. |
| `phases/<name>/implementation.md` | Record of work done for a specific phase. Write this after implementing. |

**Rule:** `PROGRESS.md` is the master. If `implementation.md` says one thing but `PROGRESS.md` says another, `PROGRESS.md` wins.

---

## 🔑 Reference Points (Quick Links)

### Authentication
| What to Find | File/Path |
|--------------|-----------|
| Login / Register / Session Restore | `lib/services/auth_service.dart` |
| PIN Persistence | `lib/services/admin_pin_service.dart` |
| Hardcoded Login (Seed Credential) | `lib/services/auth_service.dart` — `adminLogin()` |

### Gauges & FIFO
| What to Find | File/Path |
|--------------|-----------|
| FIFO calculator (collective) | `lib/utils/cylinder_fifo.dart` |
| Home screen gauge | `lib/screens/consumer/consumer_home_screen.dart` |
| Smart hub gauge | `lib/screens/consumer/consumer_cylinder_screen.dart` |

### Navigation & Routing
| What to Find | File/Path |
|--------------|-----------|
| Route router (admin / vendor / consumer) | `lib/screens/role_router.dart` |

### Models & Data
| What to Find | File/Path |
|--------------|-----------|
| Vendor model (no `verified` field yet) | `lib/models/vendor.dart` |
| Product model | `lib/models/product.dart` |
| Order model | `lib/models/order.dart` |

### Screens
| What to Find | File/Path |
|--------------|-----------|
| Admin vendor screen (STUB — 11 lines) | `lib/screens/admin/admin_vendor_screen.dart` |
| Consumer home screen (gauge + vendor list) | `lib/screens/consumer/consumer_home_screen.dart` |
| Consumer cylinder tracking | `lib/screens/consumer/consumer_cylinder_screen.dart` |
| Inventory screen | `lib/screens/vendor/inventory_screen.dart` |

### Theme & Constants
| What to Find | File/Path |
|--------------|-----------|
| Theme (orange-based, needs overhaul) | `lib/core/theme.dart` |
| App constants (order statuses, brands, districts) | `lib/core/constants.dart` |

---

## 🚀 Workflow Summary

```text
1. Read PROGRESS.md         → What's done? What's next?
2. Pick the first incomplete phase
   → Check Summary Status and Current Gaps in PROGRESS.md
   → Priority order listed in PROGRESS.md Summary Status and Current Gaps
3. Read  phases/<phase-name>/plan.md → Understand the plan
4. Implement (by yourself)  → Write code, no docs
5. Write  phases/<phase-name>/implementation.md → Document what you did
6. Update PROGRESS.md       → Move phase from ❌ to ✅ in Summary Status
7. Commit                   → git add -A && git commit -m "docs: ..."
```

---

## 📊 Status Legend

| Icon | Meaning |
|------|---------|
| ✅ | Done — verified working |
| ❌ | Not done — needs implementation |
| ⚠️ | Partly done — some work done, some remains |
| ⏳ | Not started — plan created but not implemented |

---

> **Reminder:** `PROGRESS.md` is the master. When in doubt, always read `PROGRESS.md` first.
