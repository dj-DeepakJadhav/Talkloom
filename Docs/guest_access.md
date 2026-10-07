# Guest access and optional accounts

Talkloom opens without requiring registration. Bootstrap restores the persisted
Serverpod session; if none exists, it creates a unique anonymous identity and
persists its credentials with FlutterAuthSessionManager. Guests can import,
read vocabulary/grammar, speak and practice through the same owner-scoped APIs.
The Account/sign-in entry remains optional.

The account screen uses a compact, mobile-first card (420 px maximum width),
sign-in/create-account tabs, and a secondary Back to learning action. Keep
copy short, keep form controls together, and avoid a prominent guest onboarding
banner for someone who already has a guest session. Registration uses a shorter
form height than password/verification screens; the page scrolls with the keyboard.

Guest identity is local to this browser/device. Clearing its credentials loses
access to that guest's private data; creating an account adds recoverable access
across devices. Guests are never assigned a shared user ID.

If bootstrap cannot connect, the recovery screen offers Continue as guest and
retry. Registration is not required to recover. Existing auth validation restores
or refreshes stored sessions before protected content loads.

## Conversion

Email sign-in or registration happens in a separate client with memory-only
credential storage. The main client's persisted guest credentials stay intact.
The upgrade endpoint verifies the guest's authenticated session and the new
account's access token, checks that the destination has an email identity, then
uses Serverpod's transactional account merger. No caller-supplied user ID is
trusted. Anonymous callers and invalid account proof are rejected.

The application merge hook transfers sources (including archived cache rows),
lessons and evidence. It combines vocabulary progress by language and retains
the destination's grammar values on conflicts. The auth module merges its own
profiles/tokens and removes the old guest identity. The frontend persists the
account credentials only after successful conversion and refreshes its lists.
If conversion fails, it offers retry and keeps the guest credentials.

Serverpod 4's anonymous provider is experimental and currently requires merging
instead of account linking. References:
https://docs.serverpod.dev/concepts/authentication/providers/anonymous/setup
https://docs.serverpod.dev/concepts/authentication/working-with-users#merging-accounts

No application schema change is required: the existing auth module migration
already contains the anonymous-account table. Production deployment should use
the provider's attestation hook and appropriate ingestion rate limits.

## Verification (7 October 2026)

Integration tests cover native anonymous-to-email auth merging with signed token
proof, rejection of forged proof and unauthenticated conversion, source/lesson/
evidence ownership transfer, and vocabulary-progress union. Live API checks
confirm unique guest IDs, guest access to source/lesson lists, and rejection of
requests with no session. Flutter routing/content tests and release Web builds
pass. Email verification UI and Android/iOS device flows still need manual testing.
Run the server suite with `dart test --concurrency=1`: concurrent runs can contend
for the shared embedded test PostgreSQL startup.

## Import progress

URL imports poll `getImportStatus` every two seconds. The status endpoint checks
the authenticated owner's normalized URL and import start time. It reports
reading before a source is saved, retrieved when the transcript is persisted,
ready when a lesson is attached, and failed when unsuccessful compilation archives
the source. These are server-backed states, not simulated progress percentages.
If the original request times out after 90 seconds, the client polls for up to
another 90 seconds and opens the saved lesson if it finishes. It then stops with
a clear message; a client timeout does not cancel backend work. Integration and
widget tests cover owner isolation and visible stage updates.

Source details with no lesson offer Prepare my lesson and periodically check for
completion. URL retries reuse a genuine saved transcript independently of CEFR
level or lesson completeness. Incomplete lessons still require AI preparation;
having a saved transcript alone must not be presented as a finished lesson.

Import completion is driven by both the original response and polled terminal
status. A ready status fetches the lesson immediately; a failed status ends the
wait immediately. The popup stays open on success and displays the actual saved
vocabulary and grammar in tabs, with an explicit Open my content action. Failures
appear near the top of the popup. Opening a fresh Add sheet clears a previous
completed result. Widget regression coverage includes retrieved, failure, success,
and switching to the saved grammar data.
