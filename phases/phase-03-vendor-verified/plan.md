# Phase 03 — Vendor Verified Role

> **Status:** ✅ Complete — see [`implementation.md`](implementation.md)
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)
> **Goal:** make vendor verification an explicit, auditable admin decision and
> show the verified badge to consumers only when that decision exists.

---

## Why This Phase

Consumer-facing screens already render "Verified" badges, but the badge is
unconditional and the "Verified only" filter treats any vendor with a phone
number as verified. That is misleading and unsafe for a trust-sensitive LPG
marketplace.

Verification must be:

- Stored as its own field, independent of lifecycle status and computed tier.
- Granted or removed only by an admin, with an audit record.
- Rendered only when the field is true.
- Filterable on the consumer side using the real field.

---

## Scope

### In scope

1. Add `verified`, `verifiedAt`, and `verifiedBy` to `Vendor`.
2. Admin action to verify or remove verification.
3. Audit entries for `verify_vendor` and `unverify_vendor`.
4. Admin vendor list/detail indicators for verification state.
5. Consumer verified badge gated by the real field.
6. Make the consumer "Verified only" filter use the real field.
7. Unit/widget tests and documentation.

### Out of scope

- Automated KYC checks or third-party verification APIs.
- Vendor self-service verification requests.
- Public verification landing pages or QR certificates.
- Re-verification reminders and expiry.
- Firestore rules and server-side enforcement (Phase 6).

---

## Data Model

`vendors/{vendorId}` gains:

| Field | Type | Meaning |
|---|---|---|
| `verified` | bool | Explicit admin trust decision. Defaults to `false`. |
| `verifiedAt` | timestamp? | When verification was granted. Cleared on removal. |
| `verifiedBy` | string | Admin UID that granted verification. Cleared on removal. |

Rules:

- Verification is independent of `status` and `currentTier`.
- Only `active` vendors can be verified.
- Removing verification is always allowed and requires a reason.
- Existing documents default to `verified: false`; no migration is required.

---

## Admin Experience

- Vendor detail gets a **Trust & verification** card showing the current state,
  who verified the vendor, and when.
- `Verify vendor` is shown for active, unverified vendors.
- `Remove verification` is shown for verified vendors and requires a reason.
- Vendor list shows a verified indicator next to the shop name.
- Both actions write to `admin_audit_logs` in the same batch as the vendor
  update.

---

## Consumer Experience

- `SessionData.Vendor` carries `verified` from the vendor document.
- A shared `VerifiedBadge` widget renders the icon and optional label.
- Badges appear only when `verified == true` on vendor cards and vendor detail.
- The vendor search "Verified only" filter uses `vendor.verified`.

---

## Verification

| Check | Target |
|---|---|
| Vendor parsing | Missing `verified` defaults to false; true round-trips |
| Serialization | `toMap` writes `verified`, `verifiedAt`, `verifiedBy` |
| Admin service | Verify/unverify updates the vendor and writes one audit record |
| Consumer filter | `verifiedOnly` excludes unverified vendors |
| Widget | `VerifiedBadge` renders in light and dark themes |
| Analyzer | 0 errors, 0 warnings |
| Tests | Full suite green |

---

## Rollback

- Pre-Phase-3 baseline: **`20174c7`** on
  `origin/harden-source-of-truth`.
- Revert the Phase 3 code commit with `git revert <commit>` if needed.
- No data migration is required; the new fields are additive and default to
  `false` when absent.
