# Live local mount (13 Nov 2026)

The bridge is mounted in the self-hosted gateway at:

```
/Users/apple/.cline/data/workspaces/chat/kachi-fintech-sandbox
```

Changes made there (outside this repo):

1. Copied `firebase-bridge.js` into the gateway root.
2. Mounted it in `server.js`:

   ```js
   const { createFirebaseBridgeRouter } = require('./firebase-bridge');
   app.use('/v1/bridge', createFirebaseBridgeRouter());
   ```

3. Installed `firebase-admin` (`npm install firebase-admin@^13.6.0 --save`).
4. Set in the gateway `.env`:

   ```dotenv
   PORT=8080
   GASLINK_SUBSCRIBER_CHECK_URL=http://127.0.0.1:8080/v1/bridge/subscriber
   FIREBASE_SERVICE_ACCOUNT_PATH=/Users/apple/gaslink_app/serviceAccountKey.json
   ```

5. Added temporary compatibility shims because the updated gateway files use
   underscores while the requires use hyphens:

   - `routes/v1-otp.js` → re-exports `routes/v1_otp.js`
   - `services/otp-service.js` → re-exports `services/otp_service.js`
   - `services/ai-config-store.js` → re-exports `services/ai_config_store.js`
   - `services/sms-store.js` → re-exports `services/sms_store.js`

   If those files are renamed, delete the shims.

## Current ports

- Gateway + AI + OTP + bridge: **8080**
- APK download server: **8090**
- Old gateway on 3000 has been stopped.

## Verified

- `GET /health`
- `POST /v1/otp/send` with auth (invalid phone correctly returns `INVALID_PHONE`)
- `POST /v1/bridge/subscriber` returns `registered` / `aiEnabled`
- Subscriber gate live check returned `remote_ai_disabled` for an AI-off user
- `GET /v1/bridge/catalog` returns 6 live products
