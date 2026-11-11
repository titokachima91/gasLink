# Phase 05B — App Polish & First Impressions

> **Status:** ✅ Complete — see [`implementation.md`](implementation.md)
> **Roadmap:** [`../../ROADMAP.md`](../../ROADMAP.md)
> **Rollback baseline:** `ffc0dca` on `origin/harden-source-of-truth`

**Goal:** housekeeping, not rebuilding. Fix two data bugs, then restyle the
app's public and vendor surfaces to the same visual standard as the admin
console — attractive, consistent, and trustworthy — plus a landing page, a
guest browse path, and self-serve ad slots.

---

## 1. Bug fixes and access model (root causes found)

### A. Vendor has more items than consumers see

The catalogue is split across two stores:

| Writer / reader | Location |
|---|---|
| Consumer reads (vendor detail, `SessionData`, admin inventory) | top-level `products` |
| Vendor `InventoryScreen` + dashboard stock section | subcollection `vendors/{uid}/products` |
| `add_product_dialog`, `brand_editor` | top-level `products` |
| `vendor_repository` | subcollection |

So subcollection items are invisible to consumers. Additionally,
`brand_editor_screen.dart:128` builds the document id as
`'{_uid}__{widget.brand}__$size'` — `_uid` and `widget.brand` are **not**
interpolated, so two brands of the same size overwrite each other (vendor sees
everything, consumer sees only the last brand's docs).

**Fix**

1. `InventoryScreen` lists a merged view of both stores (deduped by id, keeping
   each doc's real reference). Edits/toggles/deletes write to the source
   collection; **new items always go top-level**.
2. Fix the brand editor doc id to `'${_uid}__${widget.brand}__$size'` and, on
   save, delete any docs left with the old literal `{_uid}__{widget.brand}__`
   ids for that vendor.
3. Vendor dashboard stock section reads top-level products.

### B. Extra-services count is wrong

`VendorProfileScreen` stores a `Set<String>` of services but matches with
fuzzy legacy rules (`contains`/partial matching), so one stored entry can
mark multiple checkboxes as checked and the "N zimechaguliwa" counter can
disagree with what is ticked. The mandatory "weighing in front of the
customer" consent (`agreedToConsumerProtection`) sits in Section D but the
badge screen hardcodes Tier 1 requirements (`'done': true`), so vendors see
"2+ services selected" without ticking them.

**Fix**

1. Normalize stored services on load: map every stored entry to exactly one
   standard service string, dedupe.
2. Count only genuinely ticked services; the weighing consent is a compliance
   checkbox, never counted as a service.
3. Badge screen Tier 1 requirement rows computed from real data instead of
   hardcoded `done: true`.

### C. Guests and registered consumers are identical

Today `loginAsGuest()` sets role `guest` (no uid) and `RoleRouter` sends
guests to the **same** `ConsumerHomeScreen` as registered consumers, with the
same gauges, cylinders, and order history sections. Only the order dialog's
empty-uid snackbar differs — so an unregistered visitor effectively looks like
a customer until checkout fails.

**Fix — explicit visitor vs customer model:**

1. `AuthService.isGuest` / `isRegisteredConsumer` getters (single source of
   truth; the persisted guest session already exists).
2. `SessionGate` helper (`lib/core/session_gate.dart`):
   - `requireConsumer(BuildContext)` → opens a **Sign in / Create account**
     bottom sheet and returns whether a real consumer session exists.
   - Every order CTA (vendor detail, browse, brand shop, item vendors, order
     dialog) and every consumer-only section (Oda Zangu, cylinders, order
     history) is gated through it.
3. Guest-mode consumer home:
   - Slim **guest banner** ("Unaangalia kama mgeni · Ingia kuagiza") with
     Sign-in / Register buttons.
   - Gauges, cylinders, and tracker sections replaced by one **"Ingia
     kuagiza na kufuatilia oda zako"** card; browsing quick actions stay.
   - Order buttons show **"Ingia kuagiza"** instead of "Oda Sasa".
4. Landing "Explore as guest" → guest session → read-only browse.
   Landing "Get Gas" → login → registered features.
5. Login/register keep working as today; after login the router rebuilds the
   home screen with full features (no data migration needed).

---

## 2. Design system (same discipline as the admin console)

Reusable building blocks in `lib/widgets/app_ui.dart` (mirroring
`admin_ui.dart`):

- `AppCard` — 12px radius, `outlineVariant` border, flat (no shadow),
  consistent padding.
- `AppSectionHeader` — icon + title + optional subtitle, uppercase micro-label.
- `AppChip` / `StatusPill` — small rounded chips using semantic colors.
- `AppEmptyState` — tinted icon circle + title + message + optional CTA.
- `AppSkeleton` — pulsing placeholder for list loading.
- `AdSlot` — see §4.
- Spacing scale: 16 page padding, 12 between sections, 10 inside cards.
- Type scale: screen titles `titleLarge w800`; card titles `titleMedium w700`;
  metadata 12px `onSurfaceVariant`.
- Every change verified in light and dark, compact and wide.

---

## 3. Proposed layouts (screen by screen)

### NEW — Landing page (`LandingScreen`)

Shown to guests at app start instead of the login form.

- **Hero:** flame mark, "Gesi Mkononi. Uthibitisho Kabla ya Ununuzi." headline,
  one-line subtext, primary CTA **"Pata Gesi / Get Gas"** → login, secondary
  **"Chunguza Bila Kuingia / Explore as guest"** (starts a persisted guest
  session).
- **Value props:** 3 compact cards (Verified vendors · Delivery to your door ·
  Fair market prices).
- **How it works:** 3 numbered steps (Browse → Order → Track).
- **Trust strip:** districts served chips + "Dar es Salaam first" note.
- **Ad banner slot** above the footer (see §4).
- **Footer CTA bar (sticky):** Login / Create account.
- Login stays one tap away; guests browse read-only — any order action opens a
  "sign in to continue" sheet.

### Login / Register

- Centered card on brand background: logo, phone + PIN, helper text, role note.
- Consistent `AppCard` styling; no layout change to logic.

### Consumer Home

- **Guest mode:** slim banner (guest chip + Sign-in/Register); gauges,
  cylinders, and tracker replaced by a single "Ingia kuagiza na kufuatilia"
  card; browsing quick actions stay active.
- **Greeting header:** "Habari, Jina 👋" + district/address chip (registered
  consumers only).
- **Quick actions:** 4 tiles (Refill · Full Set · Vifaa · Huduma) in a 2×2 or
  row — replaces the plain list feel.
- **Ad slot** directly under quick actions (dismissible).
- **Nearby vendors:** cards with a 64px cover (photo or tinted initials),
  name + verified badge, min price ("Kuanzia TZS …"), distance, brand chips,
  rating; consistent with the search/browse cards.
- **Oda Zangu tracker** and **Cylinder gauges** kept, restyled into `AppCard`s
  with section headers.
- Empty states get illustrations-style icons + a CTA ("Tafuta muuzaji karibu").

### Vendor Detail

- **Hero card:** photo/banner, name, verified badge, rating, open/closed pill,
  district line, call + directions icons.
- **Price table per brand:** every available size shown at once (price +
  stock pill) instead of one weight pill at a time — fixes the "I only see
  some items" feel.
- **Services chips** and delivery terms as clean rows.
- **Sticky bottom order bar:** selected item summary + "Oda Sasa" button; for
  guests it reads **"Ingia kuagiza / Sign in to order"** and opens the sign-in
  sheet.

### Browse / Search / Brand shop / Item vendors

- One shared vendor card design (same as consumer home) everywhere.
- Section headers + filter chips styled like the admin filters.
- Empty result states with clear guidance.

### Vendor Dashboard (currently sparse)

- **Header:** store name + OPEN/CLOSED toggle (kept).
- **Today KPI row:** orders, revenue, pending, rating — 4 `AppCard` tiles.
- **Quick actions grid:** Inventory · Orders · Profile · Settings · Badges.
- **Order pipeline:** incoming order cards with accept ETA (existing flow,
  restyled).
- **Empty pipeline state (fills the space, not just a badge):** when there
  are no orders, a full-width card with an icon, "Hakuna oda bado / No orders
  yet", a one-line explanation, and a CTA — "Ensure your products are
  published so customers can find you" → Inventory. The pending badge stays
  in the header as before.
- **Low-stock nudge** list (top-level products out of stock).
- **B2B ad slot** (vendor audience only).
- **Tip card** when the dashboard has no data yet ("Add your first product…").

### Vendor Settings / Profile / Badges / Order screens

- Same card language, section headers, and type scale. No flows removed.

---

## 4. Ad framework (self-serve, audience-aware)

- `AdSlot(placementId)` widget backed by `ad_placements/{id}` in Firestore:
  `{title, subtitle, imageUrl?, linkUrl?, ctaText?, active, updatedAt,
  audience}` where `audience` is `consumer | vendor | both`.
- **Audience targeting:** each slot only renders placements matching the
  active role — consumer slots show retail offers; vendor slots show only
  B2B campaigns (suppliers, super-dealers, cylinder brands). Vendors never
  see consumer retail ads.
- **Placeholder state:** a slim branded banner reading **"Advertise Here"**
  with the support contact — the pitch asset for corporates.
- **Placements:** consumer home (below quick actions), every 4th vendor card
  in search/browse lists, order-success footer, and one B2B slot on the
  vendor dashboard. Admin surfaces have no ads.
- Rules: no popups/interstitials, always dismissible per session, opens
  `linkUrl` externally.

### Ad requests from gas stakeholders

- New **`AdvertiseScreen`** ("Tangaza na GasLink / Advertise with us"):
  pitch section (audiences, placements, sample metrics) + request form
  (company, contact phone, audience, placement preference, message/budget
  range). Submissions write to `ad_requests` in Firestore.
- Entry points: landing page footer link, consumer home footer, vendor
  settings.
- New admin **Ad requests** screen: list submissions, mark reviewed /
  contacted. Admin converts an approved request into an `ad_placements`
  record with the right `audience`.

---

## 5. Verification

| Check | Target |
|---|---|
| Bug A | Vendor inventory and consumer catalogue show the same items |
| Bug B | Service count equals ticked boxes; weighing consent counted separately |
| Bug C | Guests can browse but never order/track; registered consumers get full features |
| Ads | Slots respect `audience`; vendors never see consumer retail ads; ad requests write to `ad_requests` |
| Analyzer | 0 errors, 0 warnings |
| Tests | Full suite green + new tests for normalization, session gate, ad slot, landing |
| Visual | Light/dark and compact/wide smoke tests for new screens |

---

## Rollback

- Baseline: **`ffc0dca`**. Each step lands as its own commit so any slice can
  be reverted independently (`git revert <commit>`).
