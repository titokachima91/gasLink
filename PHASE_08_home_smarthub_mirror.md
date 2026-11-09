# PHASE 08 — Home Screen — Smart Hub Mirror

**Status:** ✅ Partial (home screen uses own cylinder data, not smart hub data)  
**Priority:** 🔴 High  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The home screen gauge is driven by saved cylinder documents directly, not by the smart hub data layer. The smart hub has access to delivered orders, cycle days, and can calculate FIFO depletion for any brand+weight group. The home screen should mirror the smart hub calculation logic.

---

## 🎯 Goal

- Link home screen gauge to smart hub data layer (delivery orders + cycle days)
- Remove direct coupling to saved cylinder documents for calculation
- Ensure both screens show identical data

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Home screen groups cylinders by brand+weight | ✅ Done |
| Uses `calculateFifo()` | ✅ Done |
| Fallback to manual cylinder docs | ✅ Done |

---

## ❌ What's NOT Done

- [ ] Replace cylinder document fallback with smart hub data layer (delivered orders)
- [ ] Synchronize home screen data with smart hub (same calculation)
- [ ] Verify both screens show identical gauge when deliveries happen

---

## 🔍 Current Behavior

The home screen uses TWO calculation paths:
1. **Delivered orders** — reads `_deliveredOrders`, groups by brand+weight, calls `calculateFifo()`
2. **Manual cylinder docs** — falls back to `_myCylinders` list (saved cylinder documents)

---

## ❌ Current Gap

Path 2 (manual cylinder docs) is not synchronized with the smart hub's delivered orders calculation. If the user adds a cylinder manually (offline) and a delivery is also recorded, the two screens could show different remaining days.

---

## 🔜 Implementation Steps

1. Remove path 2 (manual cylinder docs fallback) OR
2. Ensure manual cylinder docs are synced to delivered orders when saved
3. Verify both screens produce identical `FifoCollective` results

---

## 🚨 Risk

- Moderate — depends on how cylinder docs are saved. If they are saved in Firestore, syncing should be straightforward.

---

## 📅 Estimated Effort

- 0.5–1 day
