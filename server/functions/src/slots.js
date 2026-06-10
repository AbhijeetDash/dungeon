'use strict';

// Slot logic is PURE and lives here on its own so it is trivial to reason about
// and unit-test. Slots are not stored as rows — they are generated on demand for
// a (venue, date) from the venue's opening hours. Only BOOKINGS are persisted.
// This means we never have to pre-seed an infinite number of future dates.

const DEFAULT_OPEN_HOUR = 6; // 6 AM
const DEFAULT_CLOSE_HOUR = 22; // 10 PM (last bookable slot is 21:00–22:00)

function pad(n) {
  return String(n).padStart(2, '0');
}

// "06:00 - 07:00"
function slotLabel(hour) {
  return `${pad(hour)}:00 - ${pad(hour + 1)}:00`;
}

// Used by the "filter by time of day" feature on the client.
function classifyTimeOfDay(hour) {
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}

// Deterministic id that uniquely identifies a physical slot. This is the key to
// our concurrency guarantee: the booking transaction reads/writes THIS exact
// document, so Firestore's optimistic lock applies to it.
function slotId(venueId, date, hour) {
  return `${venueId}_${date}_${hour}`;
}

// Build the full grid of slots for a venue/date, marking which are booked.
// `bookedHours` is a Set<number> of hours that currently have an active booking.
function buildSlots(venue, date, bookedHours) {
  const open = venue.openHour ?? DEFAULT_OPEN_HOUR;
  const close = venue.closeHour ?? DEFAULT_CLOSE_HOUR;
  const slots = [];
  for (let hour = open; hour < close; hour++) {
    slots.push({
      id: slotId(venue.id, date, hour),
      venueId: venue.id,
      date,
      hour,
      label: slotLabel(hour),
      timeOfDay: classifyTimeOfDay(hour),
      status: bookedHours.has(hour) ? 'booked' : 'available',
    });
  }
  return slots;
}

// Whether a given hour is a valid bookable slot for a venue.
function isBookableHour(venue, hour) {
  const open = venue.openHour ?? DEFAULT_OPEN_HOUR;
  const close = venue.closeHour ?? DEFAULT_CLOSE_HOUR;
  return Number.isInteger(hour) && hour >= open && hour < close;
}

module.exports = {
  DEFAULT_OPEN_HOUR,
  DEFAULT_CLOSE_HOUR,
  slotLabel,
  classifyTimeOfDay,
  slotId,
  buildSlots,
  isBookableHour,
};
