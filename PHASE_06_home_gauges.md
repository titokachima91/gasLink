# PHASE 06 — Home Screen Gauges (Collective Fix)

**Status:** ✅ Done (collective logic already implemented in home screen)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The home screen is a consumer-facing gauge. It must show the consumer's collective gas cylinder status, not per-cylinder breakdowns. The fix was to group cylinders by brand+weight and use `calculateFifo()` for each group, showing the aggregated `totalRemainingDays` and `capacityFraction`.

---

## 🎯 Goal

- Confirm home screen gauge shows collective values
- Ensure progress bar uses `capacityFraction` (0.0–1.0)

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Home screen groups cylinders by brand+weight | ✅ Done |
| Uses `calculateFifo()` from `cylinder_fifo.dart` | ✅ Done |
| Displays `totalRemainingDays` and `totalPercentage` | ✅ Done |
| Progress bar uses `capacityFraction` | ✅ Done |

---

## ❌ What's NOT Done

- [ ] Manual test with real cylinder data

---

## 🔍 How It Works

The `_buildGasEstimatorCard()` function:
1. Groups `_myCylinders` by `brand+weight` key
2. For each group, calls `_aggregateCylinderGroup()` which:
   - Collects delivered orders matching the brand+weight
   - Calls `calculateFifo()` with delivery dates
   - Falls back to manual cylinder documents if no orders
3. Displays `Zimebaki ~X Siku (Y%)` and a progress bar using `capacityFraction`

---

## 🔜 Implementation Steps

1. Run app, add cylinders
2. Confirm gauge shows collective status per brand+weight group

---

## 🚨 Risk

- Low — logic is already in place.

---

## 📅 Estimated Effort

- 0.25 day (manual verification)
