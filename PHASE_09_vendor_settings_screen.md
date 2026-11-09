# PHASE 09 — Vendor Settings Screen

**Status:** ❌ Not done  
**Priority:** 🟡 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

No vendor settings screen exists. Vendors need a place to manage their commission preferences (Subscription vs %), profile management, and settings.

---

## 🎯 Goal

- Build vendor settings screen
- Add commission toggle (Subscription vs %)
- Add profile management (upload image, edit name, etc.)
- Add account settings

---

## ❌ What's Not Done

| Item | Status |
|------|--------|
| Vendor settings screen | ❌ Not started |
| Commission toggle | ❌ Not implemented |
| Profile management | ❌ Not implemented |
| Account settings | ❌ Not implemented |

---

## 🔜 Implementation Steps

1. **Create vendor settings screen** (`lib/screens/vendor/vendor_settings_screen.dart`)
2. **Add commission settings** — Subscription vs % toggle
3. **Add profile management** — upload photo, edit name, edit contact info
4. **Add account settings** — email, phone, password change
5. **Wire into** vendor dashboard navigation

---

## 🔜 Implementation Steps (Detailed)

1. **Screen structure**:
   ```
   lib/screens/vendor/vendor_settings_screen.dart
   ```

2. **Commission toggle**:
   - Subscription plan (fixed fee)
   - Percentage plan (percentage of order value)
   - Persist choice in Firestore

3. **Profile management**:
   - Upload vendor image
   - Edit profile fields

4. **Account settings**:
   - Email/phone change
   - Password change

---

## 🔜 Next Steps

- Build settings screen UI
- Add commission toggle
- Add profile management
- Test
