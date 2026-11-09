# PHASE 11 — Hardcoded Login Documentation

**Status:** ✅ Done (present on disk)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `f301944`

---

## 📝 Issue Description

The original plan flagged hardcoded login `0767304776` / `0000` as "already present; make it a documented fallback." This phase documents it and verifies it works.

---

## 🎯 Goal

- Document the hardcoded login credentials
- Verify they work in debug APK
- Make it a documented fallback (not a secret)

---

## ✅ What's Done

| Item | Status |
|------|--------|
| Hardcoded admin login `0767304776` / `0000` | ✅ Present |
| `AuthService.adminLogin()` uses hardcoded phone | ✅ Done |
| `AuthService.adminLogin()` validates PIN `0000` | ✅ Done |
| `user_role` saved as `'admin'` after login | ✅ Done |

---

## 🔍 Where It's Defined

In `lib/services/auth_service.dart`:

- `adminLogin()` accepts `adminPhone: '+255767304776'` and `adminPin: '0000'`
- On successful admin login, `user_role` is saved to session state
- `AuthService.clearSession()` removes session on logout

---

## 🔜 Verification Steps

1. Run app in Android Studio / VS Code debug mode
2. Open login screen
3. Enter `0767304776` (or `+255767304776`) as phone
4. Enter `0000` as PIN
5. App should route to home screen
6. Check session is saved (`AuthService.instance.roleAdmin` matches)

---

## ⚠️ Security Note

This is a **development fallback**, not a production credential. Documented intentionally so the dev team can use it for testing. Do NOT deploy to production with hardcoded credentials.

---

## 📅 Estimated Effort

- 0.25 day (verification)
