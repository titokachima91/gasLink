# PHASE 05 — Vendor "verified" Role

**Status:** ❌ Not done  
**Priority:** 🔴 High  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

The `Vendor` model doesn't have a `verified` field. The current model has `active`, `rating`, `currentTier`, `completionPercentage`, but no verification status. This needs to be added so consumers can see which vendors are verified.

---

## 🎯 Goal

- Add `verified` field to `Vendor` model (Firestore)
- Set via admin panel
- Display with status indicator on consumer side

---

## ❌ What's Not Done

| Item | Status |
|------|--------|
| `verified` field in Vendor model | ❌ Missing |
| Verified flag in Firestore | ❌ Not implemented |
| Consumer display | ❌ Not done |

---

## 🔜 Implementation Steps

1. **Add `verified` field** to `Vendor` model in `lib/models/vendor.dart`
2. **Add `verified` to Firestore** — update `vendor_repository.dart` to write/read `verified`
3. **Display in consumer UI** — show verified badge in `consumer_home_screen.dart` and vendor listings
4. **Set via admin** — add verified toggle in `admin_vendor_screen.dart`

---

## 🔜 Implementation Steps (Detailed)

1. **Model update** (`lib/models/vendor.dart`):
   ```dart
   class Vendor {
     // ...
     bool verified = false;
   }
   ```

2. **Firestore update** (`lib/services/vendor_repository.dart`):
   - Update `createVendor()`, `updateVendor()` to write `verified` field

3. **Consumer display** (`lib/screens/consumer/consumer_home_screen.dart`):
   - Show ✓ (verified) or ⬤ (unverified) next to vendor names

---

## 🔜 Next Steps

- Manual verification of field addition
- Test admin setting verified flag
- Test consumer display of verified status
