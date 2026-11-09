# PHASE 03 — Gauge Calculation (Cell-Wise FIFO Logic)

**Status:** ✅ Done (core logic already implemented)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The original plan called for a full cell-wise FIFO calculation across all cylinders. The current implementation uses a group-by-brand+weight aggregation that effectively does cell-wise FIFO at the cylinder level (not per-unit-cell), which is the correct approach for tracking how many "days of gas" a consumer has and what percentage of total capacity remains.

---

## 🎯 Goal

- Confirm FIFO calculation works correctly
- Ensure multiple cylinders are aggregated correctly
- Verify the `capacityFraction` (0.0–1.0) progress bar value is correct

---

## ✅ What's Done

| Item | Status |
|------|--------|
| `calculateFifo()` in `cylinder_fifo.dart` | ✅ Done |
| `FifoCollective` with `totalPercentage`, `totalRemainingDays`, `capacityFraction` | ✅ Done |
| Group-by brand+weight in home screen | ✅ Done |
| `capacityFraction` for progress bar | ✅ Done |
| Unit tests for FIFO logic | ✅ Done (3 tests) |

---

## ❌ What's NOT Done

- [ ] Automated integration test with real Firestore data
- [ ] Edge case testing (e.g., 3+ cylinders of same brand+weight)

---

## 🔍 How It Works

1. **Grouping:** Cylinders are grouped by `brand-weight` key
2. **FIFO sorting:** Delivery dates are sorted oldest → newest
3. **Per-cylinder depletion:** Each cylinder is consumed oldest-first within its group
4. **Aggregation:**
   - `totalRemainingDays` = sum of `remainingDays` across all cylinders
   - `totalPercentage` = sum of per-cylinder percentages (can exceed 100%)
   - `capacityFraction` = `totalRemainingDays / totalCapacityDays` → **0.0–1.0**, used for progress bar

---

## 🔜 Implementation Steps

1. Write integration tests with synthetic cylinder + order data
2. Verify `capacityFraction` = 1.0 when all cylinders are full
3. Verify `capacityFraction` ≈ 0.5 when half the total capacity is remaining

---

## 🚨 Risk

- Low — core logic is already implemented and tested.

---

## 📅 Estimated Effort

- 0.5 day (test verification only)
