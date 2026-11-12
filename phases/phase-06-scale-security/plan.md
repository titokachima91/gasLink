# Phase 06 — Scale & Security Hardening

> **Status:** ⏸️ **Parked** — the Firebase project is on the free **Spark**
> plan. 6A requires Cloud Functions and custom tokens, which need **Blaze**.
> Resume when the project is upgraded or a fallback is agreed.
> **Branch:** `harden-source-of-truth`
> **Rollback baseline:** `36cd5d5` (Phase 5D verified)
> **Fixed toolchain:** Flutter 3.24.5 · AGP 8.3.2 · Kotlin 1.9.22 · JDK 17

---

## Why this phase exists

Phase 5 shipped the product surface. Phase 6 makes it safe to operate with real
users and real money. The pilot currently has **no Firestore security rules**
and **no authenticated Firestore identity**, so any client that knows the
project ID can read or write every collection. That is the single largest
launch blocker.

Non-negotiables:

- The login experience stays **phone + 4-digit PIN**. No SMS OTP migration.
- No business logic is removed: FIFO cylinders, order statuses, referral codes,
  GasPlan interest, and the admin console keep working.
- The fixed Flutter/AGP/Kotlin toolchain is not upgraded.
- Rules are tested in the emulator before any deploy.

---

## Current posture (audited at `36cd5d5`)

| Area | Current state | Risk |
|------|---------------|------|
| Firestore rules | **None.** No `firestore.rules`; `firebase.json` has no `firestore` block | 🔴 Critical — open database |
| Client identity | Custom Firestore phone+PIN login; no Firebase Auth session | 🔴 Rules cannot identify caller |
| Admin login | Hardcoded phone/PIN in `auth_service.dart`; `admin_local` uid | 🔴 Anyone with the APK can open the console |
| Admin guard | Client-side role check only (`AdminGuard`) | 🔴 Bypassable |
| Storage rules | Any anonymous-auth caller may write any `vendor_images/{vendorId}` path | 🟠 Path ownership unenforced |
| Analytics | Computed client-side on demand | 🟠 Slow at scale, trust issues |
| Lists | Several `get()` queries with no limit | 🟠 Cost and latency grow unbounded |
| Billing | Not implemented | 🟡 Later |

Collections in use: `users`, `vendors`, `products`, `orders`, `cylinders`,
`reviews`, `notifications`, `app_settings`, `ad_requests`, `ad_placements`,
`ajira_interest`, `referrals`, `admin_audit_logs`.

---

## Proposed workstreams

### 6A. Identity bridge (prerequisite — decision required)

**Goal:** every Firestore request carries a trustworthy Firebase Auth uid,
without changing the phone+PIN login UI.

**Recommended approach — custom token exchange:**

1. Add a callable Cloud Function `loginWithPin({phone, pin})` that:
   - normalizes the phone exactly as the client does,
   - finds the `users` document by phone variants,
   - verifies the existing SHA-256 `passcodeHash`, lockout window, and attempt
     counter **server-side**,
   - returns `auth.createCustomToken(uid, {role, admin})`.
2. The client calls the function, then `signInWithCustomToken`, and keeps the
   existing local session fields for UI continuity.
3. Registration, role changes, and admin login move through the same function
   family (`registerWithPin`, `adminLogin`).
4. The short-lived anonymous sign-in used by `vendor_image_service.dart` is
   removed; uploads use the real session.
5. Admin identity becomes a **custom claim**, not a hardcoded uid. The PIN is
   read from a Functions secret, never shipped in the APK.

**Acceptance:** login, registration, lockout after 5 attempts, vendor uploads,
and admin console all work against the emulator with `request.auth` populated.

**Blocker:** custom tokens and callable functions require the Firebase project
to be on the **Blaze** plan. If the project is still on Spark, 6A cannot ship
as designed and we need to discuss the fallback (Firebase phone auth or a
hosted auth endpoint).

### 6B. Firestore rules (deny by default)

Draft matrix:

| Collection | Read | Create / update |
|------------|------|-----------------|
| `users` | own doc; admin all | own profile fields only; role/claims admin-only |
| `vendors` | public | owner vendor; admin all |
| `products` | public | owner vendor (`vendorId == auth.uid`); admin all |
| `orders` | consumer own; assigned vendor; admin all | consumer create; vendor status transitions; admin all |
| `cylinders` | owner consumer; admin all | owner consumer; admin all |
| `reviews` | public | consumer create/update own; admin moderate |
| `notifications` | own; admin all | server/admin only |
| `app_settings` | public | admin only |
| `ad_requests` | requester own; admin all | requester create; admin update |
| `ad_placements` | public | admin only |
| `ajira_interest` | admin only | signed-in create; no client read |
| `referrals` | referrer own; admin all | referrer create; admin update |
| `admin_audit_logs` | admin only | server only |

Also:

- Add `firebase.json` → `firestore.rules`.
- Add `@firebase/rules-unit-testing` tests covering owner, non-owner, vendor,
  consumer, admin, and unauthenticated cases.
- Validate all rules against the emulator before deploy.

### 6C. Storage ownership

- Replace anonymous uploads with the real session.
- `vendor_images/{vendorId}`: public read; write only when
  `request.auth.uid == vendorId` (or admin claim), plus size/type limits.
- Add rules tests for cross-vendor writes.

### 6D. Server-side admin actions

- Callable functions for privileged writes (vendor verification, role changes,
  ad approval, catalogue moderation, settings).
- Every function checks `context.auth.token.admin == true`.
- Write `admin_audit_logs` from the function, not the client.
- Remove the hardcoded admin phone/PIN from the production path after the
  function login is live. Keep a debug-only bypass behind `kDebugMode` if the
  team still needs local access.

### 6E. Pagination

- Add `limit` + `startAfter` to orders, users, vendors, and products queries.
- Keep existing filters; add incremental loading to the admin and vendor lists.
- No change to FIFO or status-transition logic.

### 6F. Analytics rollups

- Scheduled function writes daily aggregates to `analytics_daily/{yyyy-MM-dd}`
  (orders, revenue, cylinders, vendor counts).
- Admin analytics reads the rollups with a live fallback for today.
- CSV export continues to work.

### 6G. Billing (design only in this phase)

- Document subscription tiers, invoicing, and settlement.
- No payment code until 6A–6D are deployed and verified.

---

## Sequencing

1. **6A** identity bridge + emulator verification
2. **6B** Firestore rules + tests
3. **6C** Storage rules
4. **6D** Admin functions + audit logs
5. **6E** Pagination
6. **6F** Analytics rollups
7. **6G** Billing design

6A–6D must ship together before any public pilot. 6E–6F can follow.

---

## Rollback

- Rules: keep the previous ruleset in version control; `firebase deploy
  --only firestore:rules` reverts in seconds.
- Functions: deploy individually; 6A client code is behind the existing login
  service API so the UI is unaffected.
- Code rollback point: `36cd5d5`.

---

## Decisions needed before coding

1. ~~**Blaze plan:**~~ **Answered 12 Nov 2026 — the project is on Spark.**
   Phase 6 is parked until the project is upgraded to Blaze or a fallback is
   chosen. No auth or rules code will ship before that decision.
2. **Admin account:** the owner’s number (`0767304776`) will become the first
   real admin when Firebase Auth work resumes; confirm at that time.
3. **Rules rollout:** deploy straight to production after emulator tests, or
   stage on a second Firebase project first?
