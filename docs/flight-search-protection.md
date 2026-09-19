# Flight search protection

Flight search stays public for the portfolio demo. Protection is enforced in Rails before contacting OAG:

- Five valid searches per client IP per rolling minute, including cache hits. On Fly, the app uses the proxy's `Fly-Client-IP` header instead of trusting a visitor's `X-Forwarded-For` value.
- Identical route/date searches share a PostgreSQL cache for 15 minutes. Prices and signed booking references are generated when returning the results, so cached results do not reuse expired booking references.
- Concurrent matching searches reserve one provider request; other callers receive `429` while it is pending. Failed attempts have a one-minute cooldown.
- `OAG_DAILY_LIMIT=10` caps outgoing calls over the last 24 hours. `OAG_30_DAY_LIMIT=50` caps them over the last 30 days, across all clients and app instances. These are conservative application limits, not a statement of the OAG subscription allowance.
- Reservations commit before the HTTP request. Failures consume allowance and automatic HTTP retries are disabled. PostgreSQL row locking prevents concurrent requests exceeding the cap; restarts and demo booking resets do not clear the record.
- Invalid airport codes, identical airports, malformed dates and dates outside today through the next 365 days are rejected without contacting OAG. Provider responses are requested with a limit of 10 flights.

Limits return `429` with a `Retry-After` header. If the database cannot enforce the guard, search returns `503` without contacting OAG. Setting either provider limit to `0` stops new provider calls while still allowing valid cached results. Changing Fly environment values requires deployment.

The record is `FlightSearchGuard` ID 1. Do not delete or reset it to resolve a rate-limit response. Request timestamps start when this protection is installed; they do not account for earlier OAG usage or calls from other applications using the same key. Review the OAG portal's remaining allowance before raising the caps.

These controls bound OAG usage through this application. They do not prevent every denial-of-service attempt or protect a key that has been copied and used directly against OAG. Keep the key in Fly secrets and rotate it if exposed.
