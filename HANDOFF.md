# GasLink — AI Handoff & Operating Rules

> **Read this before changing code, restarting servers, or starting a build.**
> Last updated: **13 Nov 2026, 22:35 EAT**
> Branch: `harden-source-of-truth`

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

## Current state at 01:17 EAT, 14 Nov 2026

- **Power:** AC connected.
- **LAN IP:** `192.168.1.11`.
- **Servers:** APK download server on `8090` is running for UI inspection.
  Gateway `8080` and FCM are intentionally **off**; UI browsing still reads
  Firestore, but SMS/push will not fire until they are started.
- **Last successful APK:** 14 Nov 07:20, SHA
  `5ece834fa77068b926733160d4ac30547c7a84548bd8f7b5026044c418ff890c`
  (59,310,155 bytes), embeds `192.168.1.11:8080`.
  Download: `http://192.168.1.11:8090/gaslink-latest.apk`
- **Build:** incremental after the earlier clean build. Log:
  `build_logs/shop_width_build.log`.
- **Last commits:** `506bbf9` force full-width shop/cylinder cards,
  `7295ff0` brand-header constraint, `8122297` product/vendor card text sweep,
  `c4ae9eb` shop fallback.
- **Root cause of the Shop Details bug:** the product AppCards were nested in
  a Column with the default `center` cross-axis, so each card shrink-wrapped
  to a narrow intrinsic width. The top card was a direct ListView child and
  looked fine. `_buildCylindersSection` now uses
  `CrossAxisAlignment.stretch` and each product card is `width: double.infinity`.
  The 01:16 APK predates this specific fix; the 07:20 APK includes it.
- **Working tree:** clean.
- **Install:** uninstall the old GasLink app first, then install the new APK.
  The previous 00:41 download had a connection reset; a stale install is the
  likely reason the old mangled layout kept appearing.
- **Shop fix:** Shop Details product rows are full-width vertical rows
  (name/weight, price, full-width `Oda Sasa`). Brand headers are constrained.
  The same sweep covered vendor cards, brand shop, order summary, cylinder
  facts, vendor search, inventory, and vendor order cards.

### Known issues / non-blockers

- The vendor FCM token is stale/web and logs
  `Permission denied by the third party webpush service`. Consumer Android
  tokens were tested and received pushes successfully. Do not chase the vendor
  web push during the pitch.
- DeepSeek/AI is not configured. Do not demo inbound AI.
- Firebase rules are still open (no `firestore.rules`). Client writes were
  tested and work. Do not change rules during the pitch.
- The APK is debug-signed. A real keystore is still pending.

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
