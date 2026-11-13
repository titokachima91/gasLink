# Phase 05F — SMS, Notifications & AI Gateway Foundation

> **Status:** 🚧 Foundation implemented — bridge module ready to mount.
> **Branch:** `harden-source-of-truth`
> **Rule:** existing order, FIFO, auth and Firestore schemas are preserved;
> new fields and channels are additive.

---

## 1. User preferences

`users/{uid}` gains two fields:

| Field | Values | Default |
| --- | --- | --- |
| `notification_channel` | `push_only`, `sms_only`, `both`, `none` | `both` |
| `ai_assistant_enabled` | bool | `false` |

Missing fields keep existing accounts on `both` + AI off. Registration writes
the explicit defaults. The settings card is shared by consumer and vendor
settings (`NotificationsAiSettings`).

## 2. Unified dispatcher

`NotificationDispatcher.dispatchToUser()` reads the recipient profile, then:

- `push_only` / `both` → existing `notifications` ledger + FCM flow.
- `sms_only` / `both` → `POST /v1/send-sms` with the recipient phone.
- `none` → nothing.

Order-created events now notify both the vendor and the customer. Status events
(`confirmed`, `on_the_way`, `delivered`, `cancelled`) mirror the same way.
SMS text follows the persisted app language (Kiswahili fallback) through
`loadLocalizedMessages()`.

Payment-confirmed is not implemented in the current app; the dispatcher and
message keys are ready for it.

## 3. OTP foundation

`OtpAuthService` and `OtpVerificationScreen` call `/v1/otp/send` and
`/v1/otp/verify`. `GatewayConfig.enableOtpLogin` defaults to `false`; phone +
PIN remains the only active login path.

## 4. Firebase ↔ gateway bridge

`gateway/firebase-bridge.js` is a secure Express router using the Admin SDK:

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/v1/bridge/subscriber?phone=` | existence + AI opt-in |
| `GET` | `/v1/bridge/catalog` | live products, colours, prices, stock |
| `POST` | `/v1/bridge/orders` | create a `placed` SMS order |
| `GET` | `/v1/bridge/health` | liveness |

Brand colours: Oryx = Red, Manjis/Mihan = Yellow, Taifa = Blue, Lake = Green.
Orders use the same dual snake_case/camelCase keys as Flutter and support an
optional `idempotencyKey`. The customer must exist and have
`ai_assistant_enabled: true`.

Mount it into the existing gateway with:

```js
const { createFirebaseBridgeRouter } = require('./firebase-bridge');
app.use('/v1/bridge', createFirebaseBridgeRouter());
```

See `gateway/README.md` for env vars, curls and the standalone runner.

## 5. Configuration

`lib/core/gateway_config.dart` centralizes:

- `SMS_GATEWAY_BASE_URL` (default `http://192.168.1.12:3000`)
- `SMS_GATEWAY_API_KEY` (`x-api-key`)
- `ENABLE_OTP_LOGIN` (default `false`)

Build with a gitignored `env.local.json`:

```bash
flutter build apk --release --dart-define-from-file=env.local.json
```

`android/app/src/main/res/xml/network_security_config.xml` permits cleartext
only for the pilot LAN hosts; public tunnel URLs must use HTTPS.

## 6. Out of scope / next

- Mount the bridge into the updated gateway (pending gateway rewrite).
- Firestore security rules and the custom-token auth bridge (Phase 6A/6B).
- Payment-confirmed trigger once a payment provider exists.
- Rate limiting and audit logs on the public bridge.
- Legacy `vendors/{id}/products` rows in the catalog snapshot (top-level
  `products` is the current write path).
