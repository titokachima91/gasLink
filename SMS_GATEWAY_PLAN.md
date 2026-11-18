# GasLink SMS Gateway — Own TextBee Replacement (Build Plan)

**Status:** planned, not built. No code changed yet.
**Date:** 18 Nov 2026
**Repo:** `/Users/apple/gaslink_app`, branch `harden-source-of-truth`
**Gateway:** `/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox` (not a git repo)
**Read first:** `PROJECT_BIBLE.md`, `RUNBOOK.md`, `PHONE_NUMBERS.md`, this file.

---

## 1. Why

TextBee's free plan is exhausted: **293 received + 32 sent = 325** against
**300/month** (and 50/day). It resets **12 December 2026, 04:08 UTC**. The
owner will **not** upgrade to Pro. Most usage was inbound personal/carrier SMS
to the gateway SIM (M-PESA, SONGESHA, AzamPesa, BUSTISHA, etc.).

Decision: build our own TextBee-like gateway:

- Android app on the gateway phone sends/receives SMS over the SIM.
- Local queue in the existing Node gateway.
- No TextBee cloud, no Firebase, no per-message quota.
- Only carrier SMS cost.

Rejected: TextBee Pro, self-hosting the full TextBee stack (needs Docker,
MongoDB, Redis, Firebase, SMTP, public HTTPS domain), installing a third-party
gateway app (owner wants our own build).

## 2. Open decisions (ask the owner before coding)

1. **Where will the gateway phone live?**
   - Same Wi-Fi as the Mac → plain LAN HTTP.
   - Remote → add Tailscale (free, encrypted) on phone + Mac; use the
     Tailscale IP as the app's server URL. No code change, only the URL.
2. **App language:** English, Swahili, or both.

## 3. Architecture

```text
Customer ──SMS──▶ Gateway phone (our app) ──HTTP──▶ Mac gateway (Node)
                                                        │
                                                        ├─ subscriber gate
                                                        ├─ AI / SMS order flow
                                                        └─ outbound queue
Customer ◀──SMS── Gateway phone (our app) ◀──poll───────┘
```

- **Inbound:** SMS arrives → app posts to existing `/v1/inbound-sms` with a
  `messageId` and the local key. Existing gate/AI/order pipeline unchanged.
- **Outbound:** `sendSms()` with `SMS_PROVIDER=local` enqueues. App polls
  `GET /v1/local-sms/outbox` every ~3 s, sends via `SmsManager`, reports
  `sent`/`failed`.
- The phone initiates every connection; only the Mac must be reachable.
- Polling (not push) keeps it simple and avoids Firebase. Long-poll can come
  later if latency matters.

## 4. Backend changes (gateway dir)

| File | Change |
|---|---|
| `services/local-sms-bridge.js` (new) | Persistent outbound queue in `data/local-sms-queue.json`: `enqueue`, `claim(deviceId, limit)` with 120 s lease, `report(id, status, error)`, `stats`, prune completed >24 h. Atomic writes. |
| `routes/local-sms.js` (new) | `GET /v1/local-sms/outbox`, `POST /v1/local-sms/status`, `GET /v1/local-sms/health`. Auth `x-local-sms-key`. 503 if `LOCAL_SMS_API_KEY` unset; 401 if wrong. |
| `services/sms-gateway.js` | Provider switch: `SMS_PROVIDER=local` → enqueue, log `queued`, return `{ok:true, queued:true, id}`. TextBee path unchanged. Self-number guard stays first. |
| `routes/inbound-sms.js` | Accept `x-local-sms-key` in `inboundAuth`; dedup by `messageId` (bounded 10 min map) so retries cannot double-reply. TextBee path unchanged. |
| `routes/send-sms.js` | Use `sendSms()` instead of hardcoded TextBee, so the provider switch applies. Preserve auth + response shape. |
| `server.js` | Mount `/v1` local router; startup log provider; do not start TextBee poller when local. |
| `.env` | `SMS_PROVIDER=textbee` initially; add `LOCAL_SMS_API_KEY=<openssl rand -hex 16>`, `LOCAL_SMS_DEVICE_ID=gaslink-gateway-1`. Keep TextBee keys as fallback. |
| `test/local-sms-bridge.test.js` (new) | Enqueue/claim/report/lease/prune; endpoint auth; no real SMS. |

Rules:
- Do not change subscriber gate, AI behavior, SMS order flow, order lifecycle,
  Firestore schema, commission math, self-number rules, or opt-in pause.
- TextBee stays switchable: `SMS_PROVIDER=textbee`.

## 5. Android app (`sms-gateway-app/` in this repo)

- Kotlin, minimal UI. Mirror the fixed toolchain: **Gradle 8.10.2, AGP 8.3.2,
  Kotlin 1.9.22, JDK 17, compileSdk 35, minSdk 26, targetSdk 35.**
- **Main screen:** server URL, API key, device ID, poll interval, Start/Stop,
  live status (last poll, queued/sent/failed, last error), permission
  checklist, battery-optimization button.
- **`GatewayService`** (foreground): coroutine loop polls outbox, sends SMS
  (multipart), reports status, retries with backoff. `START_STICKY`.
- **`SmsReceiver`**: `SMS_RECEIVED` → persistent pending queue → POST to
  `/v1/inbound-sms` with `messageId`, retry until 2xx. Survives Wi-Fi loss.
- **`BootReceiver`**: start service after reboot if enabled.
- **Permissions:** `INTERNET`, `ACCESS_NETWORK_STATE`, `SEND_SMS`,
  `RECEIVE_SMS`, `READ_PHONE_STATE`, `POST_NOTIFICATIONS`,
  `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`,
  `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- Cleartext HTTP for LAN (or private-range network config). Note the risk.
- Do **not** make it the default SMS app; `SMS_RECEIVED` works without it.
- APK served at `http://192.168.1.13:8091/gaslink-sms-gateway.apk`
  (copy into `build/app/outputs/flutter-apk/`, which the 8091 server serves).
- Debug-signed for the pilot; release keystore still pending.

## 6. Security

- Dedicated `LOCAL_SMS_API_KEY`; never the tenant key, never embedded in the APK.
- Endpoints 503 if unset, 401 if wrong. No open local-send endpoint.
- App stores the key locally; user enters it once.
- LAN cleartext now; Tailscale (WireGuard) or HTTPS later if remote.
- Stop/uninstall TextBee on the gateway phone at cutover to avoid duplicate
  inbound and quota counting.
- Update `PRIVACY_DATA_INVENTORY.md`: SMS send/receive on the gateway phone,
  message content in `sms-log.json` + `local-sms-queue.json`, retention.

## 7. Cutover and rollback

1. Build backend + tests. Keep `SMS_PROVIDER=textbee`; live behavior unchanged.
2. Build APK; serve it.
3. Owner installs on gateway phone, grants permissions, enters URL/key/device
   ID, starts service, confirms health.
4. Cutover: stop/uninstall TextBee on the phone → set `SMS_PROVIDER=local`,
   `TEXTBEE_POLL_ENABLED=false` → restart gateway (launchd).
5. Owner tests: one inbound text from a registered number → inbound log → AI
   reply → SMS delivered. Check queue statuses.
6. Rollback: `SMS_PROVIDER=textbee`, re-enable poller (quota permitting),
   restart.

**Do not flip to local before the app is installed and running** — inbound
would stop (the app is the receiver) and outbound would queue silently.

## 8. Test plan

- Unit: enqueue → claim → report sent/failed; lease expiry requeues; prune;
  auth 401/503.
- Local curl: claim a fake message, report it, verify `sms-log.json` and queue.
- APK build: `./gradlew assembleDebug`; verify APK exists and is signed.
- Device: install, permissions, start, health; then owner sends real SMS.
- No test SMS from the agent; the owner runs all real tests.

## 9. First steps for the new session

1. Read this file + `PROJECT_BIBLE.md` + `PHONE_NUMBERS.md`.
2. Ask the owner the two open decisions (phone location, app language).
3. Implement backend with `SMS_PROVIDER=textbee`; run `npm test`.
4. Build the app; serve the APK.
5. Stop and hand back for install/cutover. Do not send SMS.

## 10. Key paths

- Gateway: `/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox`
- SMS send point: `services/sms-gateway.js`
- Inbound pipeline: `routes/inbound-sms.js`
- Queue store pattern: `services/sms_store.js`
- Toolchain reference: `android/gradle/wrapper/gradle-wrapper.properties`,
  `android/settings.gradle`
- Current LAN IP: `192.168.1.13` (DHCP; changes). Gateway 8080, APK 8091.
- TextBee quota: resets 12 Dec 2026, 04:08 UTC. Not to be upgraded.
