# Phase 05 — Notifications & Polish: Implementation

> **Status:** ✅ Complete
> **Completed:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Plan:** [`plan.md`](plan.md)
> **Rollback baseline:** `dcaed5a`
> **Phase 5 code commit:** `04f539a`

---

## Outcome

Order notifications now do something useful: tapping one routes the right role
to the right screen, foreground notifications raise an in-app banner, and the
three main dashboards show an offline banner when connectivity drops.

---

## What Shipped

### Notification tap-through

`lib/core/notification_routing.dart` (new)

- `NotificationRouteData.fromPayload` reads `orderId` / `order_id` and `type`
  from FCM data payloads.
- `NotificationTarget targetFor(role, orderId)` is a pure, tested mapping:
  - admin → `AdminOrderDetailScreen`
  - vendor → `VendorOrderScreen`
  - consumer → `ConsumerOrderScreen` (values fetched from the order document)
  - no order id / unknown role → no-op
- `openConsumerOrder` builds the tracker screen from the stored order.

`lib/services/notification_service.dart`

- New `onTapMessage` and `onForegroundMessage` callbacks.
- `onMessageOpenedApp` wired to `onTapMessage`.
- `initialMessage()` caches and returns the cold-start message.

`lib/app.dart`

- `GasLinkApp` is now stateful; it registers both callbacks.
- Taps route through the global `navigatorKey` and `NotificationRouting`.
- Foreground order notifications show a MaterialBanner with an
  "Angalia / View" action.
- Cold-start messages are handled after the first frame.

### Offline visibility

`lib/widgets/offline_banner.dart` (new)

- Slim banner with an injectable connectivity stream (testable without the
  platform plugin).
- Shows only when the device has no connectivity.

Wired into:

- Consumer home (top of the main list).
- Vendor dashboard (top of the order feed).
- Admin shell (above the responsive layout).

Dependency: `connectivity_plus`.

### Accessibility

- `Semantics` label/value on the vendor OPEN/CLOSED store status toggle.
- The admin shell app bar actions already carry tooltips; navigation
  destinations remain labelled.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 pre-existing info lints |
| `flutter test` | **58/58 passing** |
| New Phase 5 tests | 4 passing: payload parsing, role routing, offline banner show/hide, dark mode |
| Cold start / background tap | Handled through FCM APIs; live-device QA recommended |

### Manual QA note

Tap-through behaviour (background tap, cold start) requires a physical
device/emulator with FCM; verify with a test notification before the pilot.

---

## Known Limitations and Follow-ups

1. **Tap routing uses the in-memory session.** If the session is missing, taps
   are ignored (no crash).
2. **No deep-link support**; routing only covers order notifications.
3. **Notification preferences** remain a local toggle; server-side
   preferences are not implemented.
4. **Full screen-reader audit** is out of scope; this phase covers the main
   dashboards.
5. **Banner vs heads-up duplication:** foreground order notifications show
   both the system heads-up and the in-app banner; acceptable for now.

---

## Rollback

- Pre-Phase-5 baseline: **`dcaed5a`** on
  `origin/harden-source-of-truth`.
- Phase 5 code commit: **`04f539a`**.
- Forward revert: `git revert 04f539a`.
- Local reset: `git reset --hard dcaed5a`.
