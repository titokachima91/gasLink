# GasLink Operations Runbook

**Last updated:** 17 Nov 2026
**Purpose:** start, stop, verify and test the complete GasLink stack from this Mac.
Everything runs on the Mac; phones only need to be on the same Wi-Fi.

> This file is the copy-paste companion to `PROJECT_BIBLE.md`. If a command here
> conflicts with the Bible, the Bible wins.

---

## 0. Paths and current values

| Item | Value |
|---|---|
| Flutter app | `/Users/apple/gaslink_app` |
| Node gateway | `/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox` |
| Gateway `.env` | `.../kachi-fintech-sandbox/.env` |
| App build config | `/Users/apple/gaslink_app/env.local.json` |
| Firebase service account | `/Users/apple/gaslink_app/serviceAccountKey.json` |
| Gateway port | `8080` |
| APK server port | `8090` |
| Firestore project | `gaslink-app-4bfbb` |
| Gateway phone / support | `0767304776` (`+255767304776`) |
| Operator phone | `0714604777` (`+255714604777`) |
| Vendor demo login | `+255777000777` / PIN `1234` |
| Vendor id (Sao Gas) | `HR7lVXzVHWPeR94ebRF5` |

**The Mac IP is DHCP and changes.** Always read it first:

```zsh
export MAC_IP="$(ipconfig getifaddr en0)"
echo "$MAC_IP"
```

Use `http://$MAC_IP:8080` and `http://$MAC_IP:8090` in every link below.
If the IP changed, rebuild the APK only if you need app-side SMS/OTP
(see §5). Normal app ordering uses Firestore and does not need the gateway URL.

---

## 1. Start everything

Run each block from a normal terminal. The gateway needs about 20–30 seconds
to warm up Firestore before port 8080 starts listening.

```zsh
# 1) Node gateway: AI, SMS ordering, TextBee poller, outbox, finalizer
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
nohup node server.js >> gateway.log 2>&1 &
echo "gateway pid $!"

# 2) Python FCM dispatcher (notifications -> phones)
cd /Users/apple/gaslink_app
nohup python3 -u server.py >> build_logs/fcm_dispatcher.log 2>&1 &
echo "fcm pid $!"

# 3) APK download server
cd /Users/apple/gaslink_app/build/app/outputs/flutter-apk
nohup python3 -m http.server 8090 --bind 0.0.0.0 \
  >> /Users/apple/gaslink_app/build_logs/apk_server.log 2>&1 &
echo "apk pid $!"
```

Wait, then verify:

```zsh
export MAC_IP="$(ipconfig getifaddr en0)"

curl -sS "http://127.0.0.1:8080/health"; echo
curl -sS "http://$MAC_IP:8080/health"; echo
curl -sI "http://$MAC_IP:8090/gaslink-latest.apk" | head -5
```

Expected:

- gateway: `{"status":"OK",...}`
- APK: `HTTP/1.0 200 OK` and `Content-Length: 59277472`

---

## 2. Stop / restart

```zsh
# Gateway (also stops TextBee poller, outbox worker and finalizer)
lsof -ti tcp:8080 | xargs kill

# FCM dispatcher
pkill -f "python3 -u server.py"

# APK server
lsof -ti tcp:8090 | xargs kill
```

Only run **one** FCM dispatcher and **one** gateway at a time.

Restart everything with §1.

---

## 3. What is running

| Process | Command | Port / output |
|---|---|---|
| Node gateway | `node server.js` | `8080` |
| TextBee inbound poller | inside gateway | every 10 s |
| Notification outbox worker | inside gateway | every 5 s |
| 10-minute order finalizer | inside gateway | every 30 s |
| FCM dispatcher | `python3 -u server.py` | Firestore listener |
| APK server | `python3 -m http.server 8090` | `8090` |

Check quickly:

```zsh
lsof -nP -iTCP:8080 -sTCP:LISTEN
lsof -nP -iTCP:8090 -sTCP:LISTEN
ps aux | grep -E "[n]ode server.js|[s]erver.py|[h]ttp.server 8090"
```

---

## 4. Phone links

```zsh
export MAC_IP="$(ipconfig getifaddr en0)"

echo "APK:       http://$MAC_IP:8090/gaslink-latest.apk"
echo "Files:     http://$MAC_IP:8090/"
echo "Dashboard: http://$MAC_IP:8080/dashboard"
echo "Health:    http://$MAC_IP:8080/health"
```

Phones must be on the same Wi-Fi. If the APK link fails:

1. Confirm the Mac and phone are on the same network.
2. Confirm the APK server is on `0.0.0.0:8090`.
3. Check macOS firewall / VPN.
4. Re-read `MAC_IP`; DHCP may have changed it.

The current APK was built against `192.168.1.24`. App orders, tracking and
vendor actions use Firestore, so they work even if the Mac IP is different.
Only app-side SMS/OTP calls use `SMS_GATEWAY_BASE_URL`; rebuild with §5 if you
need those from the app.

---

## 5. Build and serve a new APK

Only **one release build at a time**. Keep the laptop on AC power.

```zsh
cd /Users/apple/gaslink_app

# Point the build at the Mac's current IP
export MAC_IP="$(ipconfig getifaddr en0)"
python3 - <<'PY'
import json, os
p = 'env.local.json'
d = json.load(open(p))
d['SMS_GATEWAY_BASE_URL'] = f"http://{os.environ['MAC_IP']}:8080"
json.dump(d, open(p, 'w'), indent=2)
print(d)
PY

# Build
flutter build apk --release --dart-define-from-file=env.local.json \
  | tee "build_logs/release_$(date +%Y%m%d_%H%M).log"

# Verify
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
shasum -a 1  build/app/outputs/flutter-apk/app-release.apk \
  > build/app/outputs/flutter-apk/app-release.apk.sha1

# The APK server serves the same directory, so gaslink-latest.apk updates
# automatically through the symlink.
curl -sI "http://$(ipconfig getifaddr en0):8090/gaslink-latest.apk" \
  | grep -iE "HTTP/|Content-Length|Last-Modified"
```

The symlink is:

```text
build/app/outputs/flutter-apk/gaslink-latest.apk -> app-release.apk
```

---

## 6. AI messaging pipeline

### 6.1 Architecture in one line

`TextBee poller -> POST /v1/inbound-sms -> SMS-order state machine OR subscriber gate -> DeepSeek -> TextBee send`.

### 6.2 Send a test SMS from the gateway

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
set -a; source .env; set +a

node scripts/send-operator-sms.js "GasLink test message from the gateway"
```

Check the result:

```zsh
tail -3 data/sms-log.json
# or use the dashboard SMS & AI screen
```

### 6.3 Simulate an inbound SMS without a phone

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
set -a; source .env; set +a

curl -sS -X POST http://127.0.0.1:8080/v1/inbound-sms \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY_GASLINK" \
  -d '{"from":"+2557XXXXXXXX","message":"Nataka Oryx 6kg"}' | python3 -m json.tool
```

Replace `+2557XXXXXXXX` with a phone you control: the reply is sent by real SMS.
For a registered AI subscriber, the assistant replies normally. For an unknown
number, only order/business keywords are forwarded; personal SMS is ignored.

### 6.4 Real phone test

Text the gateway line **0767304776** from a phone that is not the gateway phone:

```text
Nataka Oryx 6kg
```

Then follow the prompts. Check the gateway log:

```zsh
tail -f /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/gateway.log
```

Look for:

```text
[textbee-poller] +2557...: AI replied
```

### 6.5 AI regression suite

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node scripts/eval-ai.js
python3 -m json.tool data/ai-eval-latest.json | head -40
```

### 6.6 Reset AI conversation memory

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
rm data/ai-sessions.json
```

The gateway caches sessions in memory; restart it after deleting the file if
you need an immediate reset.

---

## 7. SMS ordering pipeline

### 7.1 Customer flow

Text **0767304776**:

```text
Nataka Oryx 6kg
Jina langu <your name>
<your area / address>
YES
```

The bot confirms the live price/stock, asks for the name and address, then
places the order after `YES`. The customer receives an order code.

### 7.2 Vendor flow by SMS

The vendor reply must come from the phone number stored on the vendor profile
(`vendors/{vendorId}.phone`). For Sao Gas that is **+255777000777**.

```text
YES
```

or

```text
NO
```

The customer is told when the vendor accepts and receives the vendor number.

### 7.3 Vendor flow in the app (recommended when testing with arbitrary phones)

Log in on the vendor phone with:

```text
Phone: +255777000777
PIN:   1234
```

Open the vendor dashboard. New orders appear live. Use **Pokea / Accept**,
then **Anza Safari** (ETA + optional rider), then **Imefika / Arrived**.

### 7.4 Mock end-to-end test (no real SMS)

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node -r dotenv/config scripts/test-sms-order.js
```

This creates a real Firestore order, runs customer + vendor SMS steps against a
mock TextBee endpoint, verifies the order, then deletes the test order.

### 7.5 Check an order by phone

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
set -a; source .env; set +a

curl -sS -G "http://127.0.0.1:8080/v1/bridge/orders/status" \
  -H "x-api-key: $API_KEY_GASLINK" \
  --data-urlencode "phone=+255714604777" \
  --data-urlencode "limit=5" | python3 -m json.tool
```

### 7.6 Reset the SMS order state machine

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
rm data/sms-order-state.json
lsof -ti tcp:8080 | xargs kill
nohup node server.js >> gateway.log 2>&1 &
```

The state is cached in memory, so a restart is required after deleting the file.

### 7.7 Use a different phone as the SMS vendor

For testing only. The SMS vendor reply is matched by phone number.

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
export VENDOR_PHONE="+2557XXXXXXXX"   # the test phone's number
node - <<'JS'
require('dotenv').config();
const { db } = require('./services/firebase-admin');
(async () => {
  const phone = process.env.VENDOR_PHONE;
  if (!phone) throw new Error('Set VENDOR_PHONE first');
  await db().collection('vendors').doc('HR7lVXzVHWPeR94ebRF5').set(
    { phone },
    { merge: true }
  );
  console.log('vendor phone set to', phone);
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
JS
```

Restore it when finished:

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
export VENDOR_PHONE="+255777000777"
node - <<'JS'
require('dotenv').config();
const { db } = require('./services/firebase-admin');
(async () => {
  await db().collection('vendors').doc('HR7lVXzVHWPeR94ebRF5').set(
    { phone: process.env.VENDOR_PHONE },
    { merge: true }
  );
  console.log('vendor phone restored to', process.env.VENDOR_PHONE);
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
JS
```

Do not leave a test phone on the vendor profile: it is the number shown to
customers after confirmation.

---

## 8. Testing with multiple phones

Recommended matrix:

| Phone | Role | What to do |
|---|---|---|
| Samsung SM-A075F | Gateway phone | Keep on Wi-Fi/power; runs TextBee. Do not use it as a customer. Only **0767304776** is confirmed; the Vodacom SIM number is unverified (see `PHONE_NUMBERS.md`). |
| Phone A | Consumer (app) | Install APK, register with Phone A's own number + 4-digit PIN, place an order. |
| Phone B | Vendor (app) | Install APK, log in `+255777000777` / `1234`, accept the order. |
| Phone C | Consumer (SMS) | Text `0767304776` with `Nataka Oryx 6kg` and follow prompts. |
| Phone D | Vendor (SMS, optional) | Only if its SIM matches the vendor phone, or use §7.7 temporarily. |

**Do not register the gateway phone's own SIM as a consumer.** A message sent
from the gateway phone to `0767304776` is a self-send; it does not enter the
TextBee inbound queue. Use a separate phone for the customer test. To confirm
receiving independently, text **0767304776** from another phone. The gateway's
Vodacom SIM number is unverified — do not assume it is any customer number.
Every number used in testing must be approved in `PHONE_NUMBERS.md`.

**Current testing rule (17 Nov 2026):** the owner runs all tests. Do not send
test SMS or initiate calls; ask first. Unknown-number opt-in is paused
(`optInUnauthorized: false`); only app-registered numbers are engaged, and only
when they initiate. Keep `GASLINK_SELF_NUMBER_RELAY=true`.

### 8.1 App order test

1. Phone A: Home -> Refill -> Oryx Gas -> Sao Gas Supply -> **Oda Sasa**.
2. Enter delivery address and confirm.
3. Phone B: vendor dashboard shows the new order. Tap **Pokea / Accept**.
4. Phone A: vendor phone is released and the first step substeps update.
5. Phone B: **Anza Safari** -> choose ETA -> optional rider phone.
6. Phone A: sees ETA/rider.
7. Phone B: **Imefika / Arrived**.
8. Phone A: **Nimepokea** within 10 minutes. The cylinder updates on Home.
9. If Phone A does nothing, the gateway finalizer closes the order after 10 minutes.

### 8.2 SMS order test

1. Phone C texts `Nataka Oryx 6kg`.
2. Reply with name, address, `YES`.
3. Phone B accepts in the app, or a matching vendor phone texts `YES`.
4. Check the order and SMS log.

### 8.3 What can fail and why

| Symptom | Cause | Fix |
|---|---|---|
| Vendor push not received | Stale/wrong FCM token | Log out and back in on the vendor phone; SMS fallback still works. |
| Vendor SMS `YES` ignored | Sender is not the vendor phone | Use the vendor app or §7.7. |
| No AI reply | Sender is not an AI subscriber and message is not a business keyword | Use the app number or an order keyword. |
| TextBee `429` | 50 messages/day used (inbound + outbound count) | Wait until 00:00 UTC / 03:00 EAT, or use a second device/account. |
| Order stuck at `placed` | Vendor has not opened/accepted | Vendor dashboard -> Accept. |
| Order stuck at `delivered_pending` | Buyer has not confirmed | Wait 10 minutes for the finalizer, or buyer confirms. |
| `SMS_GATEWAY_API_KEY is not configured` | APK built without `env.local.json` | Rebuild with §5. |

---

## 9. Firestore quick checks

Use the service account from the app directory.

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node - <<'JS'
require('dotenv').config();
const { db } = require('./services/firebase-admin');
(async () => {
  const dbRef = db();
  const orders = await dbRef.collection('orders')
    .orderBy('created_at', 'desc').limit(5).get();
  console.log('recent orders:');
  orders.docs.forEach((d) => {
    const o = d.data();
    console.log(d.id, o.status, o.brand, o.weight || o.size, o.total_price);
  });

  const outbox = await dbRef.collection('notification_outbox')
    .where('status', '==', 'pending').limit(10).get();
  console.log('pending outbox:', outbox.size);

  const disputes = await dbRef.collection('disputes').limit(5).get();
  console.log('disputes:', disputes.size);
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
JS
```

Inspect one order:

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
export ORDER_ID="paste-order-id-here"
node - <<'JS'
require('dotenv').config();
const { db } = require('./services/firebase-admin');
(async () => {
  const id = process.env.ORDER_ID;
  const snap = await db().collection('orders').doc(id).get();
  console.log(JSON.stringify(snap.data(), null, 2));
  process.exit(0);
})();
JS
```

Clean a test order and its outbox entries:

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
export ORDER_ID="paste-order-id-here"
node - <<'JS'
require('dotenv').config();
const { db } = require('./services/firebase-admin');
(async () => {
  const orderId = process.env.ORDER_ID;
  const fs = db();
  const out = await fs.collection('notification_outbox')
    .where('data.orderId', '==', orderId).get();
  const batch = fs.batch();
  out.docs.forEach((d) => batch.delete(d.ref));
  batch.delete(fs.collection('orders').doc(orderId));
  await batch.commit();
  console.log('deleted', orderId);
  process.exit(0);
})();
JS
```

---

## 10. TextBee / SMS gateway

### 10.1 Device health

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node - <<'JS'
require('dotenv').config();
const axios = require('axios');
(async () => {
  const r = await axios.get(
    `https://api.textbee.dev/api/v1/gateway/devices/${process.env.TEXTBEE_DEVICE_ID}`,
    { headers: { 'x-api-key': process.env.TEXTBEE_API_KEY }, timeout: 15000 }
  );
  const d = r.data.data;
  console.log({ name: d.name, enabled: d.enabled, sent: d.sentSMSCount,
    received: d.receivedSMSCount, updatedAt: d.updatedAt });
})();
JS
```

### 10.2 Quota

The free TextBee plan allows **50 messages/day**, and **received SMS counts
too**. When exhausted, sends return `429` and resume at **00:00 UTC / 03:00
EAT**. The outbox worker detects this and defers SMS retries to the next UTC
midnight instead of burning attempts.

### 10.3 Inbound poller

TextBee webhooks cannot reach a LAN gateway, so the gateway polls every 10 s.

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
tail -f gateway.log | grep textbee-poller
cat data/textbee-inbound-cursor.json
```

### 10.4 Operator channel

Texts from **0714604777** are logged to `data/operator-inbox.jsonl` and skipped
by the customer AI. Texts from the gateway phone itself are **not** a customer
channel; do not use it to place test orders.

```zsh
tail -f /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/data/operator-inbox.jsonl
```

---

## 11. Logs

| Log | Path |
|---|---|
| Gateway / AI / poller / outbox / finalizer | `.../kachi-fintech-sandbox/gateway.log` |
| FCM dispatcher | `/Users/apple/gaslink_app/build_logs/fcm_dispatcher.log` |
| APK server | `/Users/apple/gaslink_app/build_logs/apk_server.log` |
| Release build | `/Users/apple/gaslink_app/build_logs/release_*.log` |
| SMS ledger | `.../kachi-fintech-sandbox/data/sms-log.json` |
| AI sessions | `.../kachi-fintech-sandbox/data/ai-sessions.json` |
| SMS order state | `.../kachi-fintech-sandbox/data/sms-order-state.json` |

Follow the important ones:

```zsh
tail -f /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/gateway.log
tail -f /Users/apple/gaslink_app/build_logs/fcm_dispatcher.log
```

---

## 12. Common problems

### Gateway not listening on 8080

The gateway warms up Firestore first; wait 20–30 s. If it still fails:

```zsh
tail -40 /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/gateway.log
lsof -ti tcp:8080 | xargs kill
```

Then restart §1.

**Fixed 17 Nov 2026:** `services/ai-service.js` used to `require('googleapis')`
at the top even though the Gemini path calls the REST API with `axios`. That
unused import cost ~25 s of cold-start time and made launchd look dead. The
import is gone; startup is now a few seconds. If a future change re-adds a heavy
top-level `require`, lazy-load it inside the function that needs it.

### `EADDRINUSE`

```zsh
lsof -ti tcp:8080 | xargs kill
lsof -ti tcp:8090 | xargs kill
```

### APK server returns 404

The server must run from the APK directory:

```zsh
cd /Users/apple/gaslink_app/build/app/outputs/flutter-apk
ls -la gaslink-latest.apk app-release.apk
```

### Phone cannot open the APK link

- Same Wi-Fi?
- `MAC_IP` correct?
- macOS firewall allowing Python?
- VPN on either device?
- Try the directory listing: `http://$MAC_IP:8090/`.

### No inbound SMS at all

First check whether TextBee actually received it:

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
set -a; source .env; set +a
node - <<'JS'
require('dotenv').config();
const axios = require('axios');
(async () => {
  const r = await axios.get('https://api.textbee.dev/api/v1/gateway/messages', {
    headers: { 'x-api-key': process.env.TEXTBEE_API_KEY },
    params: { direction: 'received', limit: 10, order: 'desc' },
    timeout: 15000,
  });
  for (const m of (r.data && r.data.data) || []) {
    console.log(m.receivedAt, m.sender, m.message);
  }
})();
JS
```

If the message is **not** in that list, it never reached the gateway phone:

- Do not text from the gateway phone itself; a self-send is not an inbound SMS.
- Only `0767304776` is a confirmed gateway number. Text it from another phone
  to confirm the public SIM is receiving. The gateway's Vodacom SIM number is
  unverified; do not use a customer number as a gateway test.
- `0767304776` is the public line; if it never receives, check which SIM it is
  in and whether TextBee is set to receive SMS on that SIM.
- Check SMS bundle/credit on the sending and receiving SIMs.
- On the gateway phone, set TextBee battery usage to **Unrestricted** and allow
  background activity. `powerInfo.isIgnoringBatteryOptimizations` was `false`
  at the last check.
- Make sure the gateway phone is on Wi-Fi/power and the TextBee app is running.

If the message **is** in the list but not in `gateway.log`, check the poller
cursor and restart the gateway (§1).

### FCM: `Permission denied by the third party webpush service`

The stored token is stale or belongs to a web push subscription. Log the user
out and back in on the Android app to refresh it. Order SMS fallback still works.

### TextBee poller shows `timeout`

TextBee cloud is slow or unreachable. It retries every 10 s; check:

```zsh
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
set -a; source .env; set +a
curl -sS https://api.textbee.dev/api/v1/gateway/devices \
  -H "x-api-key: $TEXTBEE_API_KEY" | head
```

### SMS order started on the wrong phone

Delete `data/sms-order-state.json` and restart the gateway (§7.6).

---

## 13. Before a demo / daily checklist

```zsh
export MAC_IP="$(ipconfig getifaddr en0)"

# 1. Services
curl -sS "http://127.0.0.1:8080/health"; echo
curl -sI "http://$MAC_IP:8090/gaslink-latest.apk" | head -3

# 2. Gateway workers
tail -20 /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/gateway.log

# 3. Test SMS
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node scripts/send-operator-sms.js "GasLink daily check: gateway online"

# 4. Test SMS ordering state machine (mock, no SMS spent)
node -r dotenv/config scripts/test-sms-order.js

# 5. Phone test
echo "APK:       http://$MAC_IP:8090/gaslink-latest.apk"
echo "Dashboard: http://$MAC_IP:8080/dashboard"
```

---

## 14. Privacy & security checks

The full data-collection inventory is in
[`PRIVACY_DATA_INVENTORY.md`](PRIVACY_DATA_INVENTORY.md). Read it before writing
the privacy policy or sharing the APK.

### 14.1 What the release APK can access

```zsh
cd /Users/apple/gaslink_app
"$HOME/Library/Android/sdk/build-tools/36.0.0/aapt2" dump permissions \
  build/app/outputs/flutter-apk/app-release.apk
```

Expected pilot permissions: `INTERNET`, `ACCESS_NETWORK_STATE`,
`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`,
`VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, FCM/GSF internals.
Location is currently unused by app code.

### 14.2 Firestore is currently open (critical)

Verified 17 Nov 2026: an unauthenticated REST read of `users` with the Firebase
API key from `lib/firebase_options.dart` returned HTTP 200 and real documents
including `phone` and `passcodeHash`. Treat the database as public until rules
are deployed.

```zsh
# Reproduce the read-only check (prints status + field names, not values)
cd /Users/apple/gaslink_app
KEY="$(grep -m1 "apiKey:" lib/firebase_options.dart | sed "s/.*'\(.*\)'.*/\1/")"
curl -sS -o /tmp/gaslink_fs_probe.json -w "HTTP %{http_code}\n" \
  "https://firestore.googleapis.com/v1/projects/gaslink-app-4bfbb/databases/(default)/documents/users?pageSize=1&key=$KEY"
python3 - <<'PY'
import json
d=json.load(open('/tmp/gaslink_fs_probe.json'))
print('documents:', len(d.get('documents', [])))
print('fields:', sorted({k for doc in d.get('documents', []) for k in (doc.get('fields') or {})}))
PY
rm -f /tmp/gaslink_fs_probe.json
```

A 403 is the desired result. A 200 means rules are missing/open.

### 14.3 Storage and inbound webhook

```zsh
cd /Users/apple/gaslink_app
cat storage.rules          # public read; anonymous write to any vendor path

cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
grep -E "^TEXTBEE_INBOUND_SECRET=" .env || echo "NOT SET -> /v1/inbound-sms is open"
```

### 14.4 APK signing and backup

```zsh
cd /Users/apple/gaslink_app
grep -n "signingConfig" android/app/build.gradle          # debug signing in release
grep -n "allowBackup" android/app/src/main/AndroidManifest.xml || \
  echo "allowBackup not set -> defaults to true"
```

### 14.5 Do not publish yet

Do not share the APK link outside the pilot until Firestore/Storage rules,
admin auth, and the privacy policy are fixed. See
`PRIVACY_DATA_INVENTORY.md` §11 for the full risk register.

---

## 15. Rules that keep the pilot safe

- Do not change FIFO cylinders, order lifecycle, auth/session logic, or the
  Firestore schema without an explicit decision.
- One release build at a time; keep the laptop on AC power.
- Never ship the hardcoded admin credentials or open Firestore rules to
  production.
- Keep the gateway `.env` and `serviceAccountKey.json` out of git.
- Test on trusted phones and the private Wi-Fi only.
- TextBee’s daily cap is a pilot constraint, not a production SMS plan.
