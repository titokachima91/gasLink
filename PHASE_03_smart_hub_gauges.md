# PHASE 03 — Smart Hub Gauges (Collective)

**Status:** ✅ Done (verified on disk)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

The Smart Hub showed per-cylinder values instead of collective values. The fix was to use `calculateFifo()` from `cylinder_fifo.dart` which aggregates all deliveries per cylinder group (brand+weight).

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

## 🔜 Implementation Steps

1. **Run the app** in debug mode
2. **Add two cylinders** of same brand+weight
3. **Confirm collective display** works

---

## 🔜 Next Steps

- Manual verification complete
- Ready for next phase
