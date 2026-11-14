# GasLink — Project Bible

> **Authoritative source of truth** for engineering, product, data, operations,
> demo and handoff.
> Last updated: **14 Nov 2026** · Branch: `harden-source-of-truth`
> Latest source commit: **`885f828`** (four vendor categories + split vendor-card
> actions).
>
> If another document disagrees with this file, **this file wins**.
> Historical phase records remain in `phases/`; `PROGRESS.md` and `ROADMAP.md`
> are historical snapshots.

---

## 0. Read this first

This project has one job for the pilot:

> **A consumer can order LPG from a verified vendor, a notification fires, the
> kitchen cylinder updates, and the consumer can monitor the order.**

Everything else supports that loop.

### Reading order for a new model/engineer

1. `PROJECT_BIBLE.md` (this file)
2. `HANDOFF.md` — machine state, one-build rules, incident log, immediate plan
3. `WHITEPAPER.md` — product/market/marketing/partner narrative
4. `BUILD.md` — exact toolchain and release procedure
5. `phases/phase-05e-ux-refinements/plan.md` and
   `phases/phase-05f-sms-ai-gateway/plan.md` — localization and SMS/AI scope
6. `phases/phase-06-scale-security/plan.md` — parked security work

### What to do in the first 10 minutes

- `git status`, `git log --oneline -5`
- Read `HANDOFF.md` current-state section
- Check the build/server ports in this file
- Do **not** start a release build until the handoff checklist is met
- Do **not** change Firestore rules, auth, FIFO, or the order lifecycle

---

## 1. What GasLink is

GasLink is a mobile-first LPG (cooking gas) marketplace and operations platform
for Dar es Salaam, Tanzania.

- Consumers discover verified vendors, compare live prices/stock, order gas or
  accessories/services, track delivery, and manage household cylinders.
- Vendors receive orders, manage inventory/prices, dispatch riders, and track
  commissions.
- Admins manage vendor KYC/lifecycle, orders, consumers, inventory, analytics,
  ads and audit.
- A separate self-hosted Node gateway adds SMS notifications, OTP capability,
  an AI SMS assistant foundation, and a secure Firebase bridge.

Tagline: **“Gesi mkononi — uthibitisho kabla ya ununuzi.”**
(“Gas on hand — verification before purchase.”)

---

## 2. Users, roles and jobs

| Role | How they enter | Primary jobs |
|---|---|---|
| Guest | “Continue as guest” on landing | Browse only; ordering/tracking redirects to auth |
| Consumer | Phone + 4-digit PIN registration/login | Order, track, confirm delivery, manage cylinders, referrals, settings |
| Vendor | Admin provisions vendor profile and promotes user role | Accept/reject orders, dispatch, update stock/prices, profile/commission |
| Admin | Hardcoded pilot credentials (see §8) | Vendor KYC, orders, consumers, inventory, analytics, ads, audit |

Pilot test accounts (debug seeding in `main.dart`):

- Vendor: `+255777000777` / `1234`
- Consumer: `+255777000778` / `1234`
- Admin: `+255767304776` / `0000` (hardcoded, `admin_local`)

Never ship the hardcoded admin credentials to production. Phase 6 replaces them.

---

## 3. Status snapshot

| Area | Status |
|---|---|
| Phases 1–5D | Complete |
| Phase 5E D1: localization infrastructure | Complete |
| Phase 5E D2: consumer localization | Complete |
| Phase 5E D3: vendor localization | **Open** |
| Phase 5E D4: admin/remaining localization | **Open** |
| Phase 5F: SMS/AI/OTP/bridge foundation | Implemented; live SMS + consumer FCM tested |
| DeepSeek AI testing | **Verified** — live catalogue, real phone-to-TextBee round trip, 43/43 evaluation; SMS ordering intentionally not wired |
| OTP app wiring | Foundation only; `ENABLE_OTP_LOGIN=false` |
| Phase 6: scale/security | **Parked** (Firebase Spark) |
| Release signing | Debug key only |
| Firestore rules | **None/open** — pilot only |

Latest verified APK:

- Four-category build, 14 Nov 09:58, SHA
  `7b2c28fa073afda704730bfd352436ef6ed6f3c42b34c908fa6ea8b0210b658f`
  (59,310,032 bytes), embeds `192.168.1.11:8080`.
- Includes four categories, split vendor-card gestures, flat `Card + ListTile`
  storefront, and the diagnostic marker removed.
- Always re-verify timestamp, embedded IP, SHA and download before handoff.

Verification status:

- Last full `flutter test` before the latest UI changes: **116/116 passing**.
- `flutter analyze` after latest source changes: **0 errors / 0 warnings**.
- Gateway Node tests: **4/4 passing**.
- Re-run the full suite before any release claim after UI changes.

---

## 4. System architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Flutter app (Android/iOS/web)                               │
│  Auth/session · Consumer · Vendor · Admin                   │
│  Theme/locale · Notifications · Maps/ads/referrals          │
└───────────────┬───────────────────────────────┬─────────────┘
                │ Firestore/Auth/Storage/FCM    │ HTTPS (SMS/OTP/AI/bridge)
                ▼                               ▼
┌──────────────────────────────┐   ┌───────────────────────────────┐
│ Firebase project             │   │ Self-hosted Node gateway      │
│ gaslink-app-4bfbb (Spark)    │◄──┤ port 8080                     │
│ users/vendors/products/      │   │ /v1/send-sms /v1/otp/*        │
│ orders/cylinders/notifs/...  │   │ /v1/inbound-sms (AI pipeline) │
└───────────────┬──────────────┘   │ /v1/bridge/* (Admin SDK)      │
                │                  └───────────────┬───────────────┘
                │ FCM                              │ TextBee SMS
                ▼                                  ▼
┌──────────────────────────────┐   ┌───────────────────────────────┐
│ Python FCM ledger dispatcher │   │ Android SMS device / TextBee  │
│ `server.py` (local)          │   │ outbound + inbound SMS        │
└──────────────────────────────┘   └───────────────────────────────┘
```

Key points:

- The Flutter app uses a **custom Firestore phone+PIN session**, not Firebase
  Auth. This is why Firestore rules cannot use `request.auth` yet.
- The Python dispatcher listens to the `notifications` collection and sends FCM.
- The Node gateway is self-hosted; the bridge uses the Firebase Admin SDK and
  bypasses Firestore rules.
- DeepSeek is called only by the Node gateway, never by the app.

---

## 5. Fixed toolchain and build constraints

| Item | Value |
|---|---|
| Flutter | 3.24.5 |
| Dart SDK | ^3.5.4 |
| JDK | 17 (`/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home`) |
| AGP | 8.3.2 |
| Gradle | 8.10.2 |
| Kotlin | 1.9.22 |
| compileSdk | 35 |
| minSdk | 23 |
| Firebase BoM | 33.8.0 |
| FlutterFire | core 3.11.0, auth 5.4.2, firestore 5.6.3, messaging 15.2.2, storage 12.4.2 |
| share_plus | 10.1.4 |
| connectivity_plus | 6.1.2 |
| intl | 0.19.0 |

**Do not upgrade** Flutter/AGP/Gradle/Kotlin or the FlutterFire/share_plus pins
without checking the toolchain compatibility notes in `BUILD.md`. macOS
Monterey cannot be upgraded on this Mac.

Warm release build: roughly **10–25 minutes**.
Cold build after `flutter clean`: historically **60–80 minutes**; a recent clean
build took ~22 minutes, so measure, don’t assume.
R8 register allocation is the long pole.

### Release build command

```bash
cd /Users/apple/gaslink_app
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home \
JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true" \
flutter build apk --release --dart-define-from-file=env.local.json
```

`-Djava.net.preferIPv4Stack=true` fixes the mDNS build hang.
Do **not** use `jdk.net.hosts.file`.

### One-build rule (learned the hard way)

- Laptop on **AC power** (`pmset -g batt`).
- Exactly **one** Flutter release build at a time.
- Before building:
  ```bash
  pgrep -af "flutter_tools.snapshot build apk"
  ps aux | grep "[G]radleDaemon"
  ```
- If a previous build was killed or stuck:
  ```bash
  cd android && ./gradlew --stop
  ```
  then force-stop remaining `GradleDaemon` processes.
- Never start a second build while one runs; it creates stale APKs and 25-minute
  stalls.
- Use `caffeinate -dimsu` or `nohup` for long builds; keep the charger connected.
- Verify the APK **before** handing it over:
  ```bash
  stat -f "%Sm %z bytes" build/app/outputs/flutter-apk/app-release.apk
  shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
  strings build/app/outputs/flutter-apk/app-release.apk | grep -o "192.168.[0-9]*.[0-9]*:8080"
  curl -sI http://<LAN-IP>:8090/gaslink-latest.apk
  ```
  The timestamp must be after the build started; Content-Length must match.

---

## 6. Local services, ports and configuration

### Ports

| Service | Port | Start command |
|---|---|---|
| Node gateway + SMS/OTP/AI/bridge | **8080** | `cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox && node server.js` |
| APK download server | **8090** | `cd /Users/apple/gaslink_app/build/app/outputs/flutter-apk && python3 -m http.server 8090 --bind 0.0.0.0` |
| Python FCM dispatcher | no HTTP | `cd /Users/apple/gaslink_app && python3 -u server.py` (exactly one instance) |
| Old gateway | 3000 | **Stopped intentionally** |

Dashboard: `http://<LAN-IP>:8080/dashboard` (the root `/` returns 404 by design).

### LAN IP is DHCP

The Mac has been on `.11` and `.104`. The APK embeds the gateway URL, so always:

```bash
ipconfig getifaddr en0
```

Then update `env.local.json` and the Android network security config if needed,
and rebuild. A DHCP reservation or HTTPS tunnel is the permanent fix.

At the time of writing: `192.168.1.11`.

### App configuration

`lib/core/gateway_config.dart`:

- `SMS_GATEWAY_BASE_URL` (dart-define)
- `SMS_GATEWAY_API_KEY` (dart-define, `x-api-key`)
- `ENABLE_OTP_LOGIN` (default false)
- 15s HTTP timeout

`env.local.json` (gitignored) supplies the pilot values:

```json
{
  "SMS_GATEWAY_BASE_URL": "http://192.168.1.11:8080",
  "SMS_GATEWAY_API_KEY": "gl-...",
  "ENABLE_OTP_LOGIN": "false"
}
```

`env.local.example.json` is the tracked template. Never commit the real key.

### Gateway `.env` (outside this repo)

Path: `/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/.env`

| Key | Purpose |
|---|---|
| `PORT` | `8080` |
| `API_KEY_GASLINK` | `/v1` tenant key (`gl-alsk...`); SMS/OTP/bridge |
| `SANDBOX_API_KEY_GASLINK` | Dashboard admin key (`gl-sand...`) |
| `TEXTBEE_DEVICE_ID` / `TEXTBEE_API_KEY` | Android SMS device |
| `GASLINK_SUBSCRIBER_CHECK_URL` | `http://127.0.0.1:8080/v1/bridge/subscriber` |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `/Users/apple/gaslink_app/serviceAccountKey.json` |
| `GEMINI_API_KEY_*` | legacy Gemini fallback; DeepSeek is dashboard-configured |

Bridge mount and compatibility shims: see `gateway/MOUNTED.md`.
If the gateway is re-copied from an update, reapply the mount and shims.

### Secrets that must never be committed

- `env.local.json`
- `serviceAccountKey.json`
- gateway `.env`
- any DeepSeek `sk-...` key
- any tenant/sandbox key

`serviceAccountKey.json` is gitignored. The Firebase project is
`gaslink-app-4bfbb`.

---

## 7. Firebase backend

Project: **`gaslink-app-4bfbb`** · Firestore (default) · Firebase Storage · FCM.
Plan: **Spark** (no deployed Cloud Functions).

### Critical security posture

- There is **no `firestore.rules` file** and no `firestore` block in
  `firebase.json`.
- The current database is effectively open to anyone with the project ID.
- The app has **no Firebase Auth session**; it uses custom Firestore phone+PIN.
- Do **not** deploy auth-required rules before Phase 6A; it will break every
  read/write.
- The pilot is only appropriate for trusted testers on a private network.

### Collections

| Collection | Purpose / key fields |
|---|---|
| `users/{uid}` | `phone`, `role`, `name`, `passcodeHash`, `pinAttempts`, `lockedUntil`, `mustChangePin`, `termsAcceptedAt`, `adsConsent`, `notification_channel`, `ai_assistant_enabled`, `fcmToken`, `createdAt`, `updatedAt` |
| `users/{uid}/cylinders/{id}` | `brand`, `weight`/`size`, `refillCycle`, `lastRefillDate`, `purchase_date`, `supplier_name`, `price`, `createdAt`; FIFO is derived from delivered orders/units |
| `vendors/{uid}` | `businessName`, phone/email, area fields, coordinates, radius, fee model, opening hours, payment flags, `stockedBrandNames`, `offeredServices`, KYC URLs, `verified`, `status`, commission fields, rating, completed orders, delivery minutes |
| `products/{id}` | `vendor_id`, `brand`, `size`/`weight`, `price`, `in_stock`, `category` (`refill`, `full_set`, `accessories`, `services`) |
| `vendors/{uid}/products/{id}` | legacy inventory; `CatalogService` merges it with top-level `products` |
| `orders/{id}` | See §8; dual snake_case/camelCase keys for compatibility |
| `notifications/{id}` | `userId`, `fcmToken`, `title`, `body`, `data`, `read`, `createdAt`, `status`, `sentAt` |
| `reviews/{id}` | `order_id`, `vendor_id`, `vendor_name`, `brand_name`, `rating`, `tags`, `custom_comment`, `enable_reminder`, `reminder_interval`, `created_at` |
| `referrals/{id}` | Referrer/referred user, code, status; rewards intentionally “coming soon” |
| `ad_requests/{id}` | Stakeholder ad request; admin review |
| `ad_placements/{id}` | Approved ad campaign for `AdSlot` placements |
| `admin_audit_logs/{id}` | Admin actions, actor, target, timestamp, reason |
| `app_settings/{id}` | Admin settings |
| `ajira_interest/{id}` | GasPlan employer-interest submissions |

### Order schema (canonical)

The app writes **dual keys** to survive legacy readers:

```text
consumer_uid / consumerUid
vendor_id / vendorId
product_id / productId
brand / brand_name / brandName
size / weight / cylinder_weight
unit_price / unitPrice
total / total_price / totalPrice
order_intent / orderIntent
delivery_address / deliveryAddress
contact_phone / consumerPhone
receiver_phone / receiverPhone
special_requests
payment_method
status
commission_rate / commissionRate
commission_due / commissionDue
commission_model / commissionModel
billed
created_at / createdAt
delivered_at
cancelled_at
cancellation_reason
vendorViewed / vendor_viewed
```

### Canonical values

Brands (selected, never free-typed): `Oryx Gas`, `Taifa Gas`, `O-Lake Gas`,
`O-Gas`, `Puma Gas`, `Manjis Gas`, `Camel Gas`.

Sizes are per brand (`AppConstants.brandSizes`): e.g. Taifa 3/6/15/38kg,
Manjis 6/15/40kg.

Order statuses: `placed`, `seen`, `confirmed`, `on_the_way`,
`delivered_pending`, `delivered`, `cancelled`.
UI also accepts legacy aliases: `pending`, `accepted`, `preparing`,
`dispatched`, `in_transit`, `completed`, `rejected`, `refused`.

Product types: `refill`, `full_set`, `accessories`, `services`.
Order intents: `new_asset`, `add_stock`, `swap`.
Payment: `cash`, `mobile_money`.

Notification channels: `push_only`, `sms_only`, `both`, `none` (default both).
AI opt-in: `ai_assistant_enabled` boolean (default false).

### Auth/session details

- `AuthService` stores `currentRole`, `currentPhone`, `currentUserId` in memory.
- Session persists via `AdminPinService` (SharedPreferences); restored at startup.
- Roles: `consumer`, `vendor`, `admin`; `guest` is a browse-only state.
- PIN hash: `sha256("<pin>:<phone>")`; 5 failed attempts lock for 15 minutes.
- Registration writes user doc plus `termsAcceptedAt`, `adsConsent`,
  `notification_channel: both`, `ai_assistant_enabled: false`.
- Login normalizes phone variants and migrates legacy phone/hash on success.
- FCM token is saved on login/register and deleted on sign-out.
- There is no Firebase Auth user; Phase 6A adds a custom-token bridge.

### Storage

- Vendor shop photos via Firebase Storage path `vendor_images/{vendorId}`.
- `storage.rules` exists; anonymous upload path ownership is **not** enforced
  yet (Phase 6C).

---

## 8. Business logic

### Order lifecycle

```text
placed → seen → confirmed → on_the_way → delivered_pending → delivered
                                                      ↘ cancelled
```

- Consumer places order; vendor sees it; vendor accepts/ETA; rider dispatched;
  vendor marks delivered-pending; consumer confirms receipt; cylinder registers.
- Consumer can confirm from `on_the_way`/`in_transit` (“Nimepokea Gesi Tayari”)
  or from `delivered_pending` (“Nimepokea”).
- Vendor can reject/cancel early. Consumer can cancel before acceptance.
- ETA is manual (`eta_minutes`), not GPS-tracked.

### Four categories

- `refill`: gas content only; cylinder registration on delivery.
- `full_set`: cylinder + gas; cylinder registration on delivery.
- `accessories`: physical items; **no cylinder registration**.
- `services`: installation/maintenance/leak test; **no cylinder registration**.

`OrderService.handleOrderCompletion` guards registration to `refill` and
`full_set` only. Do not remove that guard.

### Commission

- Default percentage: **3%** (`AppConstants.defaultCommissionRate`).
- Admin can set a vendor to `percentage` or `subscription`.
- Subscription vendors pay no per-order cut; order still stamps the model.
- Commission is snapshotted onto each order at creation.

### FIFO cylinders

`lib/utils/cylinder_fifo.dart` is the single source:

- Deliveries are consumed oldest first.
- One cylinder is depleted before the next begins.
- Each unit has its own cycle (default 30 days).
- `totalPercentage` is the sum of per-unit percentages (two full = 200%).
- `capacityFraction` is total remaining days / total capacity for progress bars.
- Home card and Smart Hub must use the same helper.

Do not change these semantics for UI convenience.

### Referrals

- `ReferralService` ensures a deterministic code, stores `referrals`, and lets
  consumers invite vendors.
- Rewards are explicitly “coming soon”; no balances/payouts.

### Ads / GasPlan

- `AdSlot` reads approved `ad_placements`; `AdvertiseScreen` writes
  `ad_requests`; admin reviews.
- GasPlan teaser writes `ajira_interest`; no billing or enrollment.

---

## 9. App architecture and flows

### Startup

1. `main.dart` initializes Firebase, FCM, notification service.
2. Restores session, theme and locale.
3. Mounts `ProviderScope` with initial theme/locale overrides.
4. `GasLinkApp` builds `MaterialApp` with delegates, supported locales
   (`sw`, `en`), theme and `RoleRouter`.

### Routing

`RoleRouter` chooses admin/vendor/consumer/landing from the restored role.
`SessionGate`:

- `isConsumer` for ordering/tracking/account.
- Guests see a sign-in sheet; registration/login returns to the app.
- `SessionRedirect` is a defensive redirect for stale guest sessions.

### Consumer flow (pilot)

Landing → login/register (or guest) → Home:

- Orders tracker banner
- My cylinders overview
- Gas estimator
- Referral card
- Four service categories (Refill, Full Set, Accessories, Services)
- Stock list (10 + “View more”)
- Nearby vendors
- Ad slot

Brand → vendor list (`ItemVendorsScreen`) → vendor card:

- **Shop header** (icon/name/location) → Shop Storefront
- **Oda Sasa** → checkout dialog
- Empty card background → no action

Shop Storefront (`VendorDetailScreen`):

- Vendor profile card (area, hours, ETA, delivery, services)
- Four category chips
- Full-width `Card + ListTile` product rows, live Firestore
- `Oda` per row → checkout

Checkout → `OrderService.placeOrder` → tracking screen (`ConsumerOrderScreen`):

- Live status stream, ETA, driver/office call
- Cancel / confirm receipt
- Persistent review card and review/refill reminder sheet

### Vendor flow

Dashboard → incoming orders → accept/ETA → driver/on-the-way →
delivered-pending → consumer confirm. Inventory, brand/price editor, profile,
verification, commission terms, settings, referrals.

### Admin flow

Admin shell → dashboard/KPIs → vendors/KYC/verification → orders → consumers →
inventory → analytics/CSV → ad requests → audit → settings.

---

## 10. Notifications, SMS, AI and OTP

### Notification preferences

`users/{uid}`:

- `notification_channel`: push_only, sms_only, both, none (default both)
- `ai_assistant_enabled`: bool (default false)

Shared UI: `lib/widgets/notifications_ai_settings.dart`, added to consumer and
vendor settings.

### Dispatcher

`NotificationDispatcher.dispatchToUser`:

- push channels → `NotificationService.sendNotificationToUser` (ledger + FCM)
- SMS channels → `SmsGatewayService.sendSms`
- none → nothing
- Failures never block order placement; order notifications are `unawaited`.

Order-created notifies vendor + consumer. Status changes notified once by the
dispatcher; the old Python order-status listener was removed to avoid duplicates.

### FCM

- App saves token under `users/{uid}.fcmToken`.
- `notifications` ledger docs are consumed by `server.py` (Firebase Admin SDK).
- Python dispatcher must run as a **single instance**.
- Consumer Android push was tested successfully.
- Vendor token can be stale/web and log
  `Permission denied by the third party webpush service`; refresh by logging in
  the vendor app. Do not chase web push during a mobile demo.
- No Cloud Functions are deployed on Spark; the local Python dispatcher is the
  sender.

### SMS gateway

- Base: `http://<LAN-IP>:8080`
- Auth: `x-api-key` tenant key (`API_KEY_GASLINK`, `gl-alsk...`)
- `POST /v1/send-sms` `{recipient, message}`
- `POST /v1/otp/send` `{phone}` → 201 `{ref, expiresAt}`; code is **not**
  returned
- `POST /v1/otp/verify` `{phone, ref, code}` → `{verified:true}`
- `POST /v1/inbound-sms` — AI pipeline + subscriber gate
- Real outbound SMS tested successfully via TextBee.

### DeepSeek / AI

Dashboard: `http://<LAN-IP>:8080/dashboard` → SMS & AI.

Exact values:

| Field | Value |
|---|---|
| Provider | DeepSeek |
| API Base URL | `https://api.deepseek.com` |
| Model | `deepseek-chat` |
| Temperature | `0.7` |
| Max Tokens | `200` |
| API Key | `sk-...` |

The gateway appends `/chat/completions`.
The dashboard’s top field is the **sandbox key** (`SANDBOX_API_KEY_GASLINK`,
`gl-sand...`); the OTP panel uses the **tenant key** (`API_KEY_GASLINK`,
`gl-alsk...`).

AI pipeline:

1. Inbound SMS logged.
2. Subscriber gate: `GASLINK_SUBSCRIBER_CHECK_URL` POSTs `{phone}` to the
   bridge; requires `ai_assistant_enabled: true`.
3. App context is rebuilt from the **live Firestore catalogue** through
   `GET /v1/bridge/catalog` on every message. `services/app-context.js` is
   async and no longer reads the sample `data/gaslink-catalog.json`.
4. DeepSeek call.
5. `NO_REPLY` gate; otherwise SMS reply.

If the bridge catalogue is unreachable, the context explicitly orders the
model **not** to quote any price, stock level or delivery fee; it must say it
will confirm instead. There is no sample-price fallback.

Physical round trip verified on 14 Nov 2026 from `+255745123046` through the
TextBee poller: price/stock, delivery-policy, cylinder-weight and “order by
SMS” questions all received real SMS replies. The assistant correctly refused
an SMS order and directed the customer to the app.

Verified against live Sao Gas data:

| Question | Reply behaviour |
|---|---|
| “How much is Oryx 6kg refill?” | **TZS 26,000**, in stock at Sao Gas Supply, Sinza |
| “Gesi nyekundu 6kg ni shilingi ngapi?” | Maps red → Oryx; **TZS 26,000** |
| “Oryx 13kg refill bei gani?” | Says 13kg is not offered in Tanzania; offers live 6kg/15kg |
| “Full set ya Oryx 6kg ni ngapi?” | Says no full set is listed; does not invent a price |
| “Delivery fee ni shilingi ngapi?” | Says fee depends on vendor/distance; does not quote 3,000 |
| “Habari yako?” | `NO_REPLY` gate; nothing sent |
| Unknown phone | Subscriber gate blocks before any DeepSeek call |

### TextBee inbound: polling vs webhook

TextBee’s webhook requires a **public HTTPS** URL. The gateway is on the LAN,
so it cannot receive TextBee’s cloud webhook directly. The gateway therefore
ships a local poller:

- `services/textbee-inbound-poller.js`
- Enabled with `TEXTBEE_POLL_ENABLED=true` (10s interval by default).
- It anchors a cursor at the newest existing SMS on first run, so old messages
  are never replayed.
- New received messages are checked against the subscriber gate. Only
  AI-enabled senders are forwarded to `/v1/inbound-sms`; personal SMS on the
  TextBee phone is skipped silently (no log, no AI credit, no reply).
- Cursor: `data/textbee-inbound-cursor.json`.

If a public HTTPS tunnel is added later, point TextBee’s `MESSAGE_RECEIVED`
webhook at `/v1/inbound-sms` and set `TEXTBEE_INBOUND_SECRET`. The route has a
200/ignored guard for `MESSAGE_SENT`, `MESSAGE_DELIVERED` and `MESSAGE_FAILED`
events so status callbacks can never trigger an AI reply.

**SMS ordering is not wired yet.** The bridge has `POST /v1/bridge/orders`, but
the assistant only answers questions. It is explicitly instructed never to
accept or confirm an SMS order; customers are told to order in the app. Do not
claim “order by SMS” until a confirm-then-create flow exists.

Full pipeline, environment and troubleshooting details:
**[`gateway/AI_PIPELINE.md`](gateway/AI_PIPELINE.md)**.

### Bridge

`gateway/firebase-bridge.js` (mounted at `/v1/bridge`):

| Endpoint | Purpose |
|---|---|
| `GET/POST /subscriber` | `{exists, registered, found, aiAssistantEnabled, aiEnabled, uid?, name?, channel}` |
| `GET /catalog` | live products, colours, prices, stock |
| `POST /orders` | create `placed` SMS order with idempotency |
| `GET /health` | liveness |

Brand colours (live bridge mapping, corrected 14 Nov 2026):

| Brand | Colour | Swahili alias |
|---|---|---|
| Oryx Gas | Red | nyekundu |
| Manjis Gas | Grey | kijivu |
| Mihan Gas | Yellow | njano |
| O-Gas | Yellow | njano |
| Taifa Gas | Green | kijani |
| O-Lake / Lake Gas | Blue | bluu |

Mihan Gas and Taifa Gas are the same company; Mihan is the former name, now
Taifa. **13kg is not offered in Tanzania** and must never be quoted or offered.

Household size words: **ndogo = 6kg**, **kubwa = 15kg**. For restaurants,
hotels, mgahawa, biashara or commercial use, the AI asks for the exact size
instead of assuming.

The bridge returns both `registered/found` and `aiEnabled` for the subscriber
gate. Orders mirror the Flutter dual-key schema and `source: sms_ai`.
The `/catalog` response also includes a `vendors` array with the profile terms
the AI uses for delivery, scale, payment, hours and comparison:
`deliveryType`, `deliveryFee`, `deliveryFeeModel`, `deliveryRadiusKm`,
`openingHours`, `hasOperationalScale`, `hasCertifiedScale`, `acceptsCash`,
`acceptsMobileMoney`, `verified`.

### OTP in the app

- `OtpAuthService` calls `/v1/otp/send` and `/v1/otp/verify`.
- `OtpVerificationScreen` is a placeholder, not routed.
- `ENABLE_OTP_LOGIN=false`; phone+PIN remains active.
- OTP verifies phone possession only; linking the verified phone to a GasLink
  user/session is not wired yet.

---

## 11. Localization

Architecture:

- `flutter_localizations`, `intl 0.19.0`, `generate: true`.
- ARB files: `lib/l10n/app_sw.arb` (template), `app_en.arb`.
- **411 message keys** (last count), key-identical.
- `AppLocale { system, sw, en }`, persisted in SharedPreferences under
  `app_locale`; system resolves to English if device language is `en`,
  otherwise Kiswahili.
- `AppLocalizations.of(context)` is non-null.
- Shared `LanguagePicker` on landing/login/register/consumer settings/vendor
  drawer/settings/admin settings.
- `loadLocalizedMessages()` resolves ARB outside the widget tree for SMS/push.

Completed:

- D1: infrastructure, auth/landing/legal/About/session gate/root back/theme.
- D2: consumer home, profile, settings, orders, cylinders, GasPlan, referrals.

Remaining:

- **D3 vendor**: vendor dashboard/order/inventory/product dialogs/brand editor/
  settings/drawer/commission/badge/profile; many hardcoded bilingual labels.
- **D4 admin + remaining consumer**: admin screens, browse/vendor search/detail
  leftovers, order history duplicate, etc.
- Expand `test/no_bilingual_strings_test.dart` as files migrate.
- Keep `l10n_parity_test.dart` green; remove unused keys.

String policy:

- Never concatenate two languages in one string.
- Canonical data values stay untranslated: statuses, categories, service
  intents, brands, field keys, collection names, persisted fallbacks.
- Add display maps (e.g. `orderStatusLabel(context, status)`) instead of
  translating stored values.
- Use `MaterialLocalizations.formatMediumDate` for dates in the current design
  to avoid intl locale-data initialization.
- New strings go to both ARBs and are used from code; no unused keys.

---

## 12. Testing and verification

Commands:

```bash
cd /Users/apple/gaslink_app
flutter analyze
flutter test
cd gateway && npm test
```

Coverage highlights:

- FIFO math (empty, multiple cylinders, partial depletion)
- Auth/admin/PIN lockout/session persistence
- Session gate and root back
- Referrals, catalog merge, service normalization, analytics
- Notifications routing, dispatcher preference matrix, SMS payloads, OTP gating
- ARB parity, no-bilingual scan, locale controller/picker
- Theme/landing/About/ads/GasPlan/vendor settings

Latest known:

- Full suite before latest UI changes: **116/116**.
- Analyze after latest changes: **0 errors / 0 warnings**.
- Gateway tests: **4/4**.
- Full suite must be re-run after UI changes and before a release claim.

Not covered / manual:

- No device integration/e2e automation (order → vendor → delivery → cylinder).
- No Firestore rules tests (rules don’t exist yet).
- AI live catalogue answers and a real phone-to-TextBee round trip are verified. SMS order creation is intentionally not wired; the assistant refuses it and points to the app.
- Shop layout has a history of zero-width card bugs; verify screenshots on a
  device before handing an APK over.
- Visual QA for light/dark and small screens is manual.

### APK handoff checklist

1. Source is committed and pushed; `git status` clean.
2. One build; AC power; no duplicate Gradle workers.
3. APK timestamp after build start; SHA computed.
4. Embedded gateway IP matches `ipconfig getifaddr en0`.
5. APK server returns HTTP 200 with matching Content-Length.
6. Tell the user the exact SHA and to uninstall the old app first.
7. Do not install/use an APK from an interrupted download.

---

## 13. Known issues and technical debt

### Open / important

- **Firestore rules missing** — open database; Phase 6 blocker.
- **No Firebase Auth identity** — custom session; rules cannot identify caller.
- **Hardcoded admin** — pilot only; remove in Phase 6.
- **Debug-signed APK** — real keystore pending.
- **D3/D4 localization incomplete** — vendor/admin bilingual labels remain.
- **Vendor FCM token** may be web/stale; consumer Android push verified.
- **AI physical round trip verified** — real inbound SMS from `+255745123046` was polled from TextBee and answered through DeepSeek.
- **SMS ordering not user-facing** — the bridge order endpoint exists, but the AI does not create orders. The app is the only live ordering path; the assistant refuses SMS order requests.
- **OTP not wired into app** — flag false; user/session linking missing.
- **DHCP IP** — APK embeds gateway URL; rebuild on change.
- **Spark plan** — no Cloud Functions; Python dispatcher/local bridge required.
- **Vendor catalogue top-level vs legacy** — `VendorDetailScreen` reads
  top-level `products` only; `CatalogService` merges legacy. Some legacy
  products may not appear in the storefront.
- **Full Set/Vifaa/Huduma tabs may be empty** — live Sao Gas catalogue currently
  has refill products only.
- **No payments** — cash/mobile money labels only; no provider integration.
- **No rider GPS** — ETA manual.
- **No pagination everywhere** — some admin/vendor lists use unbounded `get()`.
- **`consumer_home_screen.dart.bak`** is tracked; remove after confirming it is
  obsolete.
- **`ProductListTile` widget is unused**; candidate for cleanup or reuse.
- **Docs drift** — `PROGRESS.md`/`ROADMAP.md` are historical; this Bible is master.

### Resolved/lessons

- Shop Details vertical text had two separate causes: squeezed `Row` children
  and nested `Column` shrink-wrapping an `AppCard`. The current flat
  `ListView` of full-width `Card + ListTile` rows avoids both.
- The redundant bottom Order Now bar was removed; per-product `Oda` buttons are
  the single order entry point on the shop.
- The `SHOP v4` diagnostic marker was removed after use.
- The previous two-category UI was a misread; all four vendor categories are
  restored in the home chooser and shop tabs.

---

## 14. Security, privacy and risk

- Firestore is open; only trusted devices/networks for the pilot.
- Tenant API key (`gl-alsk...`) is embedded in the APK; it is extractable.
  Rotate before public release and rate-limit the gateway.
- Gateway is HTTP on the LAN; use HTTPS tunnel for anything outside Wi-Fi.
- Service account JSON is local/gitignored; never commit or share.
- DeepSeek key lives server-side in `data/ai-config.json`; dashboard returns
  only last 4 characters.
- AI is credit-sensitive: subscriber gate + `NO_REPLY` protect the SMS/API
  balance. Keep the gate default-deny.
- PII: phone numbers, delivery addresses, order history. Rules/retention are
  Phase 6.
- Admin credentials are hardcoded; do not expose the APK publicly.
- Customer PINs are SHA-256 `pin:phone`; not salted per-user beyond phone. Phase
  6 should strengthen this (bcrypt/scrypt/Argon2 + per-user salt).

---

## 15. Incident log and operating lessons

### 13 Nov 2026 — pitch build failure

- Laptop battery died during a release build. Gateway, APK server, FCM and build
  all died. The demo could not recover; shop looked empty.
- Root causes: battery, duplicate builds, no single-build guard, no handoff doc.
- Lessons recorded in `HANDOFF.md`:
  - AC power before build
  - one build at a time
  - `caffeinate`/`nohup`
  - verify APK before promising it
  - servers need independent restart scripts/docs
  - do not chase web-push vendor tokens during a mobile demo

### Shop Details regression

- The `5e2c6d2` restyle replaced the known-good weight-chip product card with
  multi-row cards that could squeeze.
- Several patches addressed text wrapping, but the real container width issue
  was a nested `Column` shrink-wrapping `AppCard`.
- Final approach: flat `ListView` + full-width `Card/ListTile`, plus a
  diagnostic marker to prove which APK was running.
- Keep the screenshot/verification culture: a marker or SHA is worth more than
  guesswork.

---

## 16. Roadmap and immediate next steps

### Immediate (after current UI build verification)

1. Verify the four-category build, shop layout, gestures and order flow.
2. **AI Phase A (done 14 Nov 2026)**: persona rewritten, sandbox ledger removed,
   vendor profile terms exposed, brand colours corrected, 13kg rule added,
   household size words added, 43/43 evaluation passing.
3. **AI Phase B**: onboarding data, order-status lookup, safety hub, app link.
4. **D3 vendor localization**
5. **D4 remaining localization**
6. **OTP wiring**
   - Enable flag, route screen, link verified phone to user/session.
7. **Phase 6**
   - Blaze, 6A custom-token identity bridge, 6B rules, 6C storage, 6D admin
     functions/audit, 6E pagination, 6F analytics rollups, 6G billing design.

### Later product improvements

- M-Pesa/Tigo/Airtel/Halopesa payments and reconciliation
- Rider live location + route optimization
- Vendor ratings/reviews moderation, demand forecasting
- SMS/WhatsApp/USSD channels, AI order confirmation and payment links
- Cylinder QR/barcode, IoT scale integration, leak-test scheduling
- Loyalty/rewards, referral payouts, GasPlan employer billing
- Multi-city expansion, localization beyond sw/en
- Carbon/safety reporting, partner dashboards, public API

---

## 17. Decisions and user positions (do not drift)

- **Order → notification → kitchen cylinder → monitoring** are the pitch
  priority, in that order.
- SMS/AI is secondary; do not promise inbound AI until tested.
- Do not add unasked UX, prefilled fields, or feature creep during a pitch.
- Do not change business logic, FIFO, auth/session, order lifecycle, or schema
  for demo convenience.
- Four vendor categories are required: Refill, Full Set, Accessories, Services.
- The shop header opens the storefront; only the order button orders; empty
  card background is inert.
- One build at a time; AC power; verify before handoff.
- Keep the fixed toolchain; no upgrades.
- Documentation is part of the deliverable.

---

## 18. Glossary

| Term | Meaning |
|---|---|
| FIFO | First-in-first-out cylinder depletion |
| Full Set | Cylinder + gas |
| Refill | Gas content only |
| Vifaa | Accessories (regulators, hoses, burners) |
| Huduma | Services (installation, leak test, maintenance) |
| GasPlan | Employer-paid monthly gas concept |
| Subscriber gate | AI authorization check by phone/AI opt-in |
| Bridge | Firebase Admin SDK endpoints inside the Node gateway |
| Tenant key | `/v1` `x-api-key`, `gl-alsk...` |
| Sandbox key | Dashboard admin key, `gl-sand...` |
| Ledger | `notifications` collection consumed by the Python FCM dispatcher |
| Adjacent | The Mac’s DHCP LAN IP; APK embeds it |

---

## 19. One-paragraph handoff

GasLink is a Flutter 3.24.5 LPG marketplace for Dar es Salaam with a custom
Firestore phone+PIN auth, a consumer ordering/tracking/FIFO-cylinder experience,
a vendor operations dashboard, and an admin console. It uses Firebase
Firestore/FCM/Storage on the Spark plan (no rules, no deployed functions), plus
a self-hosted Node gateway on port 8080 for SMS, OTP, DeepSeek AI and a Firebase
Admin bridge. The pilot’s critical loop is: verified vendor → live catalogue →
order → notification → delivery confirmation → cylinder update → monitoring.
Localization infrastructure is complete but D3/D4 are open; OTP is a
feature-flagged foundation; Phase 6 security/scale work is parked pending Blaze.
Build with JDK 17 and the exact pins, one build at a time, on AC power, and
verify the APK timestamp, embedded LAN IP, SHA and download before handing it
over. The authoritative docs are this Bible, `HANDOFF.md` and `WHITEPAPER.md`.
