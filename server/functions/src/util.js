'use strict';

const { USERS } = require('./catalog');

// A typed error that carries the HTTP status + a stable machine-readable code.
// Routes throw these; the error middleware (in app.js) turns them into responses.
class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

// Wraps an async route handler so any thrown/rejected error is forwarded to the
// Express error middleware instead of crashing the process. Keeps routes clean:
// they can just `throw new ApiError(...)`.
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Light auth, per the brief: a hardcoded set of users + an `X-User-Id` header.
// Returns the validated user id, or throws 401 if missing/unknown.
function requireUserId(req) {
  const userId = req.header('X-User-Id');
  if (!userId) {
    throw new ApiError(401, 'NO_USER', 'Missing X-User-Id header.');
  }
  if (!USERS.some((u) => u.id === userId)) {
    throw new ApiError(401, 'UNKNOWN_USER', `Unknown user: ${userId}`);
  }
  return userId;
}

module.exports = { ApiError, asyncHandler, requireUserId };
