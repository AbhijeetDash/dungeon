'use strict';

// Seed venues. `openHour`/`closeHour` drive slot generation (6 AM–10 PM here).
// Written to Firestore by seed.js; venue docs use `id` as the document id.
// (Users now come from Firebase Auth — there is no hardcoded user list.)
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

module.exports = { VENUES };
