# GasLink AI SMS Pipeline — Live Data and Inbound Transport

> Companion to `PROJECT_BIBLE.md` §10. This document explains how the
> self-hosted gateway gives the AI assistant **live Firestore prices/stock** and
> how inbound SMS reaches the AI without a public webhook URL.

## Where the code lives

The AI/SMS gateway is a separate Node project on the pilot Mac:

```text
/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox/
├── server.js
├── routes/inbound-sms.js
├── services/ai-service.js
├── services/app-context.js
├── services/subscriber-store.js
├── services/sms-gateway.js
├── services/textbee-inbound-poller.js
├── services/sms-store.js
├── data/ai-config.json
├── data/sms-log.json
├── data/textbee-inbound-cursor.json
└── gateway.log
```

It is **not** inside the Flutter repository. The Flutter repo contains the
Firebase bridge (`gateway/firebase-bridge.js`) and this documentation.

## 1. Live catalogue context (the important fix)

Earlier, `services/app-context.js` read `data/gaslink-catalog.json` — sample
data. The AI therefore quoted **TZS 22,000** for Oryx 6kg while Firestore held
**TZS 26,000**.

The current design:

```text
Inbound SMS
   │
   ▼
subscriber gate (phone + ai_assistant_enabled)
   │
   ▼
appContext.build()  ──HTTP──▶  GET /v1/bridge/catalog
   │                           (Firebase Admin SDK, live Firestore)
   ▼
system prompt + live product/price/stock block
   │
   ▼
DeepSeek chat completion
   │
   ▼
NO_REPLY / 160-char gate
   │
   ▼
TextBee send-sms
```

Key properties:

- `build()` is **async**; all three call sites in `services/ai-service.js`
  `await` it.
- Every reply pulls a fresh catalogue. Nothing is cached.
- The snapshot contains refill and full-set groups, accessories/services if
  listed, brand colours/aliases, vendor names/areas/verification, stock state,
  and the live SMS traffic counters.
- **No sample fallback.** If the bridge call fails, the context says:

  > LIVE CATALOG: UNAVAILABLE. Do NOT quote any price, stock level or delivery
  > fee. Tell the customer you will confirm the current price…

  The model cannot fall back to remembered or sample prices.
- Delivery fees are never quoted from the sample data; the live bridge does not
  expose a per-order fee, so the AI says the fee is confirmed when ordering.

### Verified answers (14 Nov 2026, live Sao Gas data)

| Question | Reply |
|---|---|
| How much is Oryx 6kg refill? | Oryx Gas 6kg refill **TZS 26,000**, in stock at Sao Gas Supply, Sinza |
| Gesi nyekundu 6kg ni shilingi ngapi? | Red → Oryx; **TZS 26,000** |
| Oryx 13kg refill bei gani? | 13kg is not in the catalogue; offers live 6kg/15kg |
| Full set ya Oryx 6kg ni ngapi? | No full set listed; does not invent a price |
| Delivery fee ni shilingi ngapi? | Depends on vendor/distance; confirmed when ordering |
| Habari yako? | `NO_REPLY`; nothing sent |
| Unknown phone | Subscriber gate blocks before DeepSeek |

## 2. Inbound SMS transport

### Why not the TextBee webhook?

TextBee pushes `MESSAGE_RECEIVED` to a **public HTTPS URL**. The gateway is on
the pilot LAN (`192.168.1.11:8080`) and has no public URL, so TextBee’s cloud
cannot reach it. A tunnel would work but adds exposure, cost and a moving URL.

### Local poller

`services/textbee-inbound-poller.js`:

- Enabled by `TEXTBEE_POLL_ENABLED=true`; default interval 10s.
- Calls TextBee `GET /gateway/messages?direction=received&order=asc&from=…`.
- On first run, anchors a cursor at the newest existing message so old SMS is
  never replayed.
- For each new message:
  1. Skip if already seen or not newer than the cursor.
  2. Run the subscriber gate.
  3. **Unauthorized senders are skipped silently** — no AI call, no SMS log
     entry, no reply. This keeps personal SMS on the TextBee phone out of the
     GasLink log.
  4. Authorized senders are POSTed to the local `/v1/inbound-sms` pipeline.
  5. Cursor advances only after the pipeline accepts the message.
- Cursor file: `data/textbee-inbound-cursor.json`.
- Log line: `[textbee-poller] +255…: AI replied`.

### If a public HTTPS URL is added later

1. Point TextBee’s `MESSAGE_RECEIVED` webhook at
   `https://<host>/v1/inbound-sms`.
2. Set `TEXTBEE_INBOUND_SECRET` and include it as `?secret=…` or
   `x-webhook-secret`.
3. The route ignores `MESSAGE_SENT`, `MESSAGE_DELIVERED`, `MESSAGE_FAILED` and
   other status events with HTTP 200 `{ignored:true}`.
4. Keep the poller off to avoid duplicate processing.

The route accepts both flat TextBee fields (`sender`, `message`) and common
aliases (`from`, `phone`, `text`, `body`).

## 3. Environment

Gateway `.env` (never commit):

```dotenv
TEXTBEE_DEVICE_ID=...
TEXTBEE_API_KEY=txb_...
TEXTBEE_POLL_ENABLED=true
TEXTBEE_POLL_INTERVAL_MS=10000

# Optional, only for a public webhook:
# TEXTBEE_INBOUND_SECRET=<at-least-20-chars>

API_KEY_GASLINK=gl-alsk...        # tenant key: SMS, OTP, bridge, inbound
SANDBOX_API_KEY_GASLINK=gl-sand... # dashboard simulator/config key
GASLINK_SUBSCRIBER_CHECK_URL=http://127.0.0.1:8080/v1/bridge/subscriber
FIREBASE_SERVICE_ACCOUNT_PATH=/Users/apple/gaslink_app/serviceAccountKey.json
```

`USE_MOCK_APIS` is unrelated: it only controls the NIDA/PSP/bank sandbox
adapters. Leave it `true`; setting it to `false` makes those routes throw
“production API not implemented”. It does not affect SMS, OTP, DeepSeek, the
bridge or the live catalogue.

## 4. Running and restarting

```bash
cd /Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
node --check server.js
nohup node server.js > gateway.log 2>&1 &
curl -sS http://127.0.0.1:8080/health
tail -f gateway.log
```

Startup can take several seconds while Firebase Admin initializes; a health
check immediately after launch may fail once, then succeed. Confirm exactly one
`node server.js` process and that port 8080 is listening.

## 5. Testing

### Simulator

```bash
KEY=$(grep -E '^SANDBOX_API_KEY_GASLINK=' .env | cut -d= -f2- | xargs)
curl -sS -X POST "http://127.0.0.1:8080/api/sandbox/ai/simulate" \
  -H "x-api-key: $KEY" -H "Content-Type: application/json" \
  -d '{"phone":"+2557XXXXXXXX","message":"Oryx 6kg refill bei?"}'
```

Use a phone whose `users/{uid}.ai_assistant_enabled` is `true`, otherwise the
subscriber gate returns `unauthorized_ai_user` before any model call.

### Inbound pipeline (sends a real SMS)

```bash
KEY=$(grep -E '^API_KEY_GASLINK=' .env | cut -d= -f2- | xargs)
curl -sS -X POST "http://127.0.0.1:8080/v1/inbound-sms" \
  -H "x-api-key: $KEY" -H "Content-Type: application/json" \
  -d '{"from":"+2557XXXXXXXX","message":"Oryx 6kg refill ni bei gani?"}'
```

Expected: `{"success":true,"ai":{...},"replySent":true}` and a matching
`outbound` entry in `data/sms-log.json`.

### Physical round trip

1. Send any SMS from an AI-enabled phone to the TextBee SIM, or reply to the
   last GasLink SMS.
2. The poller picks it up within ~10–20s.
3. Check `tail gateway.log` and `data/sms-log.json` for an `inbound` entry with
   `channel: "textbee-poll"` and an `ai-reply` outbound entry.

## 6. Troubleshooting

| Symptom | Check |
|---|---|
| AI quotes TZS 22,000 or old brands | The gateway is running old code; restart `node server.js` and confirm `/v1/bridge/catalog` returns live prices |
| AI says “catalogue unavailable” | Bridge key, Firebase service account, `FIREBASE_SERVICE_ACCOUNT_PATH`, and `GET /v1/bridge/catalog` with the tenant key |
| `blocked: unauthorized_ai_user` | `users/{uid}.ai_assistant_enabled` is not true, or phone format does not match |
| No reply to a real SMS | Poller enabled? TextBee `receiveSMSEnabled:true`? Sender AI-enabled? Check `data/textbee-inbound-cursor.json` |
| Poller loops on one message | Inspect `msg.receivedAt` and the cursor; the cursor only advances after a 2xx pipeline response |
| Duplicate AI replies | Do not run both the poller and a TextBee webhook; choose one |
| Delivery fee quoted | A stale APK/gateway is running; the live bridge has no fee field and the prompt forbids quoting one |

## 7. Security notes

- The poller never replies to unauthorized senders, so it cannot be used to
  spam arbitrary SMS contacts on the TextBee phone.
- The subscriber gate is default-deny.
- The DeepSeek key lives server-side in `data/ai-config.json`; the dashboard
  returns only the last four characters.
- A public webhook must set `TEXTBEE_INBOUND_SECRET`; without it the inbound
  route accepts unauthenticated posts by design for sandbox use.
- Never expose port 8080 publicly without HTTPS and the webhook secret.

## 8. Ordering by SMS — current status

The bridge endpoint `POST /v1/bridge/orders` exists and can create a `placed`
order with `source: sms_ai`, but **the AI assistant does not call it**. There is
no order parser, address capture, confirmation step or idempotency key in the
inbound pipeline, so a text such as “Nataka Oryx 6kg mbili” must not be treated
as an order.

Current behaviour:

- The AI answers price, stock, delivery-policy and product questions.
- System prompt rule 6 forbids accepting, confirming or claiming to place an
  order by SMS. It tells the customer to order in the GasLink app.
- The settings subtitle is now:
  - EN: “Ask about live prices, stock and delivery by SMS. Order in the app.”
  - SW: “Uliza bei, stock na delivery kwa SMS. Agiza kupitia app.”
- The old “Order by SMS in Swahili. Coming soon.” string was removed.

To enable SMS ordering safely later:

1. Detect an explicit order intent and resolve brand/size/quantity against the
   live catalogue (never a model-invented vendor or price).
2. Collect or confirm the delivery address.
3. Send a “Reply YES to confirm …” message and keep pending state per phone.
4. On YES, call `/v1/bridge/orders` with an idempotency key derived from the
   phone and pending-order ID.
5. Re-check stock and price immediately before creating the order.
6. Send the order-placed SMS and let the existing notification pipeline take
   over.

Do not give the model an unrestricted order-creation tool; a wrong address or
duplicate confirmation creates a real dispatch.
