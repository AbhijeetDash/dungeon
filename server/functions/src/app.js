'use strict';

const express = require('express');
const cors = require('cors');

const venuesRoutes = require('./routes/venues');
const usersRoutes = require('./routes/users');
const bookingsRoutes = require('./routes/bookings');
const adminRoutes = require('./routes/admin');
const { ApiError } = require('./util');

// Builds the Express app. Exported as a factory-free singleton so BOTH entry
// points (Cloud Function in index.js, standalone server in local.js) share the
// exact same app and middleware.
const app = express();

app.use(cors()); // open CORS — fine for a local hackathon demo
app.use(express.json());

// Lightweight request log so you can see the two-phone race happening live.
app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()}  ${req.method} ${req.originalUrl}`);
  next();
});

app.get('/health', (_req, res) => res.json({ ok: true, service: 'quickslot' }));

app.use('/venues', venuesRoutes);
app.use('/users', usersRoutes);
app.use('/bookings', bookingsRoutes);
app.use('/admin', adminRoutes);

// 404 for unknown routes.
app.use((_req, res) => {
  res.status(404).json({ error: 'NOT_FOUND', message: 'Route not found.' });
});

// Central error handler: turns ApiError into its status/code, everything else
// into a 500. Single place that owns the error→HTTP mapping.
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err instanceof ApiError) {
    return res.status(err.status).json({ error: err.code, message: err.message });
  }
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'INTERNAL', message: 'Something went wrong.' });
});

module.exports = app;
