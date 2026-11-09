# PHASE 02 — Home Screen Gauge Wording

**Status:** ✅ Largely done (collective logic) / ⚠️ Wording cleanup needed  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The consumer home screen gauge currently shows:
- `Zimebaki ~X Siku (Y%)` — correct intended meaning but "Siku" (days) may need to be scoped to "day estimate"
- `Imeisha / Empty (0%)` — correct empty state
- "My Gas Cylinder" header is clear enough

The user noted "Siku za kurudishwa" in the report summary as a wording concern. The actual code shows "Zimebaki ~X Siku" which is acceptable, but a review for neutrality and correct Bahasa/Swahili is needed.

---

## 🎯 Goal

- Confirm gauge wording is correct and clear
- Use neutral/standard Swahili phrasing for remaining days and percentage
- Ensure empty/critical states are clear

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Gauge shows per-cylinder collective display | ✅ Done |
| Shows `Zimebaki ~X Siku (Y%)` | ✅ Done |
| Empty state `Imeisha / Empty (0%)` | ✅ Done |
| Critical low state (red) | ✅ Done |

---

## ❌ What's NOT Done

- [ ] Review wording: "Zimebaki ~X Siku" — confirm acceptable or adjust to "Mpunguzo wa kibao kwa ~X siku"
- [ ] Ensure "My Gas Cylinder" heading is clear
- [ ] Ensure "Zimebaki" (has remaining) is the best choice vs "Imebakia"

---

## 📝 Wording Recommendations

| Current | Suggested | Rationale |
|---------|-----------|-----------|
| `Zimebaki ~X Siku` | `Imebakia ~X Siku` | "Imebakia" (has remained/left) is more standard |
| `Imeisha / Empty (0%)` | `Imeisha / Empty (0%)` | Keep as is — clear |
| `My Gas Cylinder` | `My Gas Cylinder` or `Mtungi wangu` | English clear enough; optional Swahili |

---

## 🔜 Implementation Steps

1. Review all widget strings in `lib/screens/consumer/consumer_home_screen.dart`
2. Apply wording recommendations
3. Test with real cylinder data to confirm readability

---

## 🚨 Risk

- Low — wording is cosmetic; app remains functional either way.

---

## 📅 Estimated Effort

- Few hours
