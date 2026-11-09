# PHASE 11 — Hardcoded Login

**Status:** ✅ Done (present on disk)  
**Priority:** 🔵 Medium  
**Branch:** `harden-source-of-truth`  
**Commit:** `e372c5b`

---

## 📝 Issue Description

The hardcoded login `0767304776` / `0000` was present in `auth_service.dart`. This phase documents it and verifies it works.

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

## 🔜 Implementation Steps

1. **Run app** in debug mode
2. **Open login screen**
3. **Enter** `0767304776` (or `+255767304776`) as phone
4. **Enter** `0000` as PIN
5. **App routes** to home screen
6. **Verify** session is saved

---

## 🔜 Next Steps

- Verify in debug APK
- Document security note (development fallback, not production)
