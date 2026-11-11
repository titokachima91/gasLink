# Phase 04 — Vendor Settings & Profile: Implementation

> **Status:** ✅ Complete
> **Completed:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Plan:** [`plan.md`](plan.md)
> **Rollback baseline:** `7d53a0f`
> **Phase 4 code commit:** `2aeb359`

---

## Product Decisions Applied

1. **Admin-controlled commission model.** Vendors see their terms but cannot
   change them; admins set percentage or monthly subscription per vendor.
2. **Secure Firebase Storage uploads.** Shop photos are uploaded as binaries
   with size/type limits enforced by storage rules.

---

## What Shipped

### Commission model

`lib/models/vendor.dart`

- New fields: `commissionModel` (`percentage` | `subscription`) and
  `subscriptionFee` (monthly TZS).
- Legacy vendors default to `percentage`.
- `isSubscription`, `effectiveCommissionRate` (0 for subscriptions), and
  `commissionLabel` (e.g. `5.0% per order` or `TZS 75000/month`).

`lib/models/order.dart`

- New `commissionModel` snapshot stamped as `commission_model` on every order.

`lib/services/order_service.dart`

- `placeOrder` accepts the vendor's model; subscription orders get a `0` rate
  and `0` commission due instead of a misleading percentage.

`lib/screens/consumer/consumer_order_dialog.dart`

- Orders now fetch the vendor's live commission terms instead of hardcoding
  3%.

`lib/services/admin_service.dart`

- `updateVendorCommission` validates the model and writes
  `update_vendor_commission` to the audit trail in the same batch.
- `updateSettings` now stores `defaultCommissionModel` and
  `defaultSubscriptionFee` with validation.

`lib/models/admin_models.dart`

- `AdminSettings` carries the default model and fee.

### Admin console

`lib/screens/admin/admin_vendor_detail_screen.dart`

- New **Commission terms** section: current model, rate or fee, and an edit
  dialog with percentage/subscription segments and validation.
- Read-only commission row removed from the business card.

`lib/screens/admin/admin_vendors_screen.dart`

- Vendor list chip shows `%` or `TZS …/mo`.

`lib/screens/admin/admin_order_detail_screen.dart`

- Subscription orders display "Subscription (no per-order cut)" instead of a
  misleading 0%.

`lib/screens/admin/admin_settings_screen.dart`

- Default commission model segments and default monthly fee field.

### Vendor experience

`lib/screens/vendor/vendor_settings_screen.dart` (new)

- Read-only billing card via `VendorCommissionTermsCard`.
- Store profile shortcut, theme picker, notification toggle, about/support
  section (tap-to-call), and sign-out.

`lib/screens/vendor/widgets/vendor_commission_card.dart` (new)

- Reusable, testable billing summary with the "Managed by GasLink" note.

- Wired into the vendor drawer ("Mipangilio / Settings") and a settings icon
  in the vendor dashboard app bar.

### Secure shop photo upload

`lib/services/vendor_image_service.dart` (new)

- Uploads to `vendor_images/{vendorId}/shop_<ts>.<ext>`.
- Pure validators: image content types only and a 5 MB cap.
- Short-lived anonymous Firebase Auth sign-in to satisfy storage rules, with
  sign-out in `finally` so app identity resolution is untouched.

`lib/screens/vendor/vendor_profile_screen.dart`

- Live photo preview, gallery picker (re-encoded to ≤1600px JPEG/85 quality),
  progress state, upload, and immediate `imageUrl` write to the vendor
  document.

`storage.rules` + `firebase.json`

- Public reads; writes require an authenticated Firebase Auth user, an
  `image/*` content type, and a size under 5 MB.

Dependencies: `firebase_storage ^12.4.10`, `image_picker ^1.1.2`.

### Consumer polish

`lib/screens/vendor_list_screen.dart`

- Shows the verified badge next to shop names (consumer-facing list).

---

## Business Rules

1. Percentage rate must be in `[0, 1]`; subscription fee must be `>= 0`.
2. Subscription vendors pay no per-order commission; the monthly fee is the
   only term.
3. Only admins change terms; every change is audited.
4. Orders stamp the vendor's model at creation time so history stays accurate.
5. Uploaded images are capped at 5 MB and must be `image/*`.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | **54/54 passing** |
| New Phase 4 tests | 9 passing: commission model, order stamping, image validation, billing card light/dark/subscription/missing |
| Diff hygiene | Vendor settings/UI changes isolated to Phase 4 files |

### Manual QA note

- Image upload requires the Firebase project's anonymous auth provider and a
  Storage bucket with `storage.rules` deployed (`firebase deploy --only
  storage`). These cannot be verified from this environment; the client
  degrades with a clear error message when they are unavailable.
- Runtime visual QA on a device remains recommended before the pilot.

---

## Known Limitations and Follow-ups

1. **Per-vendor path ownership is not server-enforced.** Storage rules check
   Firebase Auth presence, size, and type; verifying the custom session per
   upload path moves to Cloud Functions in Phase 6.
2. **Subscription billing is not implemented.** The model is stored and
   stamped; invoicing and payment collection remain Phase 6 work.
3. **Replaced photos are not deleted** from Storage; retention cleanup is a
   follow-up.
4. **Anonymous auth provider** must be enabled in the Firebase console for
   uploads to work.
5. **New vendors default to `percentage`** at the pilot default rate; admin
   sets the subscription model per vendor.
6. **`vendor_list_screen.dart`** remains a legacy read-path screen; it now
   shows the verified badge but is not wired into the current navigation.

---

## Rollback

- Pre-Phase-4 baseline: **`7d53a0f`** on
  `origin/harden-source-of-truth`.
- Phase 4 code commit: **`2aeb359`**.
- Forward revert: `git revert <phase-4-code-commit>`.
- Local reset: `git reset --hard 7d53a0f`.
- The new fields are additive; existing vendors and orders default to
  `percentage`. Reverting code leaves any stored values harmless.
