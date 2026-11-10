# Phase 02 — Admin & Operations Console: Implementation

> **Status:** ✅ Complete
> **Completed:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Plan:** [`plan.md`](plan.md)
> **Rollback baseline:** `4c89d66`
> **Phase 2 code commit:** `5bed4fb`

---

## Outcome

The admin stub has been replaced with a responsive operations console. Admins can
review vendor KYC and lifecycle state, inspect global orders and consumers, see
catalogue coverage, review operational analytics, export a CSV snapshot, change
commercial defaults, and inspect an append-only audit trail.

All admin mutations go through `AdminService` and write an audit record in the
same Firestore batch as the change. Non-admin roles cannot render the console.

---

## What Shipped

### Shell, navigation, and access

- `lib/screens/admin/admin_shell.dart`
  - Compact layouts: bottom navigation with Dashboard, Vendors, Orders,
    Analytics, and More.
  - More contains Consumers, Inventory, and Settings.
  - Tablet/desktop (`>= 900px`): `NavigationRail`, extended at `>= 1180px`.
  - App bar: audit shortcut, theme picker, admin menu, sign-out.
- `lib/screens/role_router.dart` now routes `AuthService.roleAdmin` to
  `AdminShell`; the old `admin_vendor_screen.dart` stub was removed.
- `lib/core/admin_guard.dart`
  - Central `AdminGuard.canAccess(role)` check.
  - `AdminAccessDenied` screen for non-admin sessions.
- Theme picker and sign-out are available from the shell and settings.

### Dashboard

`lib/screens/admin/admin_dashboard_screen.dart`

- Active vendors, pending KYC, orders today, GMV today, delivered today,
  cancelled today, out-of-stock items, and consumer count.
- Pending-approval queue with direct vendor links.
- Recent orders with direct order links.
- Inventory attention list for out-of-stock catalogue items.
- Pull-to-refresh and loading/error/empty states.

### Vendors

`lib/screens/admin/admin_vendors_screen.dart`,
`lib/screens/admin/admin_vendor_detail_screen.dart`

- Search across shop name, phone, district, and owner UID.
- Status, district, and tier filters; clear-filters action.
- Vendor detail: business/contact data, location, payments, commission, tier,
  profile completion, delivery count, rating, KYC document links, catalogue,
  recent orders, and status reason.
- Lifecycle actions: approve, reject (reason required), suspend (reason
  required), reactivate.
- KYC documents open externally; missing documents are called out.

### Orders

`lib/screens/admin/admin_orders_screen.dart`,
`lib/screens/admin/admin_order_detail_screen.dart`

- Global order list, latest 300 loaded.
- Status, district, date-range (7/30/90/all-time), and free-text filters.
- Delivered value in view plus a clear load-limit note.
- Order detail: customer/contact/address, vendor lookup, line item, payment,
  commission snapshot, seven-stage timeline, and cancellation reason.
- Admin cancellation requires a reason, blocks delivered orders, writes
  cancellation metadata, and sends a cancellation notification when possible.

### Consumers

`lib/screens/admin/admin_consumer_list_screen.dart`,
`lib/screens/admin/admin_consumer_detail_screen.dart`

- Search by name, phone, or UID.
- Profile, order count, delivered count, lifetime delivered value.
- Cylinder holdings from `users/{uid}/cylinders`.
- Full order history with links to order detail.
- No PIN material is loaded.

### Analytics

`lib/services/analytics_service.dart`,
`lib/models/analytics.dart`,
`lib/screens/admin/admin_analytics_screen.dart`

- 7/30/90-day ranges.
- KPI cards: GMV, orders, AOV, completion rate, cancellation rate, average
  delivery time, repeat rate, delivered consumers.
- Daily order trend chart.
- Status breakdown.
- Top vendors by GMV.
- Demand by brand and cylinder size.
- District performance.
- Vendor scorecards: orders, delivered, cancelled, GMV, fill rate, average
  delivery time.
- CSV export.
- Metric definitions are repeated in the UI footer so operators can see how
  numbers are calculated.

### Inventory

`lib/screens/admin/admin_inventory_screen.dart`

- Top-level `products` aggregation by brand and size.
- In-stock/out-of-stock counts, vendor coverage, and price range.
- Out-of-stock filter and brand/size search.
- Vendor-offer drill-down with price and stock state.

### Settings and audit

`lib/screens/admin/admin_settings_screen.dart`,
`lib/screens/admin/admin_audit_log_screen.dart`

- Default commission, support phone, and support email.
- Read-only pilot districts and brands.
- Admin account summary, theme picker, audit shortcut, and sign-out.
- Audit trail shows action, entity, actor, reason, timestamp, and before/after
  summaries.
- Settings changes are audited.

---

## Data Model Changes

### Vendor lifecycle

`lib/models/vendor.dart` adds:

- `status`: `pending | active | suspended | rejected`
- `statusReason`
- `kycReviewedAt`, `kycReviewedBy`
- `updatedAt`

Compatibility:

- Legacy documents without `status` derive it from `active`.
- `active` is kept in sync with `status == active` on writes.
- `VendorStatus.normalize` maps legacy aliases (`approved`, `verified`,
  `disabled`, `inactive`, `declined`) into the canonical states.
- New `Vendor.fromMap` constructor keeps parsing testable without Firestore.

### Order cancellation metadata

`lib/models/order.dart` adds:

- `cancelledAt`
- `cancellationReason`

`AdminService.cancelOrder` writes `cancelled_at`, `cancellation_reason`,
`cancelled_by`, and `updated_at`, then attempts the existing customer
notification path.

### Admin projections

`lib/models/admin_models.dart`:

- `AdminAuditLog`
- `AdminConsumer`
- `AdminProduct`
- `AdminCylinder`
- `AdminSettings`
- `AdminDashboardData`

### Product stock compatibility

Vendor stock toggles now write both `in_stock` and `inStock` so older readers and
the admin inventory view stay consistent. `AdminProduct` accepts either key.

---

## Analytics Definitions

Fixed in `AnalyticsService` and `AnalyticsSnapshot`:

| Metric | Definition |
|---|---|
| GMV | Sum of delivered order totals |
| AOV | GMV ÷ delivered orders |
| Completion rate | Delivered ÷ (delivered + cancelled) |
| Cancellation rate | Cancelled ÷ all orders in range |
| Average delivery time | `delivered_at - created_at` for delivered orders |
| Repeat rate | Consumers with 2+ delivered orders ÷ consumers with a delivery |
| Vendor fill rate | Accepted orders ÷ orders received |
| Timezone | `Africa/Dar_es_Salaam` (UTC+3, no DST) |
| Currency | TZS |

Analytics contains no customer PII. Consumer lookup is a separate admin screen.

### Pilot-stage aggregation

The analytics query is date-bounded and capped at 2,000 orders. Aggregation runs
client-side because the tab needs several derived views (daily trend, status
mix, vendor scorecards, district performance, demand mix) that would otherwise
require many round-trips. This is explicitly a pilot-stage choice. Daily rollups
in `analytics_daily/{yyyy-MM-dd}` and indexed aggregate queries are follow-up
scale work.

---

## Audit Coverage

Every current admin mutation writes to `admin_audit_logs/{id}` in the same batch
as the underlying change:

- `approve_vendor`
- `reject_vendor`
- `suspend_vendor`
- `reactivate_vendor`
- `cancel_order`
- `update_settings`

Each record includes `actorUid`, `actorRole`, `action`, `entityType`,
`entityId`, `before`, `after`, `reason`, and `createdAt`.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 51 info lints (pre-existing style/doc-comment lints) |
| `flutter test` | **41/41 passing** |
| New analytics tests | 5 passing: KPIs, trend range, breakdowns, CSV, fixed definitions |
| New admin console tests | 6 passing: guard, legacy status derivation, lifecycle serialization, access denial, compact/wide navigation, dark-mode render |
| Theme guard | Existing legacy-color guard still passes |
| Formatter | Changed files formatted with `dart format` |
| Responsive shell | Automated smoke test at 400×800 (bottom navigation) and 1280×900 (navigation rail) |
| Dark mode | Automated shell render in dark mode with no exceptions |

### Manual QA note

Runtime visual QA on a physical device/emulator is still recommended before the
pilot. The local macOS build previously failed on a missing Podfile and the web
build attempt hung in this environment, so this phase was verified through
widget smoke tests, analyzer, and the full test suite rather than a live device
session.

---

## Known Limitations and Follow-ups

1. **Client-side admin checks are not security.** `AdminGuard` is UX/access
   control only. Firestore rules and server-side enforcement must land before
   production.
2. **Hardcoded admin login remains.** Phone `+255767304776`, PIN `0000`, UID
   `admin_local`. Move admin identity to secure server-side configuration.
3. **Analytics is pilot-scale.** 2,000-order cap, client aggregation, no daily
   rollups or scheduled exports.
4. **Order and dashboard lists are capped.** Orders load the latest 300;
   dashboard uses the latest 300 orders. Add pagination before volume grows.
5. **CSV export fallback.** Web triggers a file download; other platforms copy
   the CSV to the clipboard instead of adding a file-system dependency.
6. **KYC documents open externally.** No in-app image/PDF viewer.
7. **Legacy product document IDs.** `brand_editor_screen.dart` still contains a
   pre-existing malformed document-ID interpolation. Standardizing product IDs
   is a follow-up migration, not part of this phase.
8. **Out of scope by design:** rider dispatch, payments/settlement, vendor
   self-onboarding/document upload, multi-country configuration, Cloud
   Functions.

---

## Rollback

- Pre-Phase-2 baseline: **`4c89d66`** on
  `origin/harden-source-of-truth`.
- Phase 2 code commit: **`5bed4fb`**.
- To undo the phase locally:
  - `git revert <phase-2-code-commit>` for a forward revert, or
  - `git reset --hard 4c89d66` on a local branch.
- To undo on the remote, prefer `git revert <phase-2-code-commit>` and push.
  Force-pushing rewritten history requires team coordination.

The baseline includes the completed theme overhaul, cleaned documentation, and
the Phase 2 plan.
