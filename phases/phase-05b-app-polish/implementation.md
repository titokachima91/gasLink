# Phase 05B — App Polish & First Impressions: Implementation

> **Status:** ✅ Complete
> **Completed:** 2026-11-11
> **Branch:** `harden-source-of-truth`
> **Plan:** [`plan.md`](plan.md)
> **Rollback baseline:** `7632732`

**Ground rule honoured:** nothing was removed. The cylinder smart hub, FIFO
gas measurement, order flows, and session/auth logic are untouched. This phase
only fixes the agreed bugs, rearranges layout, and adds the agreed features.

---

## Bug fixes

### A. Vendor catalogue vs consumer catalogue

Root causes: the consumer reads top-level `products` while the vendor
inventory/dashboard read the per-vendor subcollection, and
`brand_editor_screen.dart` built doc ids with un-interpolated `{_uid}` /
`{widget.brand}` so brands overwrote each other.

Fixes:

- `lib/services/catalog_service.dart` — merged catalogue (top-level +
  legacy subcollection), deduped by id with top-level winning; write helpers
  target each document's own collection.
- `InventoryScreen` now lists the merged catalogue and reloads after every
  change; new products still go top-level.
- Brand editor uses `'${_uid}__${widget.brand}__$size'` and deletes the
  corrupted legacy-literal ids on every save (self-healing migration).
- Vendor dashboard stock count reads top-level products.

### B. Extra-services count

Root cause: fuzzy legacy matching let one stored entry mark multiple
checkboxes, and the weighing consent looked like a service.

Fixes:

- `lib/utils/service_normalizer.dart` — maps stored entries to exactly one
  canonical service and dedupes; profile screen normalizes on load.
- Weighing consent stays its own compliance field; never counted.
- Badge screen Tier 1 rows are computed from real data instead of hardcoded
  `done: true`.

### C. Guest vs registered consumer

Root cause: guests and consumers shared one home screen with identical
features.

Fixes:

- `AuthService.isGuest` / `isRegisteredConsumer` / `isVendor` / `isAdmin`.
- `lib/core/session_gate.dart` — `requireConsumer()` opens a sign-in sheet and
  gates every order CTA (vendor detail sizes, accessories, brand shop, item
  vendors).
- Guest consumer home shows a sign-in banner instead of the order tracker and
  cylinder gauges; browsing quick actions stay.

---

## Design system

`lib/widgets/app_ui.dart` — `AppCard`, `AppSectionHeader`, `AppStatusPill`,
`AppEmptyState`, `AppSkeleton`; same visual discipline as the admin console,
verified in light/dark.

## Landing page

`lib/screens/auth/landing_screen.dart` — shown to unauthenticated visitors:
hero, value props, how-it-works steps, district chips, ad slot, login /
register / explore-as-guest CTAs. `RoleRouter` now opens the landing instead
of the login form; login is one tap away.

## Screen restyles (rearranged, logic untouched)

- **Vendor detail:** every cylinder size is now its own row with price, stock
  pill, and order button (previously one weight pill at a time).
- **Consumer home:** welcome header and price pills on vendor cards.
- **Vendor dashboard:** 2×2 KPI grid (orders, revenue, pending, out-of-stock)
  and a full empty-pipeline card with an inventory CTA.

## Ads (audience-aware, non-intrusive)

- `AdPlacement` / `AdRequest` models + `lib/services/ad_service.dart`.
- `lib/widgets/ad_slot.dart` — renders only campaigns matching the active
  role (`consumer | vendor | both`), per-session dismiss, external links, and
  an "Advertise Here" placeholder that opens the pitch screen.
- `lib/screens/advertise_screen.dart` — stakeholder pitch + request form →
  `ad_requests`.
- Admin **Ad requests** screen in the More hub: review, call, mark contacted.
- Placements: landing, consumer home, vendor dashboard (B2B audience).

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 49 info lints (baseline was 51) |
| `flutter test` | **75/75 passing** |
| New tests | 12: catalog merge, service normalizer, session gate, landing, ad slot (6) |
| Logic safety | `cylinder_fifo.dart`, `OrderService`, `AuthService` flows untouched |
| Guest gating | Order CTAs across 4 screens route through `SessionGate` |

---

## Known limitations / follow-ups

1. **Admin creates campaigns manually** — the review screen marks requests
   contacted; converting a request into an `ad_placements` doc is currently a
   manual Firestore write. A creation form is a small follow-up.
2. **Legacy subcollection docs remain** visible and editable until vendors
   re-save; corrupted brand docs self-heal on the next brand save.
3. **Guest session persists** (as before); the landing re-shows only for a
   fresh install or after logout.
4. **Ad images** (`imageUrl`) are supported in the model but the slot renders
   text-only for now; image banners are a follow-up.

---

## Rollback

- Pre-phase baseline: **`7632732`**.
- Commits: `5c7ae57` (fixes A–C), `2f30d8b` (design kit + landing),
  `5e2c6d2` (restyles), `c1f44a8` (ads).
- Revert any slice independently with `git revert <commit>`.
