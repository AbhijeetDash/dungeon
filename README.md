# QuickSlot

A mini app for booking sports slots (badminton courts, turf grounds, tennis). Users sign in, browse venues, pick a date, view that day's hourly slots, and book one. **The one hard rule: a slot can never be double-booked** — if two people tap "Book" on the same slot at the same instant, exactly one succeeds and the other gets a clear in-app message and a refreshed grid.

> Repo note: the project was scaffolded as `dungeon`, so the Dart package, the Android `namespace`, and the on-device display name still read "dungeon/Dungeon". The product is **QuickSlot** (store name, bundle id `com.abhijeet.quickslot`). Renaming the package was deliberately deferred — see "What we'd do with one more day".

---

## Architecture at a glance

```
Flutter app  ──HTTPS (dio)──►  Express REST API  ──Admin SDK──►  Cloud Firestore
(BLoC, dio,                    (Cloud Function:                  (venues, slots,
 Firebase Auth)                 api-oupv7skwsa-uc.a.run.app)      bookings)
     │                                  ▲
     └──── Firebase ID token (Bearer) ──┘  verified server-side (verifyIdToken)
```

- **Backend** — an Express app deployed as a single 2nd-gen Cloud Function (`api`), backed by **Cloud Firestore**. The same Express app can also run locally (`node local.js`) against the emulator or real Firestore; we deployed it so devices hit one public HTTPS URL.
- **Client** — Flutter, **BLoC** for state, **dio** for networking (with an interceptor pipeline), **Firebase Auth** (email/password + Google) for identity.
- **Persistence** — Firestore. Venues are seeded; **slots are virtual** (generated 6 AM–10 PM hourly from each venue's opening hours), so we never pre-seed future dates. Only bookings (and a per-slot occupancy doc) are stored.

### The concurrency guarantee (the graded core)

Booking runs inside a Firestore **transaction keyed on a deterministic slot document**: `slots/{venueId}_{date}_{hour}`.

1. The transaction `get`s that exact document.
2. If it exists with `status == 'booked'` → throw → API returns **409 `SLOT_TAKEN`**.
3. Otherwise it atomically writes the slot doc (`booked`) **and** the booking doc.

Firestore gives the transaction an **optimistic lock** on every document it reads. When two devices book the same slot at once, both read it as free, one commits first (the slot doc's version bumps), and the second commit is rejected and auto-retried — on retry it reads `booked` and returns 409. **Exactly one winner, no row locks, no race window.** The loser's app shows "That slot was just booked by someone else" and refreshes the grid.

Verified two ways: a deterministic simulation (`server/functions/test/concurrency.sim.js`, run via `npm run test:concurrency`) that races 2 and 50 callers on one slot and asserts exactly one success, and the live two-device test.

### Security

- **All** database access goes through the backend's Admin SDK, which **bypasses** Firestore rules. So `firestore.rules` is a hard **deny-all** for any direct client SDK access — the database is reachable only through the validated, transactional API (least privilege).
- The API verifies the **Firebase ID token** (`Authorization: Bearer …`) with `admin.auth().verifyIdToken()` and derives the user from it — a client can't forge a user via a header.
- Booking/cancel are server-only **by design**: even with auth, a client write couldn't run the cross-document transaction safely.

### State management — why BLoC (and a Cubit/Bloc split)

The brief asks us to justify this. We used the **bloc** family and split intentionally:

- **Cubit** for features that are simple fetch-then-render or hold one value: `AuthCubit`, `VenuesCubit`, `BookingCubit`, `MyBookingsCubit`. Less boilerplate where there are no meaningful discrete events.
- **Bloc** (events/states) for **slots**, which has genuinely distinct events worth modelling: load, change date, change time-of-day filter, select a slot, and **refresh-after-conflict**. Event-driven traceability earns its keep here.

No business logic lives in widgets — screens dispatch events / call cubit methods and render state. Derived view data (filtered venues, slots grouped by time-of-day, upcoming vs past bookings) is computed in the state objects, not the UI.

---

## Repo structure

```
/ (Flutter app at repo root)
  lib/
    core/            theme, app config (base URL), dio ApiClient, interceptors/
    data/            models (json_serializable), repositories
    logic/           auth, venues, slots, booking, my_bookings (BLoC/Cubit)
    presentation/    screens + widgets
  test/              unit tests (slot/booking/date logic)
  ios/ android/      native (FlutterFire config, signing)
/server
  firebase.json, firestore.rules, firestore.indexes.json
  functions/
    index.js         Cloud Function entry (onRequest(app))
    local.js         standalone local runner
    seed.js          seeds venues
    src/             app.js, db.js, auth.js, slots.js, validation.js, catalog.js, routes/
    test/concurrency.sim.js
```

---

## Run it

### App (points at the deployed API by default — no flags needed)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart
flutter run            # uses https://api-oupv7skwsa-uc.a.run.app
```

The base URL is hardcoded as the default in `lib/core/app_config.dart`, overridable for local dev:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8081
```

Log in with **email/password** (works everywhere) or **Google**.

### Backend (already deployed; to run locally)

```bash
cd server/functions && npm install
# real Firestore via a service-account key in server/functions/ (auto-detected), then:
npm run dev            # http://localhost:8081
npm run seed           # seed the 4 venues
npm run test:concurrency
```

Seed the deployed DB over HTTP (guarded by a shared secret):

```bash
curl -X POST https://api-oupv7skwsa-uc.a.run.app/admin/seed -H "X-Seed-Secret: quickslot-seed-2026"
```

---

## API

| Method | Endpoint | Auth | Returns |
|---|---|---|---|
| GET | `/venues` | public | list of venues |
| GET | `/venues/:id/slots?date=YYYY-MM-DD` | public | the day's slot grid with status |
| POST | `/bookings` `{venueId,date,hour}` | Bearer | **201** booked · **409** `SLOT_TAKEN` · **400** invalid · **404** no venue |
| GET | `/users/:id/bookings` | Bearer | that user's bookings (owner-checked) |
| DELETE | `/bookings/:id` | Bearer | cancel + free the slot (**403** if not owner, **404** if missing) |
| POST | `/admin/seed` | secret header | seed venues (demo convenience) |

Status codes: `201/200` success · `400` validation · `401` missing/invalid token · `403` not owner · `404` not found · `409` slot taken.

---

## Networking: the dio interceptor pipeline

1. **AuthInterceptor** — attaches the fresh Firebase ID token as `Bearer`.
2. **RequestValidationInterceptor** — validates outgoing request shape (auth present, body well-formed) and fails fast, no wasted round-trip.
3. **ResponseValidationInterceptor** — validates each 2xx body against the API contract; surfaces a clean `BAD_RESPONSE` instead of a deep null-cast.
4. **DevLogInterceptor** — compact `→ / ← / ✖` console logs (debug builds only) — you can watch the 409 race live.

All failures normalize to a single `ApiException`, so repositories and Blocs only ever handle one error type.

---

## What we cut, and why

- **Firestore emulator** — wouldn't download on our network during the event. Switched to **real cloud Firestore** + a deployed function. Trade-off: the demo needs internet; upside: the concurrency guarantee runs on *production* Firestore.
- **`google_sign_in` package** — version churn (ecosystem on v7) and native config. Replaced with `FirebaseAuth.signInWithProvider(GoogleAuthProvider())` — one fewer dependency.
- **Desktop & web platforms** — mobile-only (Android + iOS) to match the role and shrink surface area.
- **Bonus: live slot updates (polling/websocket)** — not attempted; left as the top item for "one more day".
- **Bonus we kept: filter slots by time of day** — implemented as the Morning/Afternoon/Evening grouped sections + filter chips.
- **Composite indexes / pagination** — queries use single-field filters and sort in memory; fine at demo scale.

We also went **beyond** the brief's "keep auth light": real Firebase Auth (email/password + Google) with server-side token verification, because identity is the natural key for bookings and it's a stronger story than a hardcoded header.

---

## What we'd do with one more day

1. **Live slot updates** — Firestore snapshot listener (or polling) so a slot flips to "booked" on other phones without a manual refresh.
2. **Indexing + pagination** — proper composite indexes for slots/bookings, server-side date filtering.
3. **Harden the seed path** — remove `/admin/seed` (or gate it behind admin auth) and seed via CI.
4. **Offline read cache** for My Bookings.
5. **More tests** — widget tests for the slot grid, an integration test of the full booking flow.
6. **Clean rename** of the package/namespace/display name from `dungeon` → `quickslot`, and **Sign in with Apple** for App Store Guideline 4.8.
7. **Release-key management** in CI rather than a local keystore.

---

## AI usage note

We used AI as a pair-programmer throughout: scaffolding the Express API and the Firestore transaction, writing the dio interceptors and the json_serializable models, generating the BLoC layer and all the screens to match our design mockups, and — heavily — debugging the iOS/Android deployment chain (CocoaPods, signing, FlutterFire).

**One thing it got wrong that we caught and fixed:** the AI's first `pubspec.yaml` pinned package versions from its training cutoff (`firebase_core ^3.x`, `firebase_auth ^5.x`, `google_sign_in ^6.x`). `flutter pub get` failed outright — the ecosystem had moved to `firebase_core 4.x` / `firebase_auth 6.x`. We caught it on the first resolve, pulled the current versions from pub.dev, and took the opportunity to drop `google_sign_in` for the native `signInWithProvider` flow.

**A second one worth noting:** the API base URL originally defaulted to `http://localhost:8081`. The first TestFlight build silently pointed at the phone itself and wouldn't connect. We caught it on-device and hardcoded the deployed Cloud Function URL as the default (still overridable via `--dart-define`). Lesson reinforced: release builds never see `--dart-define` unless you pass it.

---

## Build log (hour by hour)

Scheduled build window 09:30–15:30, plus ~40 min over.

- **Hour 1 (09:30–10:30) — Scoping + backend core.** Picked the stack (Firebase end-to-end, BLoC, time-of-day filter as the bonus). Built the Express REST API with the **Firestore-transaction concurrency** model and **deny-all security rules**; verified no-double-booking with a concurrency simulation. *Commit: `feat(server): REST API + Firestore-transaction concurrency + deny-all rules`.*
- **Hour 2 (10:30–11:30) — Networking foundation.** Flutter theme, models, repositories; moved the API client to **dio** with request/response-validation + dev-log interceptors; added **json_serializable** models. Switched from the (un-downloadable) emulator to **real Firestore** via a service-account key. *Commits: dio refactor, models.*
- **Hour 3 (11:30–12:30) — State layer.** Built the BLoC/Cubit layer: session/auth, venues, slots (full Bloc), booking, my-bookings — with derived state and no logic in widgets. *Commit: `feat(app): BLoC layer`.*
- **Hour 4 (12:30–13:30) — UI.** All screens to match the mockups: login, venue list (search + category chips), venue detail (date strip + Morning/Afternoon/Evening grid + filter), booking → confirmation, My Bookings + cancel, profile — with loading/error/empty states throughout; `main.dart` wiring.
- **Hour 5 (13:30–14:30) — Auth end-to-end + dependency fixes.** Real **Firebase Auth** (email/password + Google via `signInWithProvider`): backend **ID-token verification** replacing the light header auth, client auth repo + auth interceptor + `AuthCubit`. Resolved the package-version conflicts and ran `flutterfire configure`.
- **Hour 6 (14:30–15:30) — Integration + deploy.** Layered commits; first device run. Fixed iOS deployment target (→15.0 for `firebase_auth`), CocoaPods `--repo-update`, a white-on-white text-theme bug, and a blank venue-detail screen (restructured the body to a single `ListView`). Deployed the Cloud Function; seeded Firestore.

### +40 min (15:30–16:10) — Testing, deployment & bug-fixes

- App Store Connect + Play setup: changed the package from `com.example.dungeon` (banned by both stores) to **`com.abhijeet.quickslot`**, resolved a duplicate App Store **name** clash.
- **Android release signing** — wired an upload keystore via `key.properties` (Play rejected the debug-signed AAB).
- **TestFlight wouldn't connect** — root-caused to the `localhost` base-URL default; hardcoded the deployed URL.
- **iOS Google sign-in crash** — `Info.plist` `REVERSED_CLIENT_ID` was stale after the bundle-id change; synced it to the current `GoogleService-Info.plist`.
- SHA fingerprints from Play App Signing added to Firebase (Google sign-in on Play builds); build-number bumps for re-uploads (`1.0.0+3`).

---

## Tech stack

Flutter 3.38 / Dart 3.10 · flutter_bloc 9 · dio 5.9 · json_serializable 6.13 · firebase_core 4.8 / firebase_auth 6.5 · Node 20 / Express 4 · firebase-admin 12 · Cloud Functions (2nd gen) + Cloud Firestore.
