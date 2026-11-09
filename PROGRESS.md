# GasLink — Master Progress Report

> **Last updated:** 11/09/2026
> **Branch:** harden-source-of-truth
> **Project state:** Working Flutter + Firebase application for LPG gas distribution in Dar es Salaam, Tanzania.
> **Documentation:** 12-phase plan from PHASE_*.md files; this file is the authoritative master progress tracker.

---

## 📊 Summary Status

| Area | Status |
|------|--------|
| Auth & Session Persistence | ✅ **Complete** |
| Admin PIN Integration | ✅ **Complete** |
| Home Screen Gauge (collective) | ✅ **Complete** |
| Cylinder Smart Hub (collective) | ✅ **Complete** |
| Order Statuses (/7) | ✅ **Complete** |
| Role Router | ✅ **Complete** |
| Circle FIFO Logic | ✅ **Complete** |
| Theme System | ❌ **Not started** (still Colors.orange) |
| Admin Panel UI | ❌ **Stub only** (admin_vendor_screen.dart) |
| Analytics Service | ❌ **Not started** |
| Vendor verified Role | ❌ **Not done** |
| Vendor Profile | ⚠️ **Exists** but no image upload |
| Stock Visibility | ⚠️ **Partial** |

---

## ✅ Verified Working (Confirmed on Disk)

| # | Feature | Evidence |
|---|---------|----------|
| 1 | Auth Persistence | auth_service.dart saves session; main.dart restores via restoreSession() |
| 2 | Session Persistence | admin_pin_service.dart persists role/phone/uid |
| 3 | Admin PIN Integration | admin_pin_service.dart (savePin/getPin/clearPin); auth_service.dart adminLogin with adminPhone: '+255767304776', adminPin: '0000' |
| 4 | Home Screen Gauge | Uses calculateFifo() from cylinder_fifo.dart; groups by brand+weight |
| 5 | Cylinder Smart Hub | Uses cylinder_fifo.dart; progress bar uses capacityFraction (0-1.0) |
| 6 | Order Statuses | AppConstants.orderStatuses = 7 statuses |
| 7 | Role Router | role_router.dart routes admin-vendor-consumer |
| 8 | Circle FIFO | cylinder_fifo.dart implements FIFO; totalPercentage can exceed 100%; capacityFraction is 0-1.0 |

### Hardcoded Login (Seed Credential)
- Phone: 0767304776 (or +255767304776)
- PIN: 0000
- Route: login -> auth_service.dart -> adminLogin() -> AuthService.roleAdmin

---

## 🔍 Key Code Locations

| Component | File | Notes |
|-----------|------|-------|
| FIFO calculator | lib/utils/cylinder_fifo.dart | calculateFifo(), FifoCollective, parseCycleDays() |
| Auth service | lib/services/auth_service.dart | Login, register, session restore, admin login |
| Admin PIN service | lib/services/admin_pin_service.dart | PIN persistence |
| Session data | lib/core/session_data.dart | Bulk-fetch cache |
| Consumer home screen | lib/screens/consumer/consumer_home_screen.dart | Gauge + vendor list |
| Consumer cylinder screen | lib/screens/consumer/consumer_cylinder_screen.dart | Cylinder tracking + add/edit |
| Role router | lib/screens/role_router.dart | Routes admin/vendor/consumer |
| Theme (current) | lib/core/theme.dart | Orange-based, needs overhaul |
| Admin vendor screen | lib/screens/admin/admin_vendor_screen.dart | Stub — coming soon |
| Test | lib/utils/cylinder_fifo_test.dart | 3 unit tests for FIFO logic |

---

## 🎯 Current Gaps (Priority Order)

### RED Phase 1 — Theme Overhaul
- lib/core/theme.dart still uses Colors.orange
- Missing: app_colors.dart, theme_preferences.dart, theme_controller.dart (Riverpod)
- Target: Forest Green #2D6A4F (light) / #121212 (dark) with light/dark toggle

### RED Phase 2 — Admin Panel (Biggest Gap)
- role_router.dart:29-31 routes admin to 11-line stub (admin_vendor_screen.dart)
- Missing: vendor list, approve vendors, manage inventory, consumer view, analytics, settings
- Target: Bottom tabs — Dashboard, Vendors, Consumers, Orders, Inventory, Analytics, Settings

### RED Phase 3 — Vendor verified Role
- No verified field in Vendor model (only active, rating, currentTier, completionPercentage)
- Target: Add verified field, set via admin panel, display with status indicator on consumer side

### YELLOW Phase 4 — Analytics Service
- No analytics_service.dart exists
- Target: Revenue, orders, users, vendors, inventory, cylinders, commission -> CSV/PDF export

### YELLOW Phase 5 — Vendor Settings
- No vendor settings screen exists
- Target: Commission toggle (Subscription vs %), profile management, image upload

---

## 🔜 Immediate Next Steps (Priority Order)

1. Theme Overhaul — Create app_colors.dart + theme_preferences.dart + theme.dart rewrite with forest green palette + light/dark toggle
2. Admin Panel — Build real vendor CRUD screens replacing the 11-line stub
3. Vendor verified Role — Add verified field to Vendor model, set via admin, display on consumer
4. Analytics Service — Build analytics_service.dart + CSV/PDF export
5. Vendor Settings — Commission toggle + profile management

---

> Note: Do NOT create new phase files beyond the existing 12 — reconciliation of existing PHASE_*.md files with this master file is sufficient. The 12 phases you defined are the source of truth.
