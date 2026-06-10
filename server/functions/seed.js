'use strict';

// Seeds venues into Firestore (the emulator, when run locally).
// Idempotent: venue docs use their `id` as the document id, so re-running just
// overwrites them. Run with:  npm run seed   (emulator must be running)

const { db } = require('./src/db');
const { VENUES } = require('./src/catalog');

async function seed() {
  const batch = db.batch();
  for (const venue of VENUES) {
    batch.set(db.collection('venues').doc(venue.id), venue);
  }
  await batch.commit();
  console.log(`Seeded ${VENUES.length} venues:`);
  VENUES.forEach((v) => console.log(`  • ${v.emoji}  ${v.name} (${v.id})`));
  console.log('\nDone. Slots are generated on the fly — nothing else to seed.');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Seed failed:', err);
    console.error('\nIs the Firestore emulator running?  firebase emulators:start');
    process.exit(1);
  });
