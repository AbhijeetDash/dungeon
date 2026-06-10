'use strict';

const { admin } = require('./db');
const { ApiError } = require('./util');

/// Express middleware: verifies the Firebase ID token sent as
/// `Authorization: Bearer <token>` and attaches the user to req.user.
///
/// This is the real auth boundary. The Admin SDK validates the token's
/// signature, issuer and audience against our Firebase project, so a client
/// cannot forge a user — unlike a plain header. The booking/cancel routes then
/// trust req.user.uid as the actor.
async function verifyFirebaseToken(req, _res, next) {
  try {
    const header = req.header('Authorization') || '';
    const match = header.match(/^Bearer (.+)$/i);
    if (!match) {
      return next(
        new ApiError(401, 'NO_TOKEN', 'Missing Authorization: Bearer <token>.'),
      );
    }
    const decoded = await admin.auth().verifyIdToken(match[1]);
    req.user = {
      uid: decoded.uid,
      email: decoded.email || null,
      name: decoded.name || decoded.email || 'User',
    };
    return next();
  } catch (_) {
    return next(
      new ApiError(401, 'INVALID_TOKEN', 'Invalid or expired authentication token.'),
    );
  }
}

module.exports = { verifyFirebaseToken };
