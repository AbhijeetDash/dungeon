'use strict';

const express = require('express');
const { db } = require('../db');
const { ApiError, asyncHandler } = require('../util');
const { VENUES } = require('../catalog');

const router = express.Router();

// Shared secret so the seed endpoint isn't world-callable. Override in the
// function's env (SEED_SECRET) for anything beyond the demo.
const SEED_SECRET = process.env.SEED_SECRET || 'quickslot-seed-2026';

// POST /admin/seed  — idempotently writes the venue catalog to Firestore.
// Header: X-Seed-Secret. Only seeds the fixed venue list (no user data), so it
// is safe to re-run.
router.post(
  '/seed',
  asyncHandler(async (req, res) => {
    if (req.header('X-Seed-Secret') !== SEED_SECRET) {
      throw new ApiError(401, 'BAD_SECRET', 'Invalid or missing X-Seed-Secret.');
    }
    const batch = db.batch();
    for (const venue of VENUES) {
      batch.set(db.collection('venues').doc(venue.id), venue);
    }
    await batch.commit();
    res.json({ seeded: VENUES.length, venues: VENUES.map((v) => v.id) });
  }),
);

module.exports = router;
