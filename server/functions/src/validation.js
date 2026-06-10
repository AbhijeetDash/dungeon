'use strict';

// Small, dependency-free validators. Centralized so every route validates the
// same way and the rules are easy to point at during the defense round.

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// True only for a real calendar date in strict YYYY-MM-DD form.
// Rejects e.g. "2026-13-40" and "2026-2-3" (must be zero-padded).
function isValidDateString(value) {
  if (typeof value !== 'string' || !DATE_RE.test(value)) return false;
  const [y, m, d] = value.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return (
    dt.getUTCFullYear() === y &&
    dt.getUTCMonth() === m - 1 &&
    dt.getUTCDate() === d
  );
}

function isInteger(value) {
  return typeof value === 'number' && Number.isInteger(value);
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

module.exports = { isValidDateString, isInteger, isNonEmptyString };
