'use strict';

const express = require('express');
const { db } = require('../db');
const { ApiError, asyncHandler } = require('../util');
const { isValidDateString } = require('../validation');
const { buildSlots } = require('../slots');

const router = express.Router();

// GET /venues  → list all venues
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const snap = await db.collection('venues').orderBy('name').get();
    const venues = snap.docs.map((d) => d.data());
    res.json({ venues });
  })
);

// GET /venues/:id/slots?date=YYYY-MM-DD  → the slot grid for that date, with status
router.get(
  '/:id/slots',
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { date } = req.query;

    if (!isValidDateString(date)) {
      throw new ApiError(
        400,
        'INVALID_DATE',
        'Query param `date` is required as YYYY-MM-DD.'
      );
    }

    const venueSnap = await db.collection('venues').doc(id).get();
    if (!venueSnap.exists) {
      throw new ApiError(404, 'VENUE_NOT_FOUND', `No venue with id ${id}.`);
    }
    const venue = venueSnap.data();

    // Slot docs only exist for slots that have been booked. We look up the booked
    // hours for this venue/date via the denormalized `venueDate` field (a single
    // equality filter → no composite index required).
    const slotSnap = await db
      .collection('slots')
      .where('venueDate', '==', `${id}_${date}`)
      .get();

    const bookedHours = new Set();
    slotSnap.forEach((doc) => {
      const s = doc.data();
      if (s.status === 'booked') bookedHours.add(s.hour);
    });

    res.json({
      venueId: id,
      date,
      slots: buildSlots(venue, date, bookedHours),
    });
  })
);

module.exports = router;
