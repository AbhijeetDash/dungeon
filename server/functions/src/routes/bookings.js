'use strict';

const express = require('express');
const { db } = require('../db');
const { ApiError, asyncHandler } = require('../util');
const { verifyFirebaseToken } = require('../auth');
const { isValidDateString, isInteger } = require('../validation');
const { slotId, isBookableHour } = require('../slots');

const router = express.Router();

// POST /bookings   (auth required)
// Body: { venueId, date: "YYYY-MM-DD", hour: <int> }
//
// ───────────────────── CONCURRENCY: THE ONE HARD RULE ─────────────────────
// A slot can never be double-booked. We guarantee this with a Firestore
// transaction keyed on a DETERMINISTIC slot document: slots/{venueId}_{date}_{hour}.
// Inside runTransaction we READ that exact document; Firestore gives the
// transaction an optimistic lock on it, so when two devices book the same slot
// at once, one commits and the other is retried — on retry it sees status
// 'booked' and we return 409. Exactly one wins.
router.post(
  '/',
  verifyFirebaseToken,
  asyncHandler(async (req, res) => {
    const userId = req.user.uid; // from the verified Firebase token
    const { venueId, date, hour } = req.body || {};

    // ---- Validation (→ 400) ----
    if (!venueId || typeof venueId !== 'string') {
      throw new ApiError(400, 'INVALID_VENUE', '`venueId` is required.');
    }
    if (!isValidDateString(date)) {
      throw new ApiError(400, 'INVALID_DATE', '`date` must be YYYY-MM-DD.');
    }
    if (!isInteger(hour)) {
      throw new ApiError(400, 'INVALID_HOUR', '`hour` must be an integer.');
    }

    // Venue must exist (→ 404). Read outside the transaction — nothing to lock.
    const venueSnap = await db.collection('venues').doc(venueId).get();
    if (!venueSnap.exists) {
      throw new ApiError(404, 'VENUE_NOT_FOUND', `No venue with id ${venueId}.`);
    }
    if (!isBookableHour(venueSnap.data(), hour)) {
      throw new ApiError(
        400,
        'HOUR_OUT_OF_RANGE',
        `Hour ${hour} is outside this venue's opening hours.`,
      );
    }

    const id = slotId(venueId, date, hour);
    const slotRef = db.collection('slots').doc(id);
    const bookingRef = db.collection('bookings').doc(); // auto-id
    const createdAt = new Date().toISOString();

    try {
      const booking = await db.runTransaction(async (tx) => {
        const slotDoc = await tx.get(slotRef); // the lock point

        if (slotDoc.exists && slotDoc.data().status === 'booked') {
          throw new ApiError(
            409,
            'SLOT_TAKEN',
            'Sorry, this slot was just booked by someone else.',
          );
        }

        const bookingData = {
          id: bookingRef.id,
          userId,
          venueId,
          date,
          hour,
          slotId: id,
          status: 'active',
          createdAt,
        };

        tx.set(
          slotRef,
          {
            venueId,
            date,
            hour,
            venueDate: `${venueId}_${date}`,
            status: 'booked',
            userId,
            bookingId: bookingRef.id,
            updatedAt: createdAt,
          },
          { merge: true },
        );
        tx.set(bookingRef, bookingData);
        return bookingData;
      });

      return res.status(201).json(booking);
    } catch (err) {
      if (err instanceof ApiError) throw err;
      throw new ApiError(500, 'BOOKING_FAILED', 'Could not complete booking.');
    }
  }),
);

// DELETE /bookings/:id   (auth required) — cancel + free the slot for rebooking.
router.delete(
  '/:id',
  verifyFirebaseToken,
  asyncHandler(async (req, res) => {
    const userId = req.user.uid;
    const { id } = req.params;
    const bookingRef = db.collection('bookings').doc(id);

    await db.runTransaction(async (tx) => {
      const bookingDoc = await tx.get(bookingRef);
      if (!bookingDoc.exists) {
        throw new ApiError(404, 'BOOKING_NOT_FOUND', `No booking with id ${id}.`);
      }
      const booking = bookingDoc.data();
      if (booking.userId !== userId) {
        throw new ApiError(403, 'NOT_OWNER', 'You can only cancel your own bookings.');
      }
      if (booking.status === 'cancelled') return; // idempotent

      const cancelledAt = new Date().toISOString();
      tx.update(bookingRef, { status: 'cancelled', cancelledAt });
      const slotRef = db.collection('slots').doc(booking.slotId);
      tx.set(
        slotRef,
        { status: 'available', userId: null, bookingId: null, updatedAt: cancelledAt },
        { merge: true },
      );
    });

    res.json({ id, status: 'cancelled' });
  }),
);

module.exports = router;
