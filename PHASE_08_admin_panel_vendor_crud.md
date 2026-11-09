# PHASE 08 — Admin Panel (Vendor CRUD)

**Status:** ❌ Not done (biggest gap)  
**Priority:** 🔴 High  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

`role_router.dart:29-31` routes admin to an 11-line stub (`admin_vendor_screen.dart`). The admin panel needs to be a fully functional admin panel with bottom tabs: Dashboard, Vendors, Consumers, Orders, Inventory, Analytics, Settings.

---

## 🎯 Goal

- Build real admin panel (not a stub)
- Bottom tabs: Dashboard, Vendors, Consumers, Orders, Inventory, Analytics, Settings
- Mobile-first design

---

## ❌ What's Not Done

| Item | Status |
|------|--------|
| Admin panel UI | ❌ Stub only |
| Vendor CRUD | ❌ Not implemented |
| Consumer view | ❌ Not implemented |
| Orders view | ❌ Not implemented |
| Inventory management | ❌ Not implemented |
| Analytics view | ❌ Not implemented |
| Settings | ❌ Not implemented |

---

## 🔜 Implementation Steps

1. **Replace stub** — `role_router.dart:29-31` → proper AdminPanel
2. **Create admin layout** — bottom tab navigation
3. **Build vendor CRUD** — `lib/screens/admin/vendor_crud_screen.dart`
4. **Build consumer view** — list of consumers
5. **Build order management** — approve/reject orders
6. **Build inventory management** — manage products
7. **Build analytics view** — use `analytics_service.dart`
8. **Build settings** — app configuration

---

## 🔜 Implementation Steps (Detailed)

1. **Role router** (`lib/screens/role_router.dart`):
   ```dart
   if (effectiveRole == AuthService.roleAdmin) {
     return const AdminDashboardScreen();
   }
   ```

2. **Admin dashboard** — overview with stats

3. **Vendor management** — list, add, edit, delete vendors

4. **Consumer management** — list, filter, view details

5. **Order management** — list, approve, reject, track

6. **Inventory management** — add, edit, delete products

7. **Analytics** — use `AnalyticsService` for charts

8. **Settings** — profile, notifications, theme

---

## 🔜 Next Steps

- Design admin screen layout
- Implement vendor CRUD screen
- Build bottom tab navigation
- Add analytics view
