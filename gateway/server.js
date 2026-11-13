// gateway/server.js
// Optional standalone runner for the Firebase bridge. If you prefer, import
// createFirebaseBridgeRouter() directly into the existing SMS gateway.

require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const { createFirebaseBridgeRouter } = require('./firebase-bridge');

const app = express();
const PORT = process.env.BRIDGE_PORT || 3001;

app.use(helmet());
app.use(express.json({ limit: '100kb' }));

app.use('/v1/bridge', createFirebaseBridgeRouter());

app.get('/health', (req, res) => {
  res.json({ status: 'OK', service: 'gaslink-firebase-bridge' });
});

app.listen(PORT, () => {
  console.log(`GasLink Firebase bridge on http://localhost:${PORT}`);
  console.log(
    `API_KEY_GASLINK loaded:`,
    process.env.API_KEY_GASLINK ? 'YES' : 'NO (MISSING)',
  );
  console.log(
    `Firebase credentials:`,
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 'application default',
  );
});
