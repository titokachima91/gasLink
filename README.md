# GasLink

> **Gesi mkononi — uthibitisho kabla ya ununuzi.**
> LPG marketplace and operations platform for Dar es Salaam, Tanzania.

GasLink connects consumers with verified LPG vendors, shows live prices and
stock, tracks orders end to end, and keeps a FIFO cylinder ledger so a household
knows how much gas is actually left. Vendors get an operations dashboard. The
pilot also includes SMS/AI gateway foundations, referrals, ads and an employee
GasPlan teaser.

---

## Start here (new model / new engineer)

Read in this order:

1. **[`PROJECT_BIBLE.md`](PROJECT_BIBLE.md)** — authoritative technical, product,
   data, operations, limitations and onboarding guide. **This is the master.**
2. **[`HANDOFF.md`](HANDOFF.md)** — current machine state, incident log,
   non-negotiable build rules and the immediate roadmap.
3. **[`WHITEPAPER.md`](WHITEPAPER.md)** — partner/marketing narrative, pilot
   thesis, business model, risks and potential improvements.
4. **[`BUILD.md`](BUILD.md)** — exact release build command, toolchain pins and
   troubleshooting on this Mac.

`PROGRESS.md`, `ROADMAP.md`, `guide.md` and `phases/*` are historical records.
When they disagree with `PROJECT_BIBLE.md`, the Bible wins.

---

## Current status (14 Nov 2026)

- Branch: `harden-source-of-truth`
- Latest source commit: `885f828` — four vendor categories + split vendor-card
  actions
- Phase 1–5D complete
- Phase 5E: D1 (localization infrastructure) and D2 (consumer localization)
  complete; **D3 vendor localization and D4 remaining surfaces are still open**
- Phase 5F SMS/AI gateway foundation implemented; outbound SMS and real inbound
  phone round trip tested
- DeepSeek AI Phases A–D complete in source: live Firestore catalogue, corrected
  brand colours, 13kg rule, delivery/scale terms from vendor profiles,
  profile onboarding, Safety Hub, 90-day memory, keyword opt-in and SMS
  ordering (customer confirmation + vendor YES/NO), 46/46 evaluation. Release
  build pending.
- OTP service/screen exist behind `ENABLE_OTP_LOGIN=false`; wiring is a later
  workstream
- Phase 6 (Blaze, rules, custom-token auth, production notifications) is parked

Always check `HANDOFF.md` for the latest build/APK verification before handing
anything to a user.

---

## What is in the app

### Consumer
- Landing, login/register, guest browsing
- Home: orders tracker, cylinders, gas estimator, referral card, four service
  categories, progressive stock list (+10), nearby vendors
- Brand → vendor list → shop storefront
- Shop storefront with Refill, Full Set, Vifaa and Huduma tabs
- Express checkout, order tracking, delivery confirmation, review/refill
  reminder
- Smart cylinder hub with FIFO gauges and per-unit facts
- Profile, settings, notifications/AI preferences, language, theme, About,
  Terms, Privacy, support
- GasPlan teaser, referrals, ad slots

### Vendor
- Dashboard with KPIs, incoming orders, accept/reject, ETA/driver dispatch,
  delivered-pending flow
- Order manager, inventory, brand/price editor, product visibility
- Profile, verification badge, commission terms, settings, referrals
- Shop photo upload

### Admin
- Responsive admin shell, operations dashboard
- Vendor lifecycle/KYC review, verification
- Orders oversight, consumer lookup
- Inventory visibility, analytics/CSV, ad requests, audit log, settings

### Platform
- Firebase Firestore/Auth/Storage/FCM
- Python FCM ledger dispatcher
- Self-hosted Node SMS/AI gateway
- Firebase ↔ gateway bridge (subscriber, catalog, orders)
- DeepSeek OpenAI-compatible AI SMS foundation

---

## Quick start

### Flutter app

```bash
cd /Users/apple/gaslink_app
flutter pub get
flutter run
```

### Release APK

```bash
cd /Users/apple/gaslink_app
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home \
JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true" \
flutter build apk --release --dart-define-from-file=env.local.json
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Non-negotiable:** one build at a time, laptop on AC power, verify the APK
before handing it over. See `HANDOFF.md`.

### Local servers

```bash
# Gateway + SMS/OTP/bridge (port 8080)
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node server.js

# APK download server (port 8090)
cd /Users/apple/gaslink_app/build/app/outputs/flutter-apk
python3 -m http.server 8090 --bind 0.0.0.0

# FCM ledger dispatcher (one instance only)
cd /Users/apple/gaslink_app
python3 -u server.py
```

Dashboard: `http://<LAN-IP>:8080/dashboard` (not `/`).
Current pilot IP is documented in `HANDOFF.md`; it is DHCP and can change.

---

## Verification

```bash
flutter analyze
flutter test
```

Last full suite before the latest UI changes: **116/116 passing**.
`flutter analyze`: **0 errors / 0 warnings** after the latest source changes.
Gateway Node tests: **4/4 passing**.
UI changes after that suite must be re-tested before a release claim.

---

## Repository map

| Path | Purpose |
|---|---|
| `lib/screens/auth/` | landing, login, register, OTP placeholder |
| `lib/screens/consumer/` | consumer home, shop, order, cylinder, profile, settings |
| `lib/screens/vendor/` | vendor dashboard, orders, inventory, profile, settings |
| `lib/screens/admin/` | admin console |
| `lib/services/` | auth, orders, catalog, notifications, SMS, OTP, admin, analytics |
| `lib/core/` | constants, theme, locale, session, gateway config, FIFO-adjacent state |
| `lib/utils/cylinder_fifo.dart` | shared FIFO depletion model |
| `lib/l10n/` | Swahili/English ARB files and error mapping |
| `gateway/` | Firebase bridge module, standalone runner, Node tests, docs; `AI_PIPELINE.md` explains live AI context and TextBee polling |
| `functions/` | legacy Cloud Functions source; not deployed on Spark |
| `phases/` | historical phase plans and implementation records |
| `test/` | Flutter test suite |

---

## Known limitations (summary)

- Vendor-side localization (D3) and remaining surfaces (D4) are incomplete.
- Firestore rules are still open; the pilot is not safe for untrusted public use.
- Firebase project is on Spark; Cloud Functions cannot be deployed.
- APK is debug-signed; production keystore is pending.
- The APK embeds the LAN gateway URL, so a DHCP IP change requires a rebuild.
- AI live-catalogue answers and a real phone-to-TextBee SMS round trip are verified. TextBee webhooks need public HTTPS, so the gateway polls TextBee locally.
- SMS ordering is **pilot-only**: implemented behind `SMS_ORDERING_ENABLED`, with customer confirmation, live price/stock re-check, idempotency and vendor YES/NO acceptance. The app remains the primary ordering path.
- Vendor FCM token can be stale/web; consumer Android push was verified.
- Current Sao Gas catalogue is refill-only; Full Set/Vifaa/Huduma tabs will be
  empty until products are seeded.

Full details, data model and runbooks: **[`PROJECT_BIBLE.md`](PROJECT_BIBLE.md)**.
