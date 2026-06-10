'use strict';

// Firestore initialization — supports three run modes with NO code changes.
// db.js decides which based on the environment it finds itself in:
//
//   1. Local API + REAL (cloud) Firestore   ← our setup
//        Drop a service-account key at server/functions/serviceAccountKey.json
//        (or set GOOGLE_APPLICATION_CREDENTIALS to its path).
//        No emulator, no Java needed. The API process runs locally; the database
//        is real Firestore.
//   2. Deployed Cloud Function
//        The Functions runtime injects credentials automatically — nothing to do.
//   3. Local API + Firestore EMULATOR (fallback, if you ever get it downloaded)
//        Run with USE_EMULATOR=1 (or set FIRESTORE_EMULATOR_HOST).
//
// All three run the exact same routes/transactions; only the credentials and
// endpoint differ. This is why our concurrency + API code never has to care.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const isCloudFunctions = !!process.env.FUNCTION_TARGET || !!process.env.K_SERVICE;

// Resolve a service-account key for local runs. Order of preference:
//   1. GOOGLE_APPLICATION_CREDENTIALS (an explicit path), else
//   2. server/functions/serviceAccountKey.json (conventional name), else
//   3. any *-firebase-adminsdk-*.json dropped into functions/ or server/.
// (3) lets you just drop the file Firebase downloads — no renaming required.
function resolveKeyPath() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return process.env.GOOGLE_APPLICATION_CREDENTIALS;
  }
  const conventional = path.join(__dirname, '..', 'serviceAccountKey.json');
  if (fs.existsSync(conventional)) return conventional;
  const searchDirs = [path.join(__dirname, '..'), path.join(__dirname, '..', '..')];
  for (const dir of searchDirs) {
    try {
      const hit = fs
        .readdirSync(dir)
        .find((f) => /firebase-adminsdk.*\.json$/i.test(f));
      if (hit) return path.join(dir, hit);
    } catch (_) {
      /* directory may not exist — ignore */
    }
  }
  return conventional; // default (may not exist)
}

const keyPath = isCloudFunctions ? null : resolveKeyPath();
const hasKey = !isCloudFunctions && !!keyPath && fs.existsSync(keyPath);

const useEmulator =
  !isCloudFunctions &&
  !hasKey &&
  (!!process.env.USE_EMULATOR || !!process.env.FIRESTORE_EMULATOR_HOST);

if (hasKey) {
  // Guard: a stray FIRESTORE_EMULATOR_HOST in the shell would otherwise hijack
  // the connection and send our real-Firestore traffic to a (dead) emulator.
  delete process.env.FIRESTORE_EMULATOR_HOST;
} else if (useEmulator) {
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
  process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-quickslot';
}

if (!admin.apps.length) {
  if (hasKey) {
    const serviceAccount = require(keyPath);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    console.log(
      `Firestore: REAL project "${serviceAccount.project_id}" (service-account key)`
    );
  } else if (useEmulator) {
    admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
    console.log(`Firestore: EMULATOR at ${process.env.FIRESTORE_EMULATOR_HOST}`);
  } else {
    // Cloud Functions runtime, or Application Default Credentials.
    admin.initializeApp();
    console.log('Firestore: default credentials (Cloud Functions / ADC)');
  }
}

const db = admin.firestore();

module.exports = { admin, db };
