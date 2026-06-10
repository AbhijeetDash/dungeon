'use strict';

const express = require('express');
const { db } = require('../db');
const { asyncHandler } = require('../util');
const { USERS } = require('../catalog');

const router = express.Router();

// GET /users  → the hardcoded user list (powers the login/select screen)
router.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json({ users: USERS });
  })
);

// GET /users/:id/bookings  → that user's bookings, newest first
router.get(
  '/:id/bookings',
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    // Single equality filter (auto-indexed). We sort in memory to avoid needing a
    // composite index for the demo; at scale this would move to an indexed
    // orderBy + pagination (noted in the README).
    const snap = await db.collection('bookings').where('userId', '==', id).get();
    const bookings = snap.docs
      .map((d) => d.data())
      .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));

    res.json({ userId: id, bookings });
  })
);

module.exports = router;
