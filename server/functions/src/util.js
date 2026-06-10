'use strict';

// A typed error carrying the HTTP status + a stable machine-readable code.
// Routes throw these; the error middleware (app.js) maps them to responses.
class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

// Wraps an async route handler so thrown/rejected errors reach Express's error
// middleware instead of crashing the process.
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { ApiError, asyncHandler };
