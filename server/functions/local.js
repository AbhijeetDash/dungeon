'use strict';

// Standalone local server — the recommended way to run the API for the demo.
// Talks to the Firestore emulator (configured in src/db.js).
//
// NOTE: the Firestore emulator itself uses port 8080, so this API listens on
// 8081. We bind 0.0.0.0 so a physical phone on the same Wi-Fi can reach your Mac.

const app = require('./src/app');

const PORT = process.env.PORT || 8081;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`QuickSlot API listening on http://0.0.0.0:${PORT}`);
  console.log(`  • From the same machine:     http://localhost:${PORT}`);
  console.log(`  • From a phone on your Wi-Fi: http://<your-mac-LAN-ip>:${PORT}`);
  console.log('  • Health check:              GET /health');
});
