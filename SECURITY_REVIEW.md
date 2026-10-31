# Security review — 2026-11-01

## Confirmed findings fixed

| Severity | Finding | Change |
| --- | --- | --- |
| Critical | Login accepted omitted passwords and hardcoded override passwords. | Password is required and bcrypt must match. |
| Critical | Public owner registration issued admin tokens. | Existing authenticated admin authorization is required. Bootstrap the first admin through trusted administration. |
| Critical | Several admin and driver routes used optional authentication. | Authentication and the appropriate role now run before every route in these routers. |
| High | Drivers could update another driver's order and skip workflow states. | Updates require the assigned driver and the expected previous status. |
| High | Any authenticated socket could subscribe to any order or spoof driver events. | Order membership is checked in the database; driver events require the driver role, assignment, and valid coordinates. |
| High | Predictable fallback JWT signing secret allowed token forgery. | Startup requires a JWT_SECRET of at least 32 characters. |
| High | App authentication failures created fake authenticated customer and owner sessions. Driver login ignored OTP and used shared credentials. | Customer and owner errors propagate. Driver phone onboarding is disabled pending secure OTP integration. |
| High | Static OTP codes could verify arbitrary phone numbers. | Backend and customer verification fail explicitly until a secure provider is integrated. |
| High | PostgreSQL TLS certificate verification was disabled. | Certificate verification is enabled. |
| Medium | Health and unexpected error responses could disclose internal errors. | Health failures and unexpected production errors return generic messages. |

## Operational impact

- Configure a randomly generated JWT_SECRET with at least 32 characters before starting the backend. Rotate the old secret and have users sign in again.
- Phone verification and driver phone login/registration intentionally remain unavailable until an OTP provider with expiring, phone-bound challenges and attempt limits is implemented.
- Owner self-registration now needs an authenticated admin. The current unauthenticated owner registration UI will receive an authorization error.
- Database hosts must present a valid TLS certificate.

## Verification

- Five regression tests pass: omitted password, both former override passwords, valid password, static OTP rejection, and assigned-driver status update constraints.
- Backend JavaScript syntax checks passed.
- Dart analysis passed for the modified customer, driver, and owner authentication services.
- Tests use a mocked database; live database, device, and deployed end-to-end testing were not performed.

## Remaining work and review limits

This is a focused source review, not a complete penetration test.
Several non-authentication app methods still catch API failures and return local or sample data. These need a separate flow review so failed operations cannot appear successful.
Review login rate limiting, password policy, session revocation, token expiry on active socket connections, and atomic shipment/dispatch/payment updates before production deployment.
Existing seed accounts use known demo credentials; reset or remove them in any deployed database.
Previously issued admin accounts should be audited because public owner registration was formerly enabled.
