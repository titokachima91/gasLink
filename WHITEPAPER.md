# GasLink — White Paper

> **Gesi mkononi — uthibitisho kabla ya ununuzi.**
> A verified LPG marketplace and household gas-operations layer for Dar es
> Salaam, Tanzania.

**Version:** Pilot / partner edition · 14 Nov 2026
**Status:** Working pilot application, four-category storefront, live vendor
catalogue, order tracking, SMS gateway and AI SMS foundation.
**Audience:** Potential partners, LPG brands, vendors, employers, investors,
pilot sponsors.

> **Honesty note:** This is a pilot-stage white paper. Market sizes, conversion
> rates and unit economics are hypotheses to validate in the Dar es Salaam
> pilot, not audited claims. Technical limitations are listed in the appendix.

---

## 1. Executive summary

LPG is becoming the practical clean-cooking fuel for urban Tanzanian
households, but the buying experience is still fragmented and opaque:

- Consumers do not know which nearby vendor is open, verified, or has stock.
- Prices are discovered by calling around or walking to shops.
- Delivery promises are informal; there is no shared order status.
- Households cannot easily tell how much gas is left across multiple cylinders.
- Vendors run orders on WhatsApp and notebooks, with no reliable stock or
  commission ledger.
- Trust is a constant issue: cylinder weight, seal integrity, and vendor
  legitimacy.

GasLink turns that into one mobile experience: verified vendors, live prices and
stock, a four-category catalogue (refill, full set, accessories, services),
end-to-end order tracking, a FIFO household cylinder ledger, and a notification
layer that works over app push and SMS.

The pilot’s critical loop is deliberately simple:

> **A consumer can order → a notification fires → the kitchen cylinder updates →
> the consumer can monitor the order.**

GasLink is not trying to replace LPG brands or vendors. It is the trusted
demand, ordering and operations layer that helps them sell more, deliver
better, and retain households.

---

## 2. The problem

### 2.1 For households

- **Discovery:** Which shop nearby is actually open and has the brand/size?
- **Price transparency:** The same cylinder can vary significantly by vendor.
- **Trust:** Is the shop verified? Is the cylinder weight correct? Is the seal
  intact?
- **Delivery uncertainty:** Did the vendor see the order? Is the rider coming?
- **Cylinder blindness:** How many days of cooking gas remain? When should I
  reorder?
- **Friction:** Ordering via calls/WhatsApp means repeating address and phone
  details and chasing confirmation.

### 2.2 For vendors

- Demand arrives through fragmented calls, DMs and walk-ins.
- Stock/prices are not visible to nearby households.
- Order status is manual; dispatch and proof-of-delivery are informal.
- Commission and sales reporting are not centralized.
- Customer retention depends on memory, not a system.
- Small shops cannot afford custom software or a delivery platform.

### 2.3 For brands and partners

- Little visibility into independent vendor stock, pricing and service quality.
- No direct, verified digital channel to households.
- Safety and compliance messaging is difficult to distribute consistently.
- Employer/bulk programmes are hard to administer without a household/employee
  ledger.

---

## 3. The solution

GasLink combines four layers:

### 3.1 Consumer marketplace

- Verified vendor discovery by brand, size and area.
- Live catalogue with prices and stock.
- Four categories: **Refill**, **Full Set**, **Accessories/Vifaa**, and
  **Services/Huduma**.
- Shop storefront with vendor profile, opening hours, delivery terms and
  service badges.
- Express checkout, order tracking, delivery confirmation and reviews.

### 3.2 Household gas operations

- Cylinder Smart Hub: multiple cylinders, brands and sizes per household.
- Shared **FIFO depletion model**: oldest cylinder is consumed first.
- Collective gauge shows both the sum of remaining percentages and the true
  capacity fraction.
- Delivery automatically registers/updates the cylinder after confirmation.
- Reorder reminders and order history.

### 3.3 Vendor operations

- Incoming order queue with accept/reject, ETA and driver dispatch.
- Inventory and price control per brand/size.
- Four product categories, including accessories and services.
- Commission terms (percentage or subscription), verification badge, shop photo,
  profile and referrals.
- Dashboard KPIs and delivery statistics.

### 3.4 Communications and AI

- In-app push notifications and SMS mirroring, with per-user channel choice.
- Order-created and status-change notifications.
- Self-hosted SMS gateway with tenant API keys.
- **AI SMS assistant foundation**:
  - Customers can ask natural-language questions such as
    “Gesi nyekundu shilingi ngapi?”
  - Brand-colour mapping: Oryx = red, Manjis/Mihan = yellow, Taifa = blue,
    Lake = green.
  - Live catalogue/price/stock context.
  - Subscriber gate so only registered, AI-opted-in customers reach the model.
  - SMS-length, language-aware replies.
- OTP capability foundation for future phone verification.

---

## 4. Product walkthrough

### Consumer

1. Open the app; browse as guest or sign in with phone + PIN.
2. Choose a category: Refill, Full Set, Accessories, Services.
3. Pick a brand (e.g. Oryx Gas) and see nearby vendors with live prices.
4. Tap the shop header to inspect the storefront, or **Oda Sasa** to order.
5. Enter delivery details, confirm, and track the order live.
6. Vendor accepts, dispatches and marks delivered.
7. Consumer confirms receipt; the cylinder ledger updates.
8. Consumer sees the kitchen gauge and can reorder/rate.

### Vendor

1. See incoming orders and accept/reject.
2. Set ETA; dispatch rider; update to delivered-pending.
3. Manage inventory, prices and categories.
4. Track commission and delivery performance.
5. Invite other vendors through referrals.

### Admin

1. Review vendor KYC and verify badges.
2. Oversee orders and consumers.
3. Inspect inventory and analytics.
4. Review ad requests and audit actions.

---

## 5. Why this matters now

The Dar es Salaam pilot is designed around a real, recurring household need:
cooking gas is not a one-off purchase; it is a repeat utility. That creates
natural retention, predictable demand and multiple monetization surfaces.

The market thesis to validate:

- Urban households increasingly prefer LPG for speed and cleanliness.
- Smartphone penetration and mobile money make digital ordering viable.
- Independent vendors need demand and operations tooling, not another brand.
- SMS remains a reliable fallback where data is intermittent or customers are
  not app-native.
- Employers and bulk buyers want predictable staff/customer gas programmes.

**Pilot assumptions to test (not claims):**

| Assumption | How we will test it |
|---|---|
| Households will order gas digitally if prices/stock are visible | Order conversion from shop views |
| Verified vendor badges influence choice | Click/order share of verified vendors |
| SMS improves completion for offline users | SMS vs push completion rates |
| FIFO gauge drives reorder timing | Reorder rate and days-between-orders |
| Vendors will maintain live stock/prices | Catalogue freshness and stock-out rate |
| AI SMS can answer price/stock questions safely | Simulator/inbound accuracy and escalation rate |

---

## 6. Technology and trust

### Architecture

- Flutter mobile app (Android-first; iOS/web code paths exist).
- Firebase Firestore for users, vendors, products, orders, cylinders,
  notifications, reviews, referrals, ads and audit.
- Firebase Storage for vendor shop photos.
- Firebase Cloud Messaging for push; local notification ledger dispatcher.
- Self-hosted Node gateway for SMS, OTP, AI and the Firebase Admin bridge.
- DeepSeek OpenAI-compatible model behind the gateway.

### Trust features in the pilot

- Verified vendor badge and KYC fields (business licence, WMA sticker,
  super-dealer proof).
- Consumer-protection agreement and weighing-on-request flag.
- Admin audit trail for vendor lifecycle/verification actions.
- Order status trail and delivery confirmation.
- PIN lockout after failed attempts.
- Subscriber gate and `NO_REPLY` relevance gate for AI SMS.

### What is intentionally not claimed yet

- No live rider GPS tracking.
- No automated payment capture in the app (cash/mobile-money labels only).
- No production-grade Firestore rules or custom-token auth.
- AI is a foundation; it is not yet a fully tested production assistant.

---

## 7. Business model

The pilot tests several complementary revenue lines.

### 7.1 Vendor commission

- Default **3% per order** (configurable per vendor).
- Snapshot onto each order; admin-controlled.
- Alternative: monthly **subscription** for vendors who prefer no per-order cut.

### 7.2 Verified vendor / visibility products

- Verified badge and profile enhancements.
- Sponsored placements and ad slots (already scaffolded as `ad_placements` and
  `ad_requests`).
- Category/area promotion for vendors.

### 7.3 GasPlan for employers

- Employer-paid monthly gas benefit administered through GasLink.
- Potential per-employee administration fee or brand sponsorship.
- Teaser and interest capture are live; billing is later.

### 7.4 Brand partnerships

- Verified brand presence, colour mapping in AI, co-marketing.
- Demand and stock insight for LPG brands.
- Safety/regulator campaigns through the app and SMS.

### 7.5 Future

- Delivery/routing fees, cylinder financing, insurance, carbon/safety
  certification, loyalty/rewards, data products (privacy-permitting).

### Unit-economics hypotheses

Use the pilot to validate:

- Average order value and gross margin per category.
- Commission revenue per active household.
- CAC by channel (vendor referral, consumer referral, SMS, employer).
- Repeat frequency and payback period.
- Delivery cost per order and rider utilization.
- SMS/API cost per order vs push.

Do not publish unit economics until the pilot produces real numbers.

---

## 8. Go-to-market

### 8.1 Beachhead

Dar es Salaam, starting with a small set of verified vendors in dense wards
(Ubungo, Kinondoni, Ilala). Depth before breadth: one area with reliable supply
and fast delivery is more valuable than a thin city-wide map.

### 8.2 Vendor acquisition

- Direct onboarding of established shops with WMA/licence proof.
- Verified badge, free storefront and simple order queue as the hook.
- Referral programme: existing vendors invite other vendors.
- Admin-assisted onboarding and KYC.

### 8.3 Consumer acquisition

- Vendor shop QR/flyers and “order on GasLink” signage.
- Referral codes from existing consumers and vendors.
- SMS/AI follow-up for price/stock questions.
- Employer/estate/community pilots.
- Local social media and WhatsApp groups.

### 8.4 Partnerships

- LPG brands and super-dealers for supply/price support.
- Employers for GasPlan.
- SACCOs, estate managers, restaurants and food vendors for bulk demand.
- Safety/clean-cooking NGOs and regulators for trust campaigns.

### 8.5 Positioning

> **GasLink is the verified way to order cooking gas nearby — see the price,
> see the stock, track the delivery, and know how much gas is left at home.**

Pillars:

1. **Verified** — real shops, KYC, badges.
2. **Transparent** — live price and stock.
3. **Trackable** — order status from placement to delivery.
4. **Household-aware** — FIFO cylinder gauge and reorder timing.
5. **Reachable** — app push + SMS + AI SMS foundation.

---

## 9. Pilot plan and KPIs

### Pilot scope

- One city, a handful of verified vendors, a few dense wards.
- Four categories live where vendors have stock.
- Cash/mobile-money labels; payment integration later.
- Manual rider dispatch/ETA; no GPS in the pilot.
- Consumer push tested; SMS outbound tested; AI testing next.

### KPIs

**Demand**

- Shop views → orders conversion
- Orders per active household
- Repeat/reorder rate
- Days between orders
- Category mix (refill/full set/accessories/services)

**Supply**

- Verified/active vendors
- Catalogue freshness (price/stock age)
- Stock-out rate
- Accept/reject rate and response time
- Delivery time vs ETA

**Retention/trust**

- 30/60/90-day household retention
- Review rating and complaint rate
- Cylinder registration rate after delivery
- Referral conversion

**Communications/AI**

- Push vs SMS completion
- AI simulator accuracy on price/stock questions
- Subscriber-gate allow/deny correctness
- SMS response rate, opt-out rate, cost per order

### Demo KPIs (pitch)

1. Order placed successfully.
2. Consumer notification arrives.
3. Vendor sees/accepts.
4. Cylinder appears in the kitchen after confirmation.
5. Consumer can monitor the order.

---

## 10. Competition and differentiation

| Alternative | Limitation | GasLink angle |
|---|---|---|
| Call/WhatsApp the shop | No price/stock visibility, no shared status | Live catalogue + tracked order |
| Walk to the shop | Time, stock uncertainty | Delivery + verified nearby supply |
| Brand hotline | Limited to one brand; little local vendor choice | Multi-brand, multi-vendor marketplace |
| Informal delivery apps | No LPG-specific cylinder/FIFO/safety model | Household gas ledger + KYC + four categories |
| Generic e-commerce | No vendor operations, no SMS/AI, no gas semantics | Purpose-built LPG operations layer |

The defensible asset is the **household cylinder/order history + verified vendor
network + communications layer**, not just the storefront UI.

---

## 11. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Vendor stock/price goes stale | Freshness prompts, admin visibility, vendor KPIs |
| Fake or unsafe cylinders | KYC, verified badge, WMA/licence proof, weighing-on-request |
| Delivery failure | Vendor accept/reject, ETA, status trail, support |
| Open Firestore / custom auth | Phase 6 rules + custom-token identity bridge before public launch |
| AI hallucinates prices/stock | Subscriber gate, live context, `NO_REPLY`, strict catalogue prompt, human escalation |
| SMS/API cost | Per-user channel preference, subscriber gate, 160-char cap, caching |
| Payment fraud | Start with cash/mobile-money labels; integrate verified providers later |
| Connectivity | SMS fallback, offline banners, cached reads |
| DHCP/build fragility | One-build rule, AC power, IP check, APK verification |
| Vendor FCM token issues | Log in vendor app to refresh; SMS fallback |
| Regulatory/privacy | Minimize PII, add rules/retention, legal review before public |

---

## 12. Roadmap

### Now

- Verify four-category storefront/order UX.
- Test DeepSeek AI pipeline and subscriber gate.
- Complete vendor-side localization (D3) and remaining surfaces (D4).

### Next

- OTP login wiring (feature flag, phone-to-user/session linking).
- Phase 6: Blaze, custom-token identity, Firestore/Storage rules, admin
  functions, audit, pagination, analytics rollups.
- Payment integration (M-Pesa/Tigo/Airtel/Halopesa) and reconciliation.
- Rider location and delivery proof.

### Later

- Multi-city expansion.
- GasPlan employer billing.
- Rewards/referral payouts.
- Cylinder QR/IoT scale, safety certification.
- Carbon/sustainability reporting.
- Partner APIs and brand dashboards.
- More languages and accessibility.

---

## 13. Impact and sustainability

- **Clean cooking:** Easier access to LPG supports a shift away from charcoal
  and wood fuels.
- **Safety:** Verification, seal/weight checks and clear vendor accountability.
- **Transparency:** Visible prices and stock reduce guesswork and overcharging.
- **Household resilience:** FIFO gauge and reorder reminders reduce run-outs.
- **Vendor growth:** Digital demand and simple operations for small shops.
- **Financial inclusion:** Mobile-money-first flows, SMS fallback.
- **Carbon:** Future carbon-credit/sustainability reporting if measurable and
  verified.

---

## 14. Partner ask

GasLink is looking for pilot partners who can help prove the loop:

- **LPG brands/super-dealers:** supply, price support, safety content.
- **Verified vendors:** live stock/prices and order response.
- **Employers:** GasPlan pilot with staff.
- **Estate/community managers:** household onboarding.
- **Payment providers:** mobile-money integration pilots.
- **Clean-cooking/safety organisations:** verification and awareness.
- **Investors/grants:** pilot operations, localization, security hardening and
  payment integration.

### What partners get

- Verified digital storefront and demand.
- Operational visibility (orders, stock, delivery).
- Household retention and reorder data (privacy-permitting).
- Brand-safe AI/SMS engagement.
- A measurable pilot with clear KPIs.

---

## 15. Marketing messaging

### One-liner

**GasLink — verified cooking gas nearby, delivered and tracked.**

### Swahili tagline

**Gesi mkononi — uthibitisho kabla ya ununuzi.**

### Pitch punchlines

- “See the price and stock before you order.”
- “Track the gas from the shop to your kitchen.”
- “Know how much gas is left — across every cylinder.”
- “One order, one notification, one updated kitchen.”
- “If you can send an SMS, you can check the price of gas.”

### Elevator pitch

GasLink is a verified LPG marketplace for Dar es Salaam. Households compare
live vendor prices, order refills, full sets, accessories or services, track
delivery, and see how much gas remains through a FIFO cylinder gauge. Vendors
get an order queue, inventory and commission dashboard. The platform adds SMS
and an AI assistant foundation so customers can ask “Gesi nyekundu shilingi
ngapi?” and get a live, brand-aware answer.

---

## 16. Appendix — current technical readiness

| Area | Status |
|---|---|
| Consumer app | Working pilot; four-category storefront in latest source |
| Vendor app | Working pilot |
| Admin console | Working pilot |
| Firebase | Firestore/FCM/Storage live; **rules open**; Spark plan |
| Orders | Live; Firestore + tracking |
| FIFO cylinders | Implemented and tested |
| Consumer push | Verified with Android token |
| SMS outbound | Verified via TextBee |
| AI SMS | Live-catalogue Q&A, real phone round trip and SMS ordering pilot verified in gateway tests; app remains primary ordering path |
| OTP | Foundation/feature-flagged; app wiring pending |
| Localization | D1/D2 complete; D3/D4 open |
| Payments | Not integrated |
| Release signing | Debug key |
| Security | Phase 6 parked pending Blaze |

### Known limitations

- No Firestore rules; no Firebase Auth identity; hardcoded admin.
- APK embeds a LAN gateway URL; DHCP IP changes require rebuild.
- Vendor FCM token may be stale/web; consumer Android push works.
- Live Sao Gas catalogue is refill-only; other category tabs may be empty until
  vendors seed products.
- No rider GPS, automated payments, or production monitoring.

---

## 17. Closing

GasLink is not a slide-deck marketplace. The pilot app already has the hard
parts: a live vendor catalogue, four-category ordering, vendor operations,
order tracking, a FIFO household cylinder ledger, notification preferences, an
SMS gateway, and an AI/subscriber-gate foundation.

The next milestones are execution, not invention:

1. Prove the order → notification → kitchen → monitor loop on real devices.
2. Run the real-phone SMS ordering pilot and verify vendor acceptance end to end.
3. Finish localization.
4. Wire OTP.
5. Harden identity, rules and release operations in Phase 6.

The opportunity is to become the trusted household gas layer for urban
Tanzania — starting with one city, one verified vendor network, and one
reliable order loop.
