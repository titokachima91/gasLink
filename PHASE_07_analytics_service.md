# PHASE 07 — Analytics Service

**Status:** ❌ Not started  
**Priority:** 🔴 High  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

No `analytics_service.dart` exists in the codebase. The app needs analytics to track revenue, orders, users, vendors, inventory, cylinders, and commission. Professional charts should be provided with CSV/PDF export.

---

## 🎯 Goal

- Build `lib/services/analytics_service.dart`
- Track: revenue, orders, users, vendors, inventory, cylinders, commission
- Export to CSV/PDF

---

## ❌ What's Not Done

| Item | Status |
|------|--------|
| Analytics service | ❌ Not started |
| Data collection | ❌ Not done |
| Chart rendering | ❌ Not done |
| CSV/PDF export | ❌ Not done |

---

## 🔜 Implementation Steps

1. **Create `lib/services/analytics_service.dart`** — data aggregation service
2. **Implement** data collection for:
   - Revenue (daily/monthly/yearly)
   - Orders (count, status breakdown)
   - Users (total, new registrations)
   - Vendors (registered, active)
   - Inventory (products, stock levels)
   - Cylinders (tracked, depleted)
   - Commission (earned, pending)
3. **Implement** chart rendering with `fl_chart` or `syncfusion`
4. **Implement** CSV export
5. **Implement** PDF export

---

## 🔜 Implementation Steps (Detailed)

1. **Service structure**:
   ```dart
   class AnalyticsService {
     Future<Map<String, dynamic>> getRevenueSummary() async { ... }
     Future<Map<String, dynamic>> getOrderStats() async { ... }
     // ...
   }
   ```

2. **Chart integration** — use `fl_chart` or `syncfusion` package

3. **CSV export**:
   ```dart
   Future<void> exportToCSV(String path) async { ... }
   ```

4. **PDF export** — use `syncfusion_pdf` or `jrpna_pdf` package

---

## 🔜 Next Steps

- Choose chart library
- Implement service structure
- Test with real data
