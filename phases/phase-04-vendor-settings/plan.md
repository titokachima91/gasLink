# Phase 04 — Vendor Settings & Profile

> **Status:** ✅ Complete — see [`implementation.md`](implementation.md)
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)
> **Goal:** give vendors a real settings surface, make the commission model an
> explicit admin-controlled term, and let vendors upload a shop photo securely.

---

## Product Decisions (confirmed with owner)

1. **Commission model is admin-controlled.** Vendors see their current terms
   (percentage or monthly subscription) but cannot change them. Admins set the
   model per vendor.
2. **Vendor images use secure Firebase Storage.** Binary upload replaces the
   URL-only field, with size and content-type limits enforced by storage rules.

---

## Scope

### In scope

1. `Vendor` commission fields: `commissionModel`, `subscriptionFee`.
2. Order stamping of `commission_model`; subscription vendors pay no
   per-order percentage.
3. Admin vendor detail: commission section with model/rate/fee editor.
4. Admin settings: default commission model and default subscription fee.
5. Admin order detail: subscription-aware commission display.
6. Vendor settings screen (commission terms, profile shortcut, theme,
   notifications, account, sign-out).
7. Shop photo upload via Firebase Storage with picker, preview, and rules.
8. Tests and documentation.

### Out of scope

- Subscription billing, invoicing, and payment collection.
- Vendor self-service commission changes.
- Deleting replaced shop photos from Storage (retention cleanup later).
- Server-side verification of the custom session (Phase 6); storage rules use
  Firebase Auth presence plus size/type limits.
- Cloud Functions deployment for uploads.

---

## Data Model

`vendors/{vendorId}` gains:

| Field | Type | Meaning |
|---|---|---|
| `commissionModel` | string | `percentage` (default) or `subscription` |
| `subscriptionFee` | num | Monthly TZS fee when model is `subscription` |

`orders/{orderId}` gains:

| Field | Type | Meaning |
|---|---|---|
| `commission_model` | string | Snapshot of the vendor's model at order time |

`app_settings/admin` gains:

| Field | Type | Meaning |
|---|---|---|
| `defaultCommissionModel` | string | Applied to new vendors |
| `defaultSubscriptionFee` | num | Monthly TZS default for subscription vendors |

Rules:

- Percentage model: rate must be in `[0, 1]`.
- Subscription model: `subscriptionFee >= 0`; effective per-order commission
  rate is `0`.
- Orders always stamp the vendor's model at creation time.

---

## Admin Experience

- Vendor detail commission row becomes an editable **Commission terms** card:
  model, rate or fee, with a dialog to change them.
- Changing commission writes `update_vendor_commission` to the audit trail.
- Vendor list shows the model (`%` or `TZS/mo`).
- Order detail shows `Subscription` for subscription vendors instead of a
  misleading 0%.
- Admin settings gain default model and default subscription fee inputs.

---

## Vendor Experience

- New **Settings** screen, reachable from the dashboard and drawer.
- Read-only commission terms card: model, current rate or monthly fee, and a
  note that GasLink manages these terms.
- Shop photo upload: gallery picker, 5 MB / image-type limit, progress state,
  preview, and error handling.
- Theme picker, notification toggle, about section, and sign-out.

---

## Storage Security

- `storage.rules` (new) allows public reads of `vendor_images` but requires an
  authenticated Firebase Auth user for writes, with a 5 MB size cap and
  `image/*` content type only.
- The app signs in anonymously with Firebase Auth at startup (best-effort) so
  uploads can pass the rule.
- Per-vendor path ownership cannot be verified until the custom session is
  checked server-side; documented as Phase 6 hardening.

---

## Verification

| Check | Target |
|---|---|
| Vendor model | Commission fields round-trip; subscription ⇒ effective rate 0 |
| Order stamping | `commission_model` written; due = 0 for subscription |
| Admin service | Validations enforced; audit record written |
| Storage service | Size/type validation helpers are pure and tested |
| Vendor settings widget | Renders in light/dark; shows model and fee |
| Analyzer | 0 errors, 0 warnings |
| Tests | Full suite green |

---

## Rollback

- Pre-Phase-4 baseline: **`7d53a0f`** on `origin/harden-source-of-truth`.
- Revert the Phase 4 code commit with `git revert <commit>`.
- The new fields are additive; legacy vendors and orders default to
  `percentage`.
