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

> **Correction (14 Nov 2026):** the live mapping is Oryx Red, Manjis Grey,
> Mihan/O-Gas Yellow, Taifa Green, Lake Blue. See `PROJECT_BIBLE.md`.
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

- `SMS_GATEWAY_BASE_URL` (default `http://192.168.1.12:8080`)
- `SMS_GATEWAY_API_KEY` (`x-api-key`)
- `ENABLE_OTP_LOGIN` (default `false`)

Build with a gitignored `env.local.json`:

```bash
flutter build apk --release --dart-define-from-file=env.local.json
```

`android/app/src/main/res/xml/network_security_config.xml` permits cleartext
only for the pilot LAN hosts; public tunnel URLs must use HTTPS.

## 6. Verification (13 Nov 2026)

- `flutter analyze`: 0 errors / 0 warnings.
- `flutter test`: 116/116 passed, including dispatcher preference matrix, SMS
  payload parsing, OTP gating, ARB parity, and D2 bilingual scans.
- `gateway`: 3/3 Node tests passed.
- Live gateway: `/health` OK; `POST /v1/send-sms` returned `success: true` to
  the admin test number; bridge `/subscriber` returned the seeded vendor with
  `aiAssistantEnabled: false`; `/catalog` returned 6 live products and the four
  brand colours; `/orders` correctly rejected a non-opted-in subscriber (403).
- End-to-end bridge order: with a temporarily opted-in seeded consumer, the
  bridge created a `placed` 26,000 TZS Oryx 6kg order with `source: sms_ai`;
  the order and its notification ledger entry were deleted and the opt-in flag
  restored immediately after the check.
- The gateway runs on the Mac’s current LAN IP at port 8080
  (`ipconfig getifaddr en0`); `env.local.json` points there for the pilot APK.
  The code default remains `192.168.1.12:8080` as specified.

## 7. Out of scope / next

- Mount the bridge into the updated gateway (pending gateway rewrite).
- Firestore security rules and the custom-token auth bridge (Phase 6A/6B).
- Payment-confirmed trigger once a payment provider exists.
- Rate limiting and audit logs on the public bridge.
- Legacy `vendors/{id}/products` rows in the catalog snapshot (top-level
  `products` is the current write path).
