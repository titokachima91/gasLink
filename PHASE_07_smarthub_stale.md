# PHASE 07 — Smart Hub Gauges (Stale Data Removal)

**Status:** ✅ Done (collective logic removes stale/duplicate displays)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The Smart Hub originally had stale/duplicate gauge displays — showing per-cylinder gauges that were out of sync with the actual delivery data. The fix by using `calculateFifo()` aggregates all deliveries and removes stale/duplicate per-cylinder items.

---

## 🎯 Goal

- Confirm Smart Hub no longer shows per-cylinder gauges
- Confirm all deliveries are aggregated correctly

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Smart Hub uses `calculateFifo()` | ✅ Done |
| No per-cylinder gauge displays | ✅ Done |
| Collective display for brand+weight groups | ✅ Done |

---

## ❌ What's NOT Done

- [ ] Manual test with real delivery appointments

---

## 🔍 How It Works

Instead of showing each cylinder individually, the Smart Hub:
1. Collects all delivered orders for each brand+weight group
2. Calculates FIFO depletion for the group
3. Shows combined `totalRemainingDays` and `totalPercentage`
4. Progress bar uses `capacityFraction`

---

## 🔜 Implementation Steps

1. Run app in debug
2. Add multiple deliveries for same brand+weight
3. Confirm single collective gauge is shown

---

## 🚨 Risk

- Low

---

## 📅 Estimated Effort

- 0.25 day (manual verification)
