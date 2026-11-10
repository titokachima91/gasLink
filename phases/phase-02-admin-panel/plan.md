# Phase 02 — Admin & Operations Console

> **Status:** 🚧 In progress
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)
> **Goal:** replace the admin stub with a real operations console for vendor
> approval, order oversight, consumer lookup, inventory visibility, and audit.

---

## Scope

### In scope

1. Admin shell and navigation
2. Dashboard with operational KPIs
3. Vendor list, detail, KYC review, approve/suspend
4. Global order list, filters, detail, cancellation
5. Consumer list, detail, order/cylinder history
6. Inventory overview and low-stock view
7. **Operational analytics** (KPIs, trends, vendor scorecards, demand mix)
8. Admin settings (commission, support contact, districts/brands read-only)
9. Admin service/repository layer
10. Audit log for every admin mutation
11. Admin-only route guard

### Out of scope

- Rider dispatch and delivery assignment
- Payment collection, payouts, and settlement
- Vendor self-onboarding and document upload
- Advanced BI/warehouse and scheduled exports
- Multi-country configuration
- Full server-side Cloud Functions (follow-up hardening)

---

## Screens

| Screen | Features |
|---|---|
| **Dashboard** | Vendors active/pending, orders today, GMV, delivered/cancelled, low stock, recent orders, pending approvals |
| **Vendors** | Search/filter by district, tier, status; list with tier/completion; vendor detail with profile, location, KYC images, inventory, recent orders; approve, reject, suspend, reactivate |
| **Orders** | Global list; filter by status, vendor, district, date; detail with customer, vendor, items, payment method, commission, timeline; cancel with reason |
| **Consumers** | Search/list; detail with profile, order history, cylinder holdings, contact |
| **Analytics** | 7/30/90-day KPIs, order trend, status breakdown, top vendors, demand by brand/size, district performance, vendor scorecards, CSV export |
| **Inventory** | Aggregated vendor/brand/size stock; low-stock filter; vendor drill-down |
| **Settings** | Default commission, support phone, districts/brands reference view, admin account/logout |

Mobile: bottom navigation with Dashboard, Vendors, Orders, Analytics, More.
More contains Consumers, Inventory, Settings. Tablet/desktop: `NavigationRail`.

---

## Data & Security

### Vendor lifecycle

Add to `vendors/{id}`:

- `status`: `pending | active | suspended | rejected`
- `statusReason`
- `kycReviewedAt`, `kycReviewedBy`
- `updatedAt`

Keep existing `active` during migration; derive it from `status == active`.

### Audit log

`admin_audit_logs/{id}`:

- `actorUid`, `actorRole`
- `action` (approve_vendor, suspend_vendor, cancel_order, update_settings)
- `entityType`, `entityId`
- `before`, `after`
- `reason`, `createdAt`

### Access

- Central `AdminGuard` / route check.
- Firestore rules must enforce admin-only writes before production.
- Every mutation goes through `AdminService`, never directly from widgets.

### Analytics

Build a thin, trustworthy analytics vertical slice in Phase 2:

- `AnalyticsService` exposes KPIs, trends, vendor performance, demand mix, and district breakdowns.
- Use Firestore aggregate queries (`count`, `sum`, `average`) where possible.
- Structure for daily rollups in `analytics_daily/{yyyy-MM-dd}`; client-side aggregation is pilot-only.
- Define metrics once, in code:
  - **GMV:** delivered order totals
  - **AOV:** GMV / delivered orders
  - **Completion rate:** delivered / (delivered + cancelled)
  - **Cancellation rate:** cancelled / all orders
  - **Avg delivery time:** delivered_at - created_at
  - **Repeat rate:** consumers with 2+ delivered orders / active consumers
  - **Vendor fill rate:** orders accepted / orders received
- Use `Africa/Dar_es_Salaam` and TZS consistently.
- Analytics must contain no customer PII.
- Instrument key events now (`order_placed`, `order_delivered`, `vendor_approved`) so future reporting stays reliable.

---

## Build Order

| Milestone | Deliverable |
|---|---|
| **A. Foundation** | Admin shell, routing, theme, `AdminService`, audit model, guard |
| **B. Vendors** | List, filters, detail, KYC review, approve/suspend/reject |
| **C. Operations** | Orders list/detail/cancel; consumers list/detail |
| **D. Analytics** | Dashboard KPIs, trends, vendor scorecards, demand mix, CSV export |
| **E. Visibility** | Inventory overview, settings, final admin polish |
| **F. Hardening** | Loading/empty/error states, pagination, tests, docs, light/dark QA |

---

## Success Criteria

- Admin can manage the vendor lifecycle without opening Firestore.
- Admin can inspect any order or consumer and see the full timeline.
- Every admin mutation is audited.
- Non-admin users cannot reach admin routes.
- Dashboard and analytics are useful without loading entire collections.
- Every KPI has a documented definition and timezone/currency.
- `flutter analyze` has zero errors and warnings.
- `flutter test` passes.
- All new screens work in light, dark, and system mode.

---

## Risks

| Risk | Mitigation |
|---|---|
| Client-only admin checks are not security | Central guard now; Firestore rules + Cloud Functions before launch |
| Mixed camelCase/snake_case order fields | Normalize through `AdminService`/models |
| Large Firestore collections | Pagination, indexed queries, aggregate counters |
| KYC URLs missing or broken | Document placeholders and review states |
| Hardcoded admin PIN | Move to secure server-side config in a later hardening phase |
| Analytics queries become expensive or slow | Aggregate queries, date limits, daily rollups, no full-collection scans |
| KPI definitions drift | Central metric definitions in `AnalyticsService` |
| Scope creep into payments | Keep Phase 2 focused on operations + analytics only |
