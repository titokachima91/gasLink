# Phase 03 — Vendor Verified Role: Implementation

> **Status:** ✅ Complete
> **Completed:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Plan:** [`plan.md`](plan.md)
> **Rollback baseline:** `20174c7`
> **Phase 3 code commit:** `645126d`

---

## Outcome

Vendor verification is now an explicit, auditable admin decision. Consumer-facing
badges render only when the stored `verified` flag is true, and the "Verified
only" discovery filter uses the same field instead of treating any vendor with a
phone number as verified.

---

## What Shipped

### Vendor model

`lib/models/vendor.dart` adds:

- `verified` (default `false`)
- `verifiedAt`
- `verifiedBy`
- `isVerified` convenience getter

The fields round-trip through `toMap` / `fromMap` and are preserved by
`copyWith`. Existing documents without the fields default to unverified, so no
migration is required.

### Admin service and audit

`lib/services/admin_service.dart` adds `setVendorVerified`:

- Rejects verification for non-active vendors.
- Allows removal at any lifecycle state.
- Clears `verifiedAt` / `verifiedBy` on removal.
- Writes `verify_vendor` or `unverify_vendor` to `admin_audit_logs` in the same
  Firestore batch as the vendor update.
- Stores the actor UID in `verifiedBy` and the optional/required reason in the
  audit record.

### Admin console

`lib/screens/admin/admin_vendor_detail_screen.dart`

- New **Trust & verification** section.
- Shows verified state, verification timestamp, and verifying admin.
- `Verify vendor` is shown for active, unverified vendors.
- `Remove verification` requires a reason.
- Header shows a `Trust: Verified` chip.

`lib/screens/admin/admin_vendors_screen.dart`

- Verified icon beside the shop name in the vendor list.

### Consumer experience

`lib/core/session_data.dart`

- `SessionData.Vendor` carries `verified`, loaded from the vendor document.

`lib/widgets/verified_badge.dart`

- Shared badge with icon-only and labelled variants.

`lib/core/filter_sort.dart`

- `verifiedOnly` now filters on `vendor.verified`.

Consumer surfaces updated:

| Screen | Behaviour |
|---|---|
| Consumer home vendor cards | Badge only when verified |
| Vendor search results | Badge only when verified; filter uses the field |
| Brand shop vendor cards | Badge only when verified |
| Item vendor list | Badge only when verified |
| Search delegate results | Badge only when verified |
| Vendor detail header | Badge only when the live vendor document is verified |

---

## Business Rules

1. Verification is independent of lifecycle status and computed tier.
2. Only `active` vendors can be granted verification.
3. Verification can be removed at any lifecycle state, with a required reason.
4. Granting verification records the admin UID and timestamp.
5. Removing verification clears the timestamp and actor.
6. The public badge is never inferred from profile completeness or phone number.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | **45/45 passing** |
| New Phase 3 tests | 4 passing: model round-trip, verified-only filter, badge light/dark, icon-only badge |
| Existing suite | Admin console, analytics, auth, session, theme tests still pass |
| Diff hygiene | Consumer diffs limited to the badge/filter changes |

---

## Known Limitations and Follow-ups

1. **Client-side trust signal only.** Firestore rules must prevent non-admin
   writes to `verified` in Phase 6.
2. **No verification expiry or re-review reminders.** Verification is currently
   open-ended.
3. **No automated KYC checks.** Admin judgement remains the source of truth.
4. **No vendor-facing verification status screen.** Vendors see their public
   badge through the existing profile surfaces; a dedicated status panel is a
   later polish item.
5. **Legacy vendors start unverified.** This is intentional; admins must review
   and grant the badge explicitly.

---

## Rollback

- Pre-Phase-3 baseline: **`20174c7`** on
  `origin/harden-source-of-truth`.
- Phase 3 code commit: **`645126d`**.
- Forward revert: `git revert 645126d`.
- Local reset: `git reset --hard 20174c7`.
- The new fields are additive. Reverting code leaves any stored `verified`
  values harmless and ignored by the older model.
