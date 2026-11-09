# PHASE 05 — Smart Hub Gauges (Collective)

**Status:** ✅ Done (collective/FIFO already implemented)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The Smart Hub was showing per-cylinder values instead of collective/sync-aggregated values. The fix was to use `calculateFifo()` from `cylinder_fifo.dart` which aggregates all deliveries per cylinder group (brand+weight) and produces a collective `FifoCollective` result.

---

## 🎯 Goal

- Confirm Smart Hub gauge shows collective values (not per-cylinder)
- Ensure progress and remaining-days text are combined

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Smart Hub gauge uses `calculateFifo()` | ✅ Done |
| Collective display per brand+weight group | ✅ Done |
| Day estimate and percentage shown | ✅ Done |

---

## ❌ What's NOT Done

- [ ] Verify with real app run in debug/prod

---

## 🔍 How It Works

The Smart Hub screen:
1. Fetches delivered orders (`_deliveredOrders`)
2. Groups them by brand+weight
3. Calls `calculateFifo()` for each group
4. Displays `totalRemainingDays` and `totalPercentage`
5. Uses `capacityFraction` for the progress bar

---

## 🔜 Implementation Steps

1. Run the app in debug mode
2. Add two cylinders of same brand+weight
3. Confirm collective display works

---

## 🚨 Risk

- Low

---

## 📅 Estimated Effort

- 0.25 day (manual verification)
