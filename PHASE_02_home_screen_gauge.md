# PHASE 02 — Home Screen Gauge (Collective)

**Status:** ✅ Done (verified on disk)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

The home screen gauge was showing per-cylinder values instead of collective values. Each cylinder had its own `remainingDays` and `percentage` stored as fields, which could be stale or inconsistent.

---

## 🎯 Goal

- Aggregate all cylinders by brand+weight
- Use `calculateFifo()` from `cylinder_fifo.dart` for FIFO depletion
- Display aggregate `totalRemainingDays` and `capacityFraction` (0–1.0)

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Grouping by brand+weight | ✅ Done |
| Uses `calculateFifo()` | ✅ Done |
| Aggregates `totalRemainingDays` | ✅ Done |
| Progress bar uses `capacityFraction` | ✅ Done |

---

## 🔜 Implementation Steps

1. **Group cylinders** by `brand + weight` key in `consumer_home_screen.dart`
2. **Call `calculateFifo()`** per group for FIFO depletion
3. **Display aggregate values** — `totalRemainingDays`, `totalPercentage`, `capacityFraction`
4. **Verify** that multiple deliveries for same brand+weight show correct aggregate

---

## 🔜 Next Steps

- Manual test with real cylinder data
- Verify FIFO calculation matches expected results
