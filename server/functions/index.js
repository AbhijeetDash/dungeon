'use strict';

// Cloud Functions entry point. The whole Express app is exposed as a single
// HTTPS function named `api`. When deployed (or run in the Functions emulator)
// it is reachable at:
//   http://<host>:5001/<project>/<region>/api/...     (emulator)
//   https://<region>-<project>.cloudfunctions.net/api/...  (deployed)
//
// For the local demo we instead run `local.js` (a plain Express server) — it is
// simpler and more reliable for the two-phone test. Same app either way.

const { onRequest } = require('firebase-functions/v2/https');
const app = require('./src/app');

exports.api = onRequest({ region: 'us-central1' }, app);
