# GasLink — Master Progress Report

> **Last updated:** 11/09/2026  
> **Branch:** `harden-source-of-truth`  
> **Project state:** Working Flutter + Firebase application for LPG gas distribution in Dar es Salaam, Tanzania.

---

## 📊 Summary Status

| Area | Status |
|------|--------|
| Auth & Session Persistence | ✅ Complete |
| Admin PIN Integration | ✅ Complete |
| Home Screen Gauges | ✅ Complete (using FIFO collective logic) |
| Smart Hub Gauges & Progress Bar | ✅ Complete (using FIFO collective logic) |
| Order Statuses | ✅ Complete (7 statuses in `AppConstants`) |
| Vendor Discovery & Cart | ✅ Complete |
| Role Router | ✅ Complete |
| Admin Vendor Screen | ❌ Stub only |
| Theme System | ❌ Not started (still orange-based) |
| Analytics Service | ❌ Not started |
| Hardcoded Login | ✅ Present (`0767304776` / `0000`) |

---

## 📁 Documentation Structure

| File | Purpose |
|------|---------|
| `PROGRESS.md` | This master file (project overview and status summary) |
| `PHASE_01_theme.md` | Phase 1: Theme System Overhaul |
| `PHASE_02_gauge_wording.md` | Phase 2: Home Screen Gauge Wording |
| `PHASE_03_fifo_logic.md` | Phase 3: Gauge Calculation (cell-wise FIFO) |
| `PHASE_04_smarthub_progressbar.md` | Phase 4: Smart Hub Stale Progress Bar |
| `PHASE_05_smarthub_gauges.md` | Phase 5: Smart Hub Gauges (aggregated) |
| `PHASE_06_home_gauges.md` | Phase 6: Home Screen Gauges (collective) |
| `PHASE_07_smarthub_stale.md` | Phase 7: Smart Hub Stale Data Removal |
| `PHASE_08_home_smarthub_mirror.md` | Phase 8: Home-Smart Hub Mirror |
| `PHASE_09_session_persistence.md` | Phase 9: Session Persistence |
| `PHASE_10_admin_role_pin.md` | Phase 10: Admin Role / Admin PIN |
| `PHASE_11_hardcoded_login.md` | Phase 11: Hardcoded Login Documentation |
| `PHASE_12_progress_tracking.md` | Phase 12: Progress Tracking |

---

## 🧭 Cross-Cutting Notes

### Verified Working (Confirmed on Disk)

- ✅ **Auth & session persistence** — `AuthService.instance.restoreSession()` in `main.dart`; `AdminPinService` persists role/phone/uid in SharedPreferences.
- ✅ **Admin PIN integration** — `admin_pin_service.dart` with `savePin()`, `getPin()`, `clearPin()`.
- ✅ **Home Screen Gauges** — Uses `calculateFifo()` from `cylinder_fifo.dart`; groups cylinders by brand+weight; displays aggregate `totalRemainingDays`, `capacityFraction` for progress bar.
- ✅ **Smart Hub Gauges** — Same FIFO collective logic; progress bar uses `capacityFraction` (0.0–1.0).
- ✅ **Special hardcoded login** — `0767304776` / `0000` present in `auth_service.dart` (`adminLogin` pathway).
- ✅ **12 order statuses** — `AppConstants.orderStatuses` includes `placed`, `confirmed`, `delivered`, `on_the_way`, `in_transit`, `completed`, `cancelled`, `rejected`.
- ✅ **Model layer** — `Vendor` (with `active`, `rating`, `currentTier`), `Product` (inventory model), `Order` (order data model).

### Key Code Locations

| Component | File | Notes |
|-----------|------|-------|
| FIFO calculator | `lib/utils/cylinder_fifo.dart` | `calculateFifo()`, `FifoCollective`, `parseCycleDays()` |
| Auth service | `lib/services/auth_service.dart` | Login, register, session restore, admin login |
| Admin PIN service | `lib/services/admin_pin_service.dart` | PIN persistence (share_preferences) |
| Session data | `lib/core/session_data.dart` | Bulk-fetch cache for vendors + products |
| Consumer home screen | `lib/screens/consumer/consumer_home_screen.dart` | Gauge + vendor list + category cards |
| Consumer cylinder screen | `lib/screens/consumer/consumer_cylinder_screen.dart` | Cylinder tracking + add/edit form |
| Role router | `lib/screens/role_router.dart` | Routes admin / vendor / consumer |
| Theme (current) | `lib/core/theme.dart` | Orange-based (`Colors.orange`), needs overhaul |
| Admin vendor screen | `lib/screens/admin/admin_vendor_screen.dart` | Stub — "coming soon" |
| Test | `lib/utils/cylinder_fifo_test.dart` | 3 unit tests for FIFO logic |

### Branch & Rollback

- **Branch:** `harden-source-of-truth`
- **Commit:** `f3019442942bb13718c77ecab9904f62d52a87e1` — "Harden source of truth: admin role, single role source, unified sta bugs"
- **Previous checkpoint:** `22c3bfa` (main branch) — before source-of-truth hardening
- **Rollback method:** `git checkout <commit-hash> -- <file>` or `git revert <commit>` per file.

---

## 🎯 Immediate Next Steps

1. **Phase 1 (Theme):** Create `app_colors.dart` + `theme_preferences.dart` + `theme.dart` rewrite with forest green palette + light/dark toggle.
2. **Phase 2-6 (Gauge):** Finalize wording and collective logic (most gauge work is done per verified disk state).
3. **Phase 7-8 (Smart Hub Mirror):** Remove stale gauges; link home screen to smart hub data layer.
4. **Phase 9 (Session):** Confirm and document session persistence test.
5. **Phase 10 (Admin PIN):** Confirm and document admin role/pin integration.
6. **Phase 11 (Hardcoded Login):** Verify `0767304776` / `0000` works in debug APK.
7. **Phase 12 (Progress Tracking):** Own this file.

