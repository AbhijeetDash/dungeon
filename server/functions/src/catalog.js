'use strict';

// Hardcoded users (light auth, per the brief). The client picks one of these on
// the "login" screen and sends its id in the `X-User-Id` header.
const USERS = [
  { id: 'u1', name: 'Abhijeet' },
  { id: 'u2', name: 'Riya' },
  { id: 'u3', name: 'Karan' },
  { id: 'u4', name: 'Meera' },
];

// Seed venues. `openHour`/`closeHour` drive slot generation (6 AM–10 PM here).
// These are written to Firestore by `seed.js`; venue docs use `id` as the doc id.
const VENUES = [
  {
    id: 'smashers',
    name: 'Smashers Badminton Arena',
    sport: 'Badminton',
    location: 'Indiranagar, Bengaluru',
    pricePerHour: 400,
    currency: 'INR',
    emoji: '🏸',
    openHour: 6,
    closeHour: 22,
  },
  {
    id: 'greenfield',
    name: 'Greenfield Turf',
    sport: 'Football',
    location: 'Koramangala, Bengaluru',
    pricePerHour: 1200,
    currency: 'INR',
    emoji: '⚽',
    openHour: 6,
    closeHour: 22,
  },
  {
    id: 'baseline',
    name: 'Baseline Tennis Club',
    sport: 'Tennis',
    location: 'HSR Layout, Bengaluru',
    pricePerHour: 600,
    currency: 'INR',
    emoji: '🎾',
    openHour: 6,
    closeHour: 22,
  },
  {
    id: 'centercourt',
    name: 'Center Court Badminton',
    sport: 'Badminton',
    location: 'Whitefield, Bengaluru',
    pricePerHour: 350,
    currency: 'INR',
    emoji: '🏸',
    openHour: 6,
    closeHour: 22,
  },
];

module.exports = { USERS, VENUES };
