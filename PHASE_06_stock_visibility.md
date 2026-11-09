# PHASE 06 — Stock Visibility

**Status:** ⚠️ Partial  
**Priority:** 🟡 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

`inventory_screen.dart` shows all products, but `vendor_detail_screen.dart` filters `in_stock == true`. This inconsistency means consumers see different stock information depending on which screen they access.

---

## 🎯 Goal

- Unify vendor and consumer product queries
- Ensure consistent `in_stock` handling across all screens

---

## ❌ What's Not Done

| Item | Status |
|------|--------|
| Unified product query | ❌ Not done |
| Consistent `in_stock` handling | ❌ Partial |
| Consumer sees same stock info | ⚠️ Partial |

---

## 🔜 Implementation Steps

1. **Review** `inventory_screen.dart` — identify current product query logic
2. **Review** `vendor_detail_screen.dart` — identify stock filtering logic
3. **Unify** product queries — ensure both use same `in_stock` filter
4. **Add** consistency check test

---

## 🔜 Implementation Steps (Detailed)

1. **Identify query logic** in both files
2. **Create shared method** `getProductsInStock()` in a service or repository
3. **Update** `inventory_screen.dart` to use unified query
4. **Update** `vendor_detail_screen.dart` to use same query
5. **Test** both screens show identical stock info

---

## 🔜 Next Steps

- Manual verification of stock consistency
- Test on both vendor and consumer sides
- Edge case testing (out of stock items)
