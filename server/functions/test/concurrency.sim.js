'use strict';

/**
 * Concurrency simulation — proves the no-double-booking invariant.
 *
 * We can't spin up two real phones inside a unit test, so this models Firestore's
 * OPTIMISTIC CONCURRENCY exactly the way the real engine behaves:
 *   - every document read inside a transaction records the doc's version;
 *   - at commit, if any read document's version changed, the commit is rejected
 *     and the transaction is retried;
 *   - app-level errors (SLOT_TAKEN) abort without retry.
 *
 * The booking logic below is identical in shape to src/routes/bookings.js:
 * read the deterministic slot doc, reject if booked, otherwise claim it.
 *
 * Honest caveat: this verifies the ALGORITHM. The real guarantee in production
 * comes from Firestore's own transaction engine + the live two-phone test.
 */

// ── A minimal Firestore-like store with optimistic-concurrency transactions ──
class OptimisticStore {
  constructor() {
    this.docs = new Map(); // id -> { version, data }
  }

  _read(id) {
    const e = this.docs.get(id);
    return e
      ? { exists: true, version: e.version, data: { ...e.data } }
      : { exists: false, version: 0, data: null };
  }

  _commit(reads, writes) {
    // Reject if any read doc changed since we read it (the optimistic check).
    for (const [id, observedVersion] of reads) {
      const cur = this.docs.get(id);
      const curVersion = cur ? cur.version : 0;
      if (curVersion !== observedVersion) return false; // conflict → retry
    }
    for (const [id, data] of writes) {
      const cur = this.docs.get(id);
      this.docs.set(id, { version: (cur ? cur.version : 0) + 1, data });
    }
    return true;
  }

  async runTransaction(fn, { maxAttempts = 5, onFirstRead } = {}) {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const reads = new Map();
      const writes = new Map();
      const tx = {
        get: async (id) => {
          const snap = this._read(id);
          reads.set(id, snap.version);
          // Barrier hook: on the first attempt only, used to force all racers to
          // read BEFORE anyone commits (worst-case simultaneous-tap scenario).
          if (onFirstRead && attempt === 1) await onFirstRead();
          return snap;
        },
        set: (id, data) => writes.set(id, { ...data }),
      };

      const result = await fn(tx); // throws (e.g. SLOT_TAKEN) propagate, no retry
      if (this._commit(reads, writes)) return result;
      // else: version conflict, loop to retry
    }
    throw new Error('ABORTED: too many retries');
  }
}

// Releases all waiters only once `n` of them have arrived.
function makeBarrier(n) {
  let count = 0;
  let release;
  const gate = new Promise((r) => (release = r));
  return async () => {
    if (++count >= n) release();
    await gate;
  };
}

// The booking transaction under test (mirrors bookings.js).
function book(store, slotKey, userId, onFirstRead) {
  return store.runTransaction(
    async (tx) => {
      const slot = await tx.get(slotKey);
      if (slot.exists && slot.data.status === 'booked') {
        const e = new Error('SLOT_TAKEN');
        e.code = 'SLOT_TAKEN';
        throw e;
      }
      tx.set(slotKey, { status: 'booked', userId });
      return { userId };
    },
    { onFirstRead }
  );
}

function cancel(store, slotKey) {
  return store.runTransaction(async (tx) => {
    const slot = await tx.get(slotKey);
    if (slot.exists) tx.set(slotKey, { status: 'available', userId: null });
  });
}

// ────────────────────────────── scenarios ──────────────────────────────
let failures = 0;
function check(name, condition, detail) {
  const ok = !!condition;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  — ${detail}` : ''}`);
  if (!ok) failures++;
}

async function scenarioSameSlot(n) {
  const store = new OptimisticStore();
  const barrier = makeBarrier(n);
  const results = await Promise.allSettled(
    Array.from({ length: n }, (_, i) => book(store, 'venue_2026-06-11_18', `u${i}`, barrier))
  );
  const wins = results.filter((r) => r.status === 'fulfilled').length;
  const taken = results.filter(
    (r) => r.status === 'rejected' && r.reason.code === 'SLOT_TAKEN'
  ).length;
  check(
    `${n} users tap the SAME slot simultaneously → exactly 1 wins`,
    wins === 1 && taken === n - 1,
    `${wins} success, ${taken} rejected`
  );
}

async function scenarioDifferentSlots(n) {
  const store = new OptimisticStore();
  const barrier = makeBarrier(n);
  const results = await Promise.allSettled(
    Array.from({ length: n }, (_, i) => book(store, `venue_2026-06-11_${i}`, `u${i}`, barrier))
  );
  const wins = results.filter((r) => r.status === 'fulfilled').length;
  check(`${n} users book DIFFERENT slots simultaneously → all ${n} succeed`, wins === n, `${wins} success`);
}

async function scenarioCancelRebook() {
  const store = new OptimisticStore();
  const slot = 'venue_2026-06-11_09';
  await book(store, slot, 'u1');
  await cancel(store, slot);
  let rebooked = false;
  try {
    await book(store, slot, 'u2');
    rebooked = true;
  } catch (_) {
    rebooked = false;
  }
  const owner = store._read(slot).data.userId;
  check('cancel frees the slot → another user can rebook it', rebooked && owner === 'u2', `owner=${owner}`);
}

(async () => {
  console.log('QuickSlot — concurrency simulation\n');
  await scenarioSameSlot(2); // the exact judge test: two phones
  await scenarioSameSlot(50); // stress
  await scenarioDifferentSlots(16); // a full day of slots, no false contention
  await scenarioCancelRebook();
  console.log(`\n${failures === 0 ? 'ALL PASSED ✅' : `${failures} FAILED ❌`}`);
  process.exit(failures === 0 ? 0 : 1);
})();
