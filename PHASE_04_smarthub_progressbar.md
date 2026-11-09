# PHASE 04 — Smart Hub Stale Progress Bar

**Status:** ✅ Largely done (uses `capacityFraction`)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The Smart Hub progress bar was reported as stale — showing correct gauge data but the progress bar not updating. The fix involved using `FifoCollective.capacityFraction` (which is 0.0–1.0) instead of `totalPercentage` (which can exceed 100%) for the progress bar value.

---

## 🎯 Goal

- Confirm Smart Hub progress bar uses `capacityFraction` (0.0–1.0), NOT `totalPercentage`
- Ensure progress bar updates correctly after new deliveries

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Smart Hub uses `capacityFraction` for progress bar | ✅ Done |
| `capacityFraction` = 1.0 when full | ✅ Done |
| Unit tests verify `capacityFraction` behavior | ✅ Done |

---

## ❌ What's NOT Done

- [ ] Manual test with real delivery data (e.g., after a new delivery appointment)

---

## 🔍 How It Works

The Smart Hub screen calculates:

```dart
final aggregate = calculateFifo(deliveryDates, cycleDays: cycleDays);
final progress = aggregate.capacityFraction; // 0.0–1.0
```

Instead of using `totalPercentage` directly (which would be 200% for two full cylinders), `capacityFraction` divides remaining days by total capacity days.

---

## 🔜 Implementation Steps

1. Verify Smart Hub screen uses `aggregate.capacityFraction` (not `totalPercentage`)
2. Manually test after a new delivery appointment to confirm progress bar updates

---

## 🚨 Risk

- Low — the fix is already in place.

---

## 📅 Estimated Effort

- 0.25 day (verification)
