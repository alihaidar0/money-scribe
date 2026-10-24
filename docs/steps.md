# Money Scribe — Build Steps

The build plan for **Money Scribe: Budget & Expense Tracker**, as a checklist. Each step is one topic branch and one pull request into `develop`; tick a box in the same change that completes it.

> This file is public. Keep every entry to one short line, and never add secrets, credentials, personal or financial data, account details or local machine setup.

## 1. Project setup

- [x] Choose the name: **Money Scribe**, store title **Money Scribe: Budget & Expense Tracker**
- [x] Create the repository with `develop` (default, integration) and `main` (release)
- [x] Set the repository-only git identity
- [x] Create the Flutter project for Android, iOS and web (`com.alihaidar.moneyscribe`)
- [x] Pin the dev image and the Flutter version (`scripts/pin-image.sh`)
- [x] Make the repository describe the app: README, contributing, security, forms, workflows, docs
- [x] List the app's keys in `.env.example` (names only)
- [x] Commit the scaffold and open the first pull request into `develop`
- [x] Apply the repository settings and import the rulesets ([`github-setup.md`](github-setup.md))

## 2. Quality baseline

- [x] Pre-commit hook runs every CI check (format, analyze, tests, file hygiene)
- [x] Smart checks: the commit hook runs only the tests a change can reach and skips non-Dart commits; CI skips Flutter jobs for non-Dart pull requests and splits the tests in three shards
- [x] CI runs the test shards at the same time as format and analyze, not after them
- [x] First smoke test in `test/`
- [x] Spell checker configured (`cspell.json`, shared project word list)
- [x] Strict lints in `analysis_options.yaml` (`very_good_analysis`)
- [x] Design brief for the theme and screens ([`design-brief.md`](design-brief.md))
- [x] App shell: feature-first folders (`app/`, `core/`, `features/<name>/`), Bloc and `go_router`
- [x] Material 3 theme with light and dark modes
- [x] Localization with ARB files: English and Arabic, with the language following the system and a setting
- [x] Arabic font and right-to-left layout, added to the design system and checked on every screen
- [x] State management with Bloc (`flutter_bloc`, events in every feature), documented in [`architecture.md`](architecture.md)
- [ ] Data layer base: repository interfaces with fake data sources (invented data), one feature at a time, replaced by the server later
- [ ] Immutable models (sealed classes, `json_serializable` for DTOs), added with the first model that needs it

## 3. Core features

- [x] `Money` value object: integer minor units, currency code, one place for rounding, Western digits in every language
- [x] Salary calculation: one or two payments a month, every line rounded to the kopeck (pure Dart, tests)
- [ ] Monthly salary calculator, with every month saved
- [ ] Recurring monthly income and expenses
- [ ] Transactions and purchases
- [ ] Debts: borrowed and lent, partial repayments, settled status
- [ ] Backend and sign-in, with the server as the only place the data is stored (the Django backend; steps in section 7)
- [ ] Decide on crash reporting and opt-in analytics (none until then; never amounts or personal data)
- [ ] Notifications: local reminders first (for example debts due); push messages through Firebase Cloud Messaging are tested from the Firebase console until the backend can send them

## 4. Insight and polish

- [ ] Monthly overview
- [ ] Reports: by category, month over month, debts summary
- [ ] CSV export and import that round-trips without loss
- [x] App lock: a salted hash of the PIN in secure storage, pauses and a limit on wrong PINs, the fingerprint through the system, a timeout the person chooses, and a secure window in production
- [ ] Accessibility review

## 5. Release

Done in the repository:

- [x] App name "Money Scribe" and launcher icons for Android, iOS and web (`flutter_launcher_icons`, sources in `assets/icon/`)
- [x] Staging and production flavors with their own app IDs, icons and signing keys ([`environments.md`](environments.md))
- [x] Signed builds and draft GitHub Releases for staging and production in the build workflow ([`android-signing.md`](android-signing.md))

To do, in this order, one step at a time:

- [x] Create the staging signing key and back it up
- [x] Create the `staging` GitHub environment, restricted to `develop`
- [x] Add the four staging secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`) and the variable `ANDROID_CERT_SHA256`
- [x] Untick "Allow administrators to bypass configured protection rules" on the `staging` environment
- [x] Merge the environments pull request; check the first staging build and the "Staging" draft release
- [x] Dependencies updated to the latest versions that resolve with Flutter 3.47.7 (Firebase 5.1.0 and 17.0.1, `go_router` 18.1.1, the code generators); the 13 packages held back by the SDK move with the Flutter update below
- [ ] Toolchain update, as its own pull request: a dev image with the latest stable Flutter, pin it, refresh the lock file
- [x] Create the upload signing key and back it up
- [x] Create the `production` GitHub environment, restricted to `main`, and untick "Allow administrators to bypass configured protection rules"
- [x] Add the four production secrets (same names as staging, with the upload key's values) and the variable `ANDROID_CERT_SHA256`
- [x] Open the `develop` → `main` release pull request, test its files, merge, check the signed production build and the draft release `v0.1.0` (left unpublished)
- [x] Create one Google Cloud project per environment (staging and production)
- [x] Add Firebase to both projects (Analytics off) and register the staging and production Android apps; keep `google-services.json` out of Git
- [x] Store each environment's `google-services.json` (base64) as the secret `GOOGLE_SERVICES_JSON_BASE64` of its GitHub environment
- [x] Firebase Cloud Messaging in the app, as its own pull request: flavor configuration files written by the build workflow, notification permission, push token behind a repository interface
- [ ] Google Play: developer account, app, first internal-testing upload, store listing and privacy policy
- [ ] Upload to Google Play from the build workflow (staging to an internal track, production on merge into `main`)
- [ ] iOS: flavors, signing and TestFlight (needs a Mac and an Apple Developer account)
- [ ] Optional: set the repository variable `BUILD_IOS` to `true` for the iOS compile check in CI (after the iOS flavors)
- [ ] Publish the first release (`v0.1.0` or higher) once the app has its first real features
- [ ] Register the domain and check the USPTO and WIPO trademark databases

## 6. Screens

Every screen of the design is built with fake data, checked on the emulator, and then ticked. The IDs come from the design prompts, which are kept locally; a screen with a one-payment and a two-payment version has a line for each.

### Foundations

- [x] Navigation shell: bottom bar on phones, rail on tablet and web, a route for every screen
- [x] Demo panel (staging only) to force loading, empty, error and no connection, and the payment mode
- [x] Shared screen widgets: hero card, amount row, period card, state views, code boxes
- [x] Screen render check: every screen drawn to an image in a test, in English and Arabic
- [x] Navigation test: every button leads where the design says

### A. Authentication and first start

- [x] AUTH-1 Welcome
- [x] AUTH-2 Sign in
- [x] AUTH-2b Sign in, wrong password
- [x] AUTH-2c Sign in, too many attempts
- [x] AUTH-3 Register
- [x] AUTH-3b Register, errors
- [x] AUTH-4 Verify email
- [x] AUTH-4b Verify email, wrong code
- [x] AUTH-4c Verify email, code expired
- [x] AUTH-5 Email verified
- [x] AUTH-6 How are you paid?
- [x] AUTH-6b How are you paid? two payments
- [x] AUTH-7 Forgot password
- [x] AUTH-8 Reset code
- [x] AUTH-8b Reset code, wrong code
- [x] AUTH-9 New password
- [x] AUTH-10 Password changed
- [x] AUTH-11 App lock
- [x] AUTH-12 PIN entry
- [x] AUTH-13 Create a PIN
- [x] Fingerprint switch of its own (on only after a match), and the PIN, the fingerprint and the timeout stay after sign-out for the same account
- [x] The PIN lock can be on alone and the fingerprint needs it (turned on without a PIN it asks for the fingerprint, then a new PIN); a new lock asks every time the app comes back
- [x] Pin the contract that has the device-key endpoints, and generate the client on a scratch copy first
- [x] Fingerprint sign-in, the key and the server: `DeviceKeyStore` over the plugin, the remote and the fake repository, the key compared with the server after each sign-in
- [x] Settings: "Sign in with fingerprint" switch (password, then a fingerprint; off removes the key from the server and the phone)
- [ ] Sign-in screen: "Sign in as `<name>` with fingerprint" and "Use another account", the wait after too many failures, and the message when it is refused
- [ ] After a password change: offer to turn the fingerprint sign-in on again (the server removes every key)
- [ ] "Phones with fingerprint sign-in": the list with the key of each phone, removing one
- [ ] Check on a real phone against staging (an emulator is refused): turn on, sign out, sign in, a changed fingerprint, a changed password
- [x] Before adding the biometric signing plugin: check it (maintainer, licence, native code), then `flutter pub add` by the owner
- [ ] Store forms for the fingerprint sign-in: Data safety (device identifier, no biometric data) and App Privacy answers, in the privacy policy text
- [x] App lock for real: lock at start and after the time in the background, pauses after wrong PINs, sign-out after ten, "Lock after" in the Settings
- [x] Sign in with an unverified email: opens Verify email, no code sent
- [x] Register: passwords differ, and the countdown on the button while the server asks to wait
- [x] Verify email: 6 digits, the hint for an existing account, and the dead code after too many tries
- [x] "Try again shortly" state when the server is busy (sign in, register, verify email)
- [x] "Not available yet" state for changing a password and deleting the account, until the server offers them

### B. Overview

- [x] OV-1 Overview, one payment
- [x] OV-2 Overview, two payments
- [x] OV-3 Overview, first launch
- [x] OV-4 Choose a debt

### C. Salary, fixed items and history

- [x] SAL-1 Salary, one payment
- [x] SAL-1b Salary, editing a saved month
- [x] SAL-1c Delete month
- [x] SAL-2 Salary, two payments
- [x] SAL-3 Month picker
- [x] SAL-4 Switch to one payment
- [x] SAL-5 Switch to two payments
- [x] SAL-6 Salary history, one payment
- [x] SAL-7 Salary history, two payments
- [x] SAL-8 Compare months
- [x] SAL-9 Compare parts
- [x] SAL-10 Month saved
- [x] FIX-1 Fixed items, one payment
- [x] FIX-2 Fixed items, two payments
- [x] FIX-3 Add fixed item
- [x] FIX-4 Edit fixed item
- [x] FIX-5 Delete fixed item

### D. Transactions

- [x] TX-1 Transactions, one payment
- [x] TX-2 Transactions, two payments
- [x] TX-3 Filters
- [x] TX-3b Filters, two payments
- [x] TX-4 Add transaction
- [x] TX-5 Edit transaction
- [x] TX-6 Choose account
- [x] TX-7 Delete transaction
- [x] TX-8 Transactions, no results

### E. Debts

- [x] DB-1 Debts
- [x] DB-2 Add debt
- [x] DB-3 Debt details
- [x] DB-4 Add repayment
- [x] DB-5 Edit repayment
- [x] DB-6 Delete repayment
- [x] DB-7 Delete debt
- [x] DB-8 Edit debt

### F. Reports

- [x] RP-1 Reports, Categories
- [x] RP-2 Reports, Categories by part
- [x] RP-3 Reports, Month vs month
- [x] RP-4 Reports, Part vs part
- [x] RP-5 Reports, Debts

### G. Settings, account and data

- [x] ST-1 Settings
- [x] ST-2 Account
- [x] ST-3 Pay schedule
- [x] ST-4 Categories
- [x] ST-4b Add or edit category
- [x] ST-5 Accounts
- [x] ST-5b Add or edit account
- [x] ST-6 Change password
- [x] ST-7 Export CSV
- [x] ST-8 Import CSV
- [x] ST-8b Import result
- [x] ST-9 Default currency
- [x] ST-10 Sign out
- [x] ST-11 Delete account

### H. Loading, empty, error and no connection

- [x] OV-5 Overview, loading
- [x] OV-6 Overview, error
- [x] OV-7 Overview, no connection
- [x] SAL-11 Salary, new empty month
- [x] SAL-12 Salary, loading
- [x] SAL-13 Salary, error
- [x] SAL-14 Salary, no connection
- [x] SAL-15 Salary history, empty
- [x] FIX-6 Fixed items, empty
- [x] TX-9 Transactions, loading
- [x] TX-10 Transactions, empty
- [x] TX-11 Transactions, error
- [x] TX-12 Transactions, no connection
- [x] DB-9 Debts, loading
- [x] DB-10 Debts, empty
- [x] DB-11 Debts, error
- [x] DB-12 Debts, no connection
- [x] RP-6 Reports, loading
- [x] RP-7 Reports, empty
- [x] RP-8 Reports, error
- [x] RP-9 Reports, no connection
- [x] NC-1 No connection, full screen
- [x] ERR-1 Could not save
- [x] ERR-2 Something went wrong

### I. Arabic (right-to-left) screens

- [x] AR-1 Overview (Arabic)
- [x] AR-2 Salary (Arabic)
- [x] AR-3 Transactions (Arabic)
- [x] AR-4 Add transaction (Arabic)
- [x] AR-5 Debts (Arabic)
- [x] AR-6 Settings (Arabic)
- [x] AR-7 Sign in (Arabic)
- [x] AR-8 Verify email (Arabic)

### J. Tablet and web layouts

- [x] TB-1 Transactions, wide
- [x] TB-2 Overview, wide
- [x] TB-3 Sign in, web
- [x] Web 1: pushed screens framed as one centred column, the authentication pages split with the brand panel
- [x] Web 2: list and detail for Debts, sections list for Settings
- [x] Web 3: Reports in two columns

### K. Dark mode, app icon and fix-ups

- [x] DK-1 Dark mode: every screen checked in dark
- [x] IC-1 App icon (already in the app)

## 7. Backend connection

The server is the Django backend. The app pins one release of its API contract and generates its client from it; the full guide is [`backend-api.md`](backend-api.md). Do the steps in order, one pull request each unless noted.

Done in the repository:

- [x] Contract tooling: pin a backend release, generate the client, check it in CI, weekly reminder workflow

To do:

- [ ] Backend: first release with `openapi.yaml` attached and immutable releases on (backend repository)
- [x] Add the client packages with `flutter pub add`, every version pinned exactly
- [ ] Create `api/BACKEND_REPO`, sign in with `gh auth login`, run `scripts/sync-api.sh vX.Y.Z`, commit `api/` and `lib/core/api/`
- [x] `API_BASE_URL` per environment: ignored `.env.staging` and `.env.production`, a variable of each GitHub environment, and the launch configurations
- [ ] Local backend: debug-only cleartext exception for the emulator; CORS and allowed hosts on the backend
- [x] Dio instance, token interceptor and one error parser in `core/network/`
- [x] Write safety in the app: one `Idempotency-Key` per action kept until it has an answer, `If-Match` and `If-None-Match`, `412` and `409 idempotency_in_progress`, and reading every page of a list
- [ ] Remote repositories, one feature at a time: `data/remote/`, switch in `main`, delete `data/fake/`
- [ ] Optional: repository variable `BACKEND_REPO` (and secret `BACKEND_READ_TOKEN` if private) for the weekly reminder
- [x] Update `SECURITY.md`, `CONTRIBUTING.md`, the design brief and `docs/DESIGN.md` for the connected backend

Authentication step (agreed with the backend, summary in [`backend-api.md`](backend-api.md) section 7). The contract is pinned; the screens and the fake account follow it first, then the app connects to the server:

- [x] Backend: merge `openapi/schema.yaml` for register, verify email, resend, sign in, refresh, sign out and profile
- [x] Pin the schema, generate the client on a scratch copy first, and check the optional fields and the extra error members
- [x] Prepare the screens, no schema needed: 6-digit email code, no password rule in the app, register countdown, verify-screen hint, "try again shortly" state
- [x] Update the fake auth repository and its tests to the agreed rules (6-digit code, new error codes, resend wait)
- [x] Add the packages for tokens, device information and time zone with `flutter pub add`, exact versions
- [x] Remote auth repository: tokens in secure storage, one refresh at a time, device object, language and time zone
- [x] Check the authentication on a real device against staging: register and verify, sign out and in, a wrong password and the lock, the token expiring, a lost refresh answer
- [x] Staging only: a banner "the server is starting" when a request waits more than a few seconds (the free server sleeps after 15 minutes, production does not), and a silent warm-up request at start
- [x] Request to the backend (`alihaidar0/money-scribe-backend#35`): separate sign-in errors for an unknown email and a wrong password
- [x] Pin the contract that has them, and generate the client on a scratch copy first
- [x] Sign in names the field at fault: email not registered under the email, wrong password under the password, email first
- [x] Sign-in bot challenge (Cloudflare Turnstile) after repeated failed sign-ins: show the widget, send its token once, a new one for each attempt
- [x] Write the leaked-password and bot-check sentences for the privacy policy and the store forms (wording in `backend-api.md`)
- [x] Account endpoints (`alihaidar0/money-scribe-backend#40`): pin the contract and generate the client
- [x] Forgot password on the server: ask for the code, check it, set the new password, then sign in again
- [x] Change password on the server: the new tokens replace the stored ones
- [x] Delete account on the server, and the deletion wording for the privacy policy and the store forms
- [x] Delete the push token of the device when the person signs out, the account is deleted or the session ends
- [x] Push token rules agreed with the backend (one token per device, removed with the session and the account, 90-day retention; written in `backend-api.md`)
- [ ] Push token on the server, when its endpoints are in a pinned contract: register after sign-in and on a new token, only while notifications are allowed; remove first on sign-out, with a short timeout
- [ ] Decide with the backend whether push addresses a device by its FCM token or by its Firebase installation ID (`firebase_messaging` 17 deprecates the token calls), then update `PushMessagingRepository`
- [x] Language and time zone of the account follow the app through the settings `PATCH` of the preferences step, so notifications use the right language
- [x] Remote pay schedule and default currency: the settings of the account are read and saved on the server
- [ ] Before publishing: declare the push token and Firebase installation ID in the privacy policy and the store data forms, and give the web address for account deletion that Google Play asks for
- [x] Edit the name
- [x] Change email: new address, code, cancel (a new code asks for the password again)

Salary step (agreed with the backend; the screens and the fake data follow the agreed contract first, the remote repositories come when the contract is pinned):

- [x] Versions on a month and on a fixed item; a save, edit or delete of a stale one is refused and the person chooses what to do
- [x] A new month starts with the figures of the last saved month (currency, base salary, food allowance, working hours, tax rate, pay schedule); the monthly numbers stay empty
- [ ] Fixed items need a saved month: "Save this month's salary first" instead of an empty list
- [ ] "Copy from last month" for the fixed items of a month, with a confirmation when it already has some, and the refusals worded
- [ ] Results, payments and balances as the server calculates them, next to the live preview
- [x] Remote salary and fixed items repositories (month, history, defaults, per-item calls); the copy comes with "Copy from last month"

How each step is worked on (branches, commits, checks) is described in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
