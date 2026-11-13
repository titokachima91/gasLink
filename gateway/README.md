# GasLink Firebase <-> SMS/AI Bridge

Secure endpoints the self-hosted Node gateway uses to read GasLink data and
create SMS orders. Every request needs the GasLink tenant key:

```
x-api-key: gl-...
```

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET/POST` | `/v1/bridge/subscriber` | Existence + AI opt-in check (`phone` query or `{phone}` body) |
| `GET` | `/v1/bridge/catalog` | Live products, colours, sizes, prices, vendor stock |
| `POST` | `/v1/bridge/orders` | Create a PENDING (`placed`) SMS order |
| `GET` | `/v1/bridge/health` | Liveness |

The subscriber response includes both naming conventions expected by the
gateway's subscriber gate:

```json
{ "exists": true, "registered": true, "found": true,
  "aiAssistantEnabled": true, "aiEnabled": true }
```

Set `GASLINK_SUBSCRIBER_CHECK_URL=http://127.0.0.1:8080/v1/bridge/subscriber`
when the bridge is mounted in the gateway.

Only users with `ai_assistant_enabled: true` can create SMS orders. The bridge
never returns PIN hashes or other credentials.

### Brand colour mapping

| Brand | Colour | Swahili alias |
| --- | --- | --- |
| Oryx Gas | Red | nyekundu |
| Manjis / Mihan Gas | Yellow | njano |
| Taifa Gas | Blue | bluu |
| O-Lake / Lake Gas | Green | kijani |

## Mount into the existing gateway

Copy `firebase-bridge.js` into the gateway project root, install the dependency,
then mount it next to the existing `/v1` routes:

```js
const { createFirebaseBridgeRouter } = require('./firebase-bridge');
app.use('/v1/bridge', createFirebaseBridgeRouter());
```

`package.json`:

```bash
npm install firebase-admin
```

Environment (`.env`):

```dotenv
API_KEY_GASLINK=gl-your-existing-tenant-key
FIREBASE_SERVICE_ACCOUNT_PATH=../gaslink_app/serviceAccountKey.json
# or use GOOGLE_APPLICATION_CREDENTIALS with application default credentials
```

## Run standalone

```bash
cd gateway
cp .env.example .env
npm install
npm start
# http://localhost:3001/v1/bridge/health
```

## Examples

```bash
KEY="gl-..."
BASE="http://192.168.1.12:3001"

curl -H "x-api-key: $KEY" "$BASE/v1/bridge/subscriber?phone=0767304776"
curl -H "x-api-key: $KEY" "$BASE/v1/bridge/catalog"

curl -X POST "$BASE/v1/bridge/orders" \
  -H "x-api-key: $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0767304776",
    "vendorId": "VENDOR_UID",
    "brand": "Oryx Gas",
    "size": "6kg",
    "quantity": 1,
    "category": "refill",
    "orderIntent": "add_stock",
    "address": "Kinondoni, Dar es Salaam",
    "paymentMethod": "cash",
    "sessionId": "sms-session-123",
    "idempotencyKey": "sms-session-123-1"
  }'
```

Orders are written with the same dual snake_case/camelCase keys as the Flutter
app (`consumer_uid` + `consumerUid`, `total_price` + `totalPrice`, etc.) and
`status: "placed"` so the existing vendor flow accepts them unchanged.

## Security notes

- The bridge uses the Firebase Admin SDK, which bypasses Firestore rules. Keep
  the service account and `.env` out of version control.
- Expose it through the same private network or HTTPS tunnel as the SMS gateway.
- Rate-limit `/orders` at the gateway/proxy layer before public exposure.
- The customer must exist and have `ai_assistant_enabled: true`.
- The mobile app embeds the tenant `gl-...` key at build time. Like any mobile
  secret it can be extracted from the APK; rotate it before public release and
  keep gateway rate limits tight.
