# Phase 05 — Notifications & Polish

> **Status:** ✅ Complete — see [`implementation.md`](implementation.md)
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)
> **Goal:** make notifications actually useful (tap-through routing, in-app
> banners), add offline visibility, and polish accessibility on the main
> role dashboards.

---

## Scope

### In scope

1. Notification tap-through routing.
   - Parse `orderId` / `type` from FCM payloads.
   - Role-aware destination: admin → order detail, vendor → orders, consumer →
     live order tracker.
   - Handle background tap (`onMessageOpenedApp`) and cold-start
     (`getInitialMessage`).
2. In-app banner for foreground notifications with a "View" action.
3. Offline banner on consumer home, vendor dashboard, and admin shell.
4. Accessibility polish: tooltips and semantic labels on icon-only controls
   and the vendor open/closed toggle.
5. Tests and documentation.

### Out of scope

- Deep links and universal links.
- Notification preferences backend (still local toggle).
- Replacing the Cloud Function dispatcher.
- Full screen-reader audit; this phase covers the main dashboards only.

---

## Design

### Notification routing

- `lib/core/notification_routing.dart`
  - `NotificationRouteData.fromPayload(Map)` — extracts `orderId`/`type`.
  - `NotificationTarget targetFor(String? role, String? orderId)` — pure,
    testable mapping to `consumerOrder | vendorOrders | adminOrder | none`.
  - `openConsumerOrder(BuildContext, String orderId)` — fetches the order and
    opens `ConsumerOrderScreen` with the stored values.
- `NotificationService` exposes `onTapMessage` and `initialMessage()`, wired
  by `GasLinkApp` through the global `navigatorKey`.

### Offline banner

- `lib/widgets/offline_banner.dart` with an injectable connectivity stream.
- Shows a compact banner when the device has no connectivity.

### Accessibility

- `Semantics`/tooltips on the vendor dashboard app bar buttons and the
  OPEN/CLOSED toggle; tooltips on admin shell app bar actions.

---

## Verification

| Check | Target |
|---|---|
| Routing | Payload parsing and role mapping are pure and tested |
| Offline banner | Renders/hides with injected connectivity states |
| Analyzer | 0 errors, 0 warnings |
| Tests | Full suite green |

---

## Rollback

- Pre-Phase-5 baseline: **`dcaed5a`** on `origin/harden-source-of-truth`.
- Revert the Phase 5 code commit with `git revert <commit>`.
