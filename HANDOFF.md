# GasLink — AI Handoff & Operating Rules

> **Read this before changing code, restarting servers, or starting a build.**
> Last updated: **14 Nov 2026**
> Branch: `harden-source-of-truth`
>
> Master docs: **[`PROJECT_BIBLE.md`](PROJECT_BIBLE.md)** (authoritative) and
> **[`WHITEPAPER.md`](WHITEPAPER.md)** (partner/marketing).
> Reading order: Bible → this file → white paper → `BUILD.md`.

---

## Why this file exists

On 13 Nov 2026 the pitch demo failed. The laptop ran out of battery during a
release build. The gateway, APK server, FCM dispatcher and build all died at
once. The consumer shop then looked empty, and there was no time to recover.

This file records the user's priorities, the machine constraints, and the
non-negotiable build/server checklist so the next model does not repeat it.

---

## The user's position (do not drift from this)

The pitch punchline is, in this order:

1. **A consumer can place an order.**
2. **A notification fires.**
3. **The cylinder in the kitchen updates.**
4. **The consumer can monitor the order.**

SMS and AI are secondary. DeepSeek is **not** integrated. Do not promise the
inbound AI assistant. The outbound SMS gateway works independently and may be
shown if it is already working.

Rules:

- Do **not** add unasked UX, prefill fields, or " improvements" while a build is
  pending. The user explicitly does not want feature creep during a pitch.
- Do **not** change business logic: FIFO cylinders, order lifecycle, auth /
  session logic, commission math, or the Firestore schema.
- Preserve the paid pilot constraints: Flutter 3.24.5, AGP 8.3.2,
  Gradle 8.10.2, Kotlin 1.9.22, JDK 17. Do not upgrade anything.
- If something is broken, fix the smallest thing that restores the demo.
- Do not claim success until the APK timestamp, embedded URL and SHA are
  verified and the servers answer.

---

## Machine and build constraints

- macOS Monterey, Mac cannot be upgraded.
- JDK: `/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home`
- Flutter: 3.24.5
- One warm release build: roughly **10–25 minutes**.
- A cold release build can take **60–80 minutes** (R8 register allocation).
- **The laptop must be on AC power before any release build.** Check:
  `pmset -g batt` and confirm `AC Power`.
- Never run two Flutter release builds at once. Two builds competing for
  Gradle caused a 25+ minute stall and a stale APK on 13 Nov.
- Before building, check:
  `pgrep -af "flutter_tools.snapshot build apk"`
  and `ps aux | grep "[G]radleDaemon"`.
- If a previous build was killed, stop Gradle first:
  `cd android && ./gradlew --stop`
  then force-stop any remaining `GradleDaemon` before starting one build.

### Build command

```bash
cd /Users/apple/gaslink_app
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home \
JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true" \
flutter build apk --release --dart-define-from-file=env.local.json
```

### Before every build: the LAN IP changes

DHCP has already moved the Mac between `192.168.1.11` and `192.168.1.104`.
The APK embeds the gateway URL, so the IP must be checked **before every
build**:

```bash
ipconfig getifaddr en0
```

Then update:

- `env.local.json` → `SMS_GATEWAY_BASE_URL`
- `android/app/src/main/res/xml/network_security_config.xml` → add the host
- Rebuild the APK

A DHCP reservation for the Mac, or an HTTPS tunnel, is the permanent fix.

### After the build: verify before handing over

```bash
cd build/app/outputs/flutter-apk
stat -f "%Sm %z bytes" app-release.apk
shasum -a 256 app-release.apk
strings app-release.apk | grep -o "192\.168\.[0-9]*\.[0-9]*:8080" | sort -u
curl -sI http://<LAN-IP>:8090/gaslink-latest.apk
```

The APK timestamp must be **after** the build start, the embedded URL must be
the current host, and `Content-Length` must match the file size. Only then send
the link and SHA.

---

## Running servers

| Service | Port | How |
|---|---|---|
| Gateway + bridge + OTP + SMS | **8080** | `cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox && node server.js` |
| APK download | **8090** | `cd /Users/apple/gaslink_app/build/app/outputs/flutter-apk && python3 -m http.server 8090 --bind 0.0.0.0` |
| FCM dispatcher | — | `cd /Users/apple/gaslink_app && python3 -u server.py` (exactly **one** instance) |

- Old gateway on `3000` is intentionally stopped.
- Gateway health: `http://<LAN-IP>:8080/health`
- Bridge health: `http://<LAN-IP>:8080/v1/bridge/health` with `x-api-key`.
- FCM dispatcher must be a single process; duplicates send duplicate pushes.
- The APK server and gateway must bind `0.0.0.0` so the phone on the Wi-Fi can
  reach them.

---

## Gateway mount (outside this repo)

Live gateway folder:

```
/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
```

Changes made there:

- `firebase-bridge.js` copied into the gateway root and mounted at
  `/v1/bridge`.
- `npm install firebase-admin`.
- `.env`: `PORT=8080`,
  `GASLINK_SUBSCRIBER_CHECK_URL=http://127.0.0.1:8080/v1/bridge/subscriber`,
  `FIREBASE_SERVICE_ACCOUNT_PATH=/Users/apple/gaslink_app/serviceAccountKey.json`.
- Compatibility shims because the updated gateway files use underscores while
  the requires use hyphens:
  - `routes/v1-otp.js` → `routes/v1_otp.js`
  - `services/otp-service.js` → `services/otp_service.js`
  - `services/ai-config-store.js` → `services/ai_config_store.js`
  - `services/sms-store.js` → `services/sms_store.js`

If the gateway is re-copied from an update, reapply the mount and shims.
Reference: `gateway/MOUNTED.md`.

---

## Current state at 14 Nov 2026

- **Power:** AC connected.
- **LAN IP:** `192.168.1.24` (new Wi-Fi; DHCP).
- **Source HEAD:** `885f828` — four vendor categories + split vendor-card
  actions.
- **Servers:** gateway `8080` is running (dashboard 200) with the AI live
  catalogue wiring and the TextBee inbound poller; APK download server `8090`
  is running; FCM dispatcher is **on** (one instance). Gateway log:
  `/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/gateway.log`.
- **Build:** four-category build **verified**.
- **Latest verified APK:** 14 Nov 09:58, SHA
  `7b2c28fa073afda704730bfd352436ef6ed6f3c42b34c908fa6ea8b0210b658f`
  (59,310,032 bytes), embeds `192.168.1.11:8080`; includes four categories,
  split vendor-card gestures, flat ListTile storefront, and no `SHOP v4` marker.
  Download: `http://192.168.1.11:8090/gaslink-latest.apk`.
- **Latest commits:** `885f828` four categories + gestures, `525e137` remove
  bottom bar/marker and refine gestures, `03fa3d0` flat ListTile storefront,
  `5c221e7` restore pre-restyle storefront, `506bbf9` full-width cards.
- **Shop details:** flat `ListView` of full-width `Card + ListTile` product
  rows; four tabs (Refill, Full Set, Vifaa, Huduma); bottom Order Now bar and
  `SHOP v4` marker removed.
- **Vendor card gestures:** shop header → storefront; `Oda Sasa` → checkout;
  empty card background → no action.
- **AI Phase A applied:** `services/app-context.js` fetches
  `/v1/bridge/catalog` on every message; the sample catalogue and sandbox
  ledger/transactions are gone. The dashboard persona was rewritten. The bridge
  now returns a `vendors` array with delivery, scale, payment and hours terms.
- **AI evaluation:** **46/46** cases pass (live prices, brand colours, 13kg,
  full-set/complete, fullness/weight, delivery, vendor-number policy, support,
  order-status refusal, safety, NO_REPLY, language and household size words).
  Results: `data/ai-eval-latest.json`; runner: `scripts/eval-ai.js`.
- **Brand colours corrected:** Oryx Red, Manjis Grey, Mihan/O-Gas Yellow,
  Taifa Green, Lake Blue. Mihan is the former name of Taifa. **13kg is not
  offered in Tanzania.** Household shorthand: ndogo = 6kg, kubwa = 15kg;
  restaurants/hotels ask for the exact size.
- **AI inbound:** `/v1/inbound-sms` verified through the real pipeline, and a
  real SMS reply was delivered to `+255716546732`. TextBee webhooks need public
  HTTPS, so `services/textbee-inbound-poller.js` polls TextBee locally every
  10s, forwards only AI-enabled subscribers, and skips personal SMS silently.
  Cursor: `data/textbee-inbound-cursor.json`.
- **AI physical round trip verified:** real SMS from `+255745123046` was polled
  from TextBee and answered through DeepSeek. The assistant quoted live prices,
  refused SMS ordering, and directed the customer to the app.
- **SMS ordering:** **enabled for pilot** (`SMS_ORDERING_ENABLED=true`).
  `services/sms-order-service.js` handles intent → name/address → YES →
  live re-check → `POST /v1/bridge/orders`; vendors reply `YES`/`NO` by SMS.
  Mock end-to-end test passed against Firestore and cleaned up after itself.
- **Phase B/C/D source:** profile setup screen, Safety Hub, 90-day memory,
  keyword opt-in, order status, vendor response, SMS-only subscriber creation.
  Release build pending.
- **Working tree:** docs added (`PROJECT_BIBLE.md`, `WHITEPAPER.md`, README and
  this update). Gateway changes are outside this repo. Check `git status`
  before building.
- **Install:** uninstall the old GasLink app first, then install the verified
  APK. Stale installs have repeatedly shown the old layout.

### Known issues / non-blockers

- Vendor-side localization (D3) and remaining surfaces (D4) are open.
- The vendor FCM token can be stale/web and logs
  `Permission denied by the third party webpush service`. Consumer Android push
  was verified; do not chase web push during a mobile demo.
- DeepSeek/AI live-catalogue answers, brand colours and the physical phone
  round trip are verified (46/46). SMS ordering is pilot-only and needs a real
  phone order test. TextBee webhooks cannot reach a LAN gateway, so do not
  delete the poller unless a public HTTPS tunnel is added.
- OTP is feature-flagged off; app user/session linking is not wired.
- Firebase rules are still open (no `firestore.rules`); do not enable
  auth-required rules before Phase 6A.
- The APK is debug-signed. A real keystore is still pending.
- Live Sao Gas catalogue currently has refill products only; Full Set, Vifaa
  and Huduma tabs show empty states until products are seeded.

### Next plan

1. Verify the four-category build and shop UI on a device.
2. Finish Flutter tests, update docs, commit.
3. Build and verify the release APK on `192.168.1.24`.
4. Real-phone SMS order + vendor acceptance check.
5. D3 vendor localization, then D4 remaining surfaces.
6. Wire OTP login.
7. Phase 6 security/scale after Blaze.

---

## Demo runbook (when the new APK is installed)

1. Log in as a **consumer**.
2. Home → pull to refresh → **Refill** → Oryx Gas.
3. Sao Gas Supply appears; tap **Oda Sasa**.
4. Enter address; phone is prefilled.
5. Tap **Thibitisha Oda**. Tracking opens immediately.
6. Vendor accepts and starts delivery (`on_the_way`) or marks
   `delivered_pending`.
7. Consumer taps **Nimepokea** / **Nimepokea Gesi Tayari**.
8. The order becomes `delivered`; `OrderService.handleOrderCompletion`
   registers the cylinder.
9. Back to Home → pull to refresh → the kitchen cylinder/gauge updates.

Consumer push was verified end-to-end with a real Android token. SMS outbound
was verified with the TextBee gateway. Inbound AI is not part of this demo.

---

## Do not

- Do not start two builds.
- Do not build on battery.
- Do not hand over an APK without checking its timestamp, embedded IP and SHA.
- Do not change the order lifecycle, FIFO, auth, or schema for demo convenience.
- Do not promise the AI SMS assistant.
- Do not add "nice to have" UI while a build or pitch is pending.
