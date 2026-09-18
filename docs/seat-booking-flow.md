# Seat booking demo

The completed story is: a signed-in user selects a flight and seat, confirms a demo booking, and finds it in My Flights after reopening the page or signing back in.

## How it fits the existing code

- The existing React forms sign in or create an account, then update the shared user ID through the existing route outlet context. Opening authentication during seat selection keeps the selected flight and seat.
- Flight search adds a signed reference containing the provider's schedule key, flight number, carrier, departure date and airports. It expires after two hours; an expired selection needs a fresh search.
- `POST /bookings` verifies that reference, finds or creates the local flight, and saves the seat through the authenticated user's bookings association. The browser cannot choose another booking owner.
- The database enforces one booking per flight, row and column. Competing requests receive either a saved booking or a 409 seat conflict, with a link to choose another seat.
- `GET /bookings` returns only the signed-in user's bookings, including the stored flight details used by My Flights.
- Normal container startup migrates the database without running the destructive demo seeds.

## Running locally

From the backend directory, use the project's Ruby 2.7.6 environment with PostgreSQL running:

```sh
bundle exec rails db:migrate
bundle exec rails server -p 3000
```

From the companion client directory:

```sh
PORT=3001 npm start
```

Search still requires a working `OAG_API_KEY` in the backend environment. Existing login tokens may need a fresh sign-in because login and signup now use the same Rails signing secret. Keep that secret stable when deploying.

## Shared demo login

The sign-in form displays `demo@burningairlines.test` / `demo1234`. It is a regular account with no admin privileges. Create it without deleting anything using `bundle exec rails demo:setup`.

Docker startup now uses `entrypoint.sh`. With `DEMO_MODE=true`, it migrates, prepares the demo account, and clears only that account's bookings before Rails starts. A background shell loop repeats the reset every 86,400 seconds. A stopped container has no running timer; starting the container resets the demo again. This is an interval from startup, not a midnight schedule. Each app container startup resets this shared account.

Other users, their bookings, flights and aircraft remain. Freed demo seats can be booked again. Local `rails server` does not enable resets. The manual command is `bundle exec rails demo:reset`. The tasks refuse to reuse an admin account or overwrite a different account's password. Reset failures are logged; the daily loop retries at its next interval. The destructive `db:seed` task is not used.

Fly configuration enables demo mode and builds the checked-in Dockerfile instead of pulling the old image. These changes are not deployed: the backend Fly app had no machines when checked. A deployment still needs its database and environment configured, plus the client's local API URLs replaced. No Fly resources were created or deployed in this change.

Six additional backend examples verify setup, selective reset, retained data, seat reuse and startup scheduling. The shell tests use harmless stubs for Rails and sleep, so they do not wait 24 hours or reset a real database.

## Verification

- Backend: 22 passing examples covering provider responses, authentication, account isolation, saved bookings, invalid seats, expired or altered flight references, and simultaneous seat requests. These run against `burning_airlines_test`.
- Frontend: six focused tests in `src/bookingFlow.test.js` cover login, failed login, booking confirmation, conflicts, missing selections and loading My Flights. Run with `CI=true npm test -- --watchAll=false --runInBand --runTestsByPath src/bookingFlow.test.js`.
- The production client build passed. The existing starter `App.test.js` still references a missing App component and is outside this change.
- Local browser check: search, choose seat 12A, sign up without losing the selection, book, open My Flights in a fresh page, then sign out and sign back in.

## Deliberate limits

This is a portfolio booking simulation: prices and the 28-row, six-column aircraft remain simulated, and no airline ticket or payment is involved. Availability is enforced on confirmation; the seat map does not yet display occupied seats or update live. Profile content is still the existing wireframe; saved bookings are shown on the separate My Flights page. A fresh direct seat/confirmation link without its search selection offers a return to search.

Existing accounts and bookings were retained. Existing duplicate email records were not merged; new signup checks email uniqueness in the model, and login chooses the oldest matching account. A database email uniqueness constraint would require resolving those legacy duplicates first.
