# Phase 5D — Vendor Polish & Growth Hooks

> **Status:** ✅ Complete
> **Baseline:** `cbae13e` + Phase 5C (`f536788`)
> **Branch:** `harden-source-of-truth`
> **Rule:** no business logic removed or changed — restyles, additions, and
> navigation only.

---

## Slices shipped

| Slice | Commit | Summary |
|-------|--------|---------|
| 1. Vendor polish | `1fd5630` | Drawer icon tiles + verified chip, dashboard verification card, badge chip, inventory/order/profile restyles |
| 2. GasPlan teaser | `dd2f629` | `GasPlanScreen`, `ajira_interest` interest form, share-with-HR, single Settings → Features entry |
| 3. Referral foundation | `ec45524` | Deterministic codes, `referrals` collection, shared `ReferralCard`, consumer vendor-invite form, vendor dashboard/settings surfaces |
| 4. Dependency pin | `f09d678` | `share_plus 10.1.4` for the AGP 8.3 toolchain |

---

## D. Vendor polish

- **Drawer** — emoji replaced with rounded icon tiles, GasLink logo avatar
  fallback when the store has no photo, verified chip beside the tier badge.
- **Dashboard** — verification status card: “Umethibitishwa / Verified” with a
  success pill when verified, otherwise a “Pata Badge ya Uhakiki” CTA that
  opens the badge hub.
- **Badge hub** — verified chip on the hero and a shared section header.
- **Inventory** — design-kit cards with price/stock pills, shared empty state,
  count header, switch and delete actions preserved. Merged catalogue logic
  untouched.
- **Order manager** — per-tab section headers with counts, shared empty state,
  `AppStatusPill` status chips; all status transitions and the 10-minute
  fallback handler untouched.
- **Profile** — plain “Section A…” labels replaced with `AppSectionHeader`;
  fields, validations, and photo upload unchanged.

---

## E1. GasPlan kwa Waajiriwa (teaser only)

- **Placement:** Consumer Settings → **Vipengele / Features** → “GasPlan kwa
  Waajiriwa — Inakuja”. Not present on the landing page, consumer home, or any
  public surface.
- **GasPlanScreen:** hero pitch (“Gesi ya uhakika kila mwezi. Malipo kupitia
  payslip.”), three steps, benefit chips, example plan, and clear
  “coming soon” framing.
- **Register interest:** mini-form (name, phone, optional employer) writes to
  `ajira_interest` with `source`, `status: new`, and `createdAt`.
- **Share with HR:** `share_plus` share sheet with the concept text.
- **No billing, payouts, or subscription logic.**

---

## E2. Referral foundation

- **Codes:** deterministic 6-character codes generated from the uid using a
  readable alphabet that excludes `0/O/1/I/L`. Stored on `users/{uid}` and
  `vendors/{id}`; recomputable if the field is missing.
- **`referrals/{id}`:** `referrerUid`, `referrerRole`, `refereeRole`,
  `refereeShopName`, `refereePhone`, `status` (`invited`), `createdAt`.
- **Consumer home:** “Alika & Pata Zawadi” card with the consumer code, copy
  and share actions, invited count, and a “Mwalike muuzaji wa gesi” mini-form
  that writes a `refereeRole: vendor` referral.
- **Vendor dashboard:** “Alika Wauzaji Wenzako” card with the vendor code and
  invited count.
- **Vendor settings:** dedicated referral section with the same card.
- **Rewards:** every surface says “Zawadi zinakuja hivi karibuni.” No amounts,
  balances, or payout logic.

---

## Toolchain compatibility pins

This project stays on **Flutter 3.24.5 / AGP 8.3.2 / Kotlin 1.9.22** because
the development Mac runs macOS Monterey. Two dependency pins keep that
toolchain buildable:

| Pin | Reason |
|-----|--------|
| `share_plus: 10.1.4` | v12 resolves `compileSdk` from `flutter.compileSdkVersion`, which is null under this Flutter/AGP combination. |
| FlutterFire Feb 2025 set: `firebase_core 3.11.0`, `firebase_auth 5.4.2`, `cloud_firestore 5.6.3`, `firebase_messaging 15.2.2`, `firebase_storage 12.4.2` | Newer FlutterFire releases use Firebase BoM 33.9+ / `firebase-auth` 23.2.x, compiled with Kotlin 2.1 metadata. This set uses BoM 33.8.0 / `firebase-auth` 23.1.0 (Kotlin 1.9 metadata) and matching plugin APIs. |

Do not bump either pin without upgrading the whole Android toolchain.

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 errors, 0 warnings (51 info lints) |
| `flutter test` | 85/85 passing |
| New tests | `test/gas_plan_test.dart` (render/CTA/dark mode), `test/referral_code_test.dart` (determinism, alphabet, collisions, empty uid) |
| Android release build | ✅ `flutter build apk --release` succeeded on 12 Nov 2026 — `build/app/outputs/flutter-apk/app-release.apk`, 56,769,554 bytes (56.8 MB), SHA-256 `244d39e909ee581df5c4c415d14f178fccccecb3a79f748138e7fee778d83a9b`; ZIP integrity verified; signed with the project's debug keystore (no release keystore configured) |
| Toolchain | Flutter 3.24.5 · AGP 8.3.2 · Gradle 8.10.2 · Kotlin 1.9.22 · JDK 17 |
| Business logic | FIFO, order flows, auth, and admin console untouched |

> **Build command used:**
>
> ```bash
> JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home \
> JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true" \
> flutter build apk --release
> ```
>
> Build note for this Mac: Java's `InetAddress.getLocalHost()` hangs on the
> unresolvable `apples-MacBook-Air.local` name. `preferIPv4Stack=true` avoids
> the mDNS stall while keeping external DNS working. If the Kotlin compile
> daemon cannot be reached after a restart, the Kotlin plugin falls back to
> in-process compilation and the build still succeeds; stop stale Gradle/Kotlin
> daemons before rebuilding if it hangs. These are environment workarounds, not
> project changes.

---

## New Firestore collections

| Collection | Purpose |
|------------|---------|
| `ajira_interest` | GasPlan employer/employee interest submissions |
| `referrals` | Invite records for consumers and vendors |

Security rules for both are deferred to Phase 6, consistent with the rest of the
pilot.

---

## Rollback

Revert slices in reverse order:

```bash
git revert ec45524 dd2f629 1fd5630
```

Reverting slice 1 also removes the `share_plus` dependency; revert slices 2–3
first if only the growth hooks need to be undone.
