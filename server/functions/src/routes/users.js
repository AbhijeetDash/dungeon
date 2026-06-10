'use strict';

const express = require('express');
const { db } = require('../db');
const { ApiError, asyncHandler } = require('../util');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();

// GET /users/:id/bookings   (auth required)
// :id is the Firebase uid. We verify it matches the authenticated user so one
// user can't read another's bookings.
router.get(
  '/:id/bookings',
  verifyFirebaseToken,
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    if (req.user.uid !== id) {
      throw new ApiError(403, 'FORBIDDEN', "You can only read your own bookings.");
    }

    // Single equality filter (auto-indexed); sort in memory to avoid needing a
    // composite index for the demo.
    const snap = await db.collection('bookings').where('userId', '==', id).get();
    const bookings = snap.docs
      .map((d) => d.data())
      .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));

    res.json({ userId: id, bookings });
  }),
);

module.exports = router;
