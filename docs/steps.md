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
- [ ] Salary calculation: one or two payments a month, every line rounded to the kopeck (pure Dart, tests)
- [ ] Monthly salary calculator, with every month saved
- [ ] Recurring monthly income and expenses
- [ ] Transactions and purchases
- [ ] Debts: borrowed and lent, partial repayments, settled status
- [ ] Backend and sign-in, with the server as the only place the data is stored (provider chosen when needed)
- [ ] Decide on crash reporting and opt-in analytics (none until then; never amounts or personal data)
- [ ] Notifications: local reminders first (for example debts due); push messages through Firebase Cloud Messaging are tested from the Firebase console until the backend can send them

## 4. Insight and polish

- [ ] Monthly overview
- [ ] Reports: by category, month over month, debts summary
- [ ] CSV export and import that round-trips without loss
- [ ] App lock
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
- [ ] Navigation test: every button leads where the design says

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

### B. Overview

- [x] OV-1 Overview, one payment
- [x] OV-2 Overview, two payments
- [x] OV-3 Overview, first launch
- [x] OV-4 Choose a debt

### C. Salary, fixed items and history

- [ ] SAL-1 Salary, one payment
- [ ] SAL-1b Salary, editing a saved month
- [ ] SAL-1c Delete month
- [ ] SAL-2 Salary, two payments
- [ ] SAL-3 Month picker
- [ ] SAL-4 Switch to one payment
- [ ] SAL-5 Switch to two payments
- [ ] SAL-6 Salary history, one payment
- [ ] SAL-7 Salary history, two payments
- [ ] SAL-8 Compare months
- [ ] SAL-9 Compare parts
- [ ] SAL-10 Month saved
- [ ] FIX-1 Fixed items, one payment
- [ ] FIX-2 Fixed items, two payments
- [ ] FIX-3 Add fixed item
- [ ] FIX-4 Edit fixed item
- [ ] FIX-5 Delete fixed item

### D. Transactions

- [ ] TX-1 Transactions, one payment
- [ ] TX-2 Transactions, two payments
- [ ] TX-3 Filters
- [ ] TX-3b Filters, two payments
- [ ] TX-4 Add transaction
- [ ] TX-5 Edit transaction
- [ ] TX-6 Choose account
- [ ] TX-7 Delete transaction
- [ ] TX-8 Transactions, no results

### E. Debts

- [ ] DB-1 Debts
- [ ] DB-2 Add debt
- [ ] DB-3 Debt details
- [ ] DB-4 Add repayment
- [ ] DB-5 Edit repayment
- [ ] DB-6 Delete repayment
- [ ] DB-7 Delete debt
- [ ] DB-8 Edit debt

### F. Reports

- [ ] RP-1 Reports, Categories
- [ ] RP-2 Reports, Categories by part
- [ ] RP-3 Reports, Month vs month
- [ ] RP-4 Reports, Part vs part
- [ ] RP-5 Reports, Debts

### G. Settings, account and data

- [ ] ST-1 Settings
- [ ] ST-2 Account
- [ ] ST-3 Pay schedule
- [ ] ST-4 Categories
- [ ] ST-4b Add or edit category
- [ ] ST-5 Accounts
- [ ] ST-5b Add or edit account
- [ ] ST-6 Change password
- [ ] ST-7 Export CSV
- [ ] ST-8 Import CSV
- [ ] ST-8b Import result
- [ ] ST-9 Default currency
- [ ] ST-10 Sign out
- [ ] ST-11 Delete account

### H. Loading, empty, error and no connection

- [x] OV-5 Overview, loading
- [x] OV-6 Overview, error
- [x] OV-7 Overview, no connection
- [ ] SAL-11 Salary, new empty month
- [ ] SAL-12 Salary, loading
- [ ] SAL-13 Salary, error
- [ ] SAL-14 Salary, no connection
- [ ] SAL-15 Salary history, empty
- [ ] FIX-6 Fixed items, empty
- [ ] TX-9 Transactions, loading
- [ ] TX-10 Transactions, empty
- [ ] TX-11 Transactions, error
- [ ] TX-12 Transactions, no connection
- [ ] DB-9 Debts, loading
- [ ] DB-10 Debts, empty
- [ ] DB-11 Debts, error
- [ ] DB-12 Debts, no connection
- [ ] RP-6 Reports, loading
- [ ] RP-7 Reports, empty
- [ ] RP-8 Reports, error
- [ ] RP-9 Reports, no connection
- [ ] NC-1 No connection, full screen
- [ ] ERR-1 Could not save
- [ ] ERR-2 Something went wrong

### I. Arabic (right-to-left) screens

- [ ] AR-1 Overview (Arabic)
- [ ] AR-2 Salary (Arabic)
- [ ] AR-3 Transactions (Arabic)
- [ ] AR-4 Add transaction (Arabic)
- [ ] AR-5 Debts (Arabic)
- [ ] AR-6 Settings (Arabic)
- [ ] AR-7 Sign in (Arabic)
- [ ] AR-8 Verify email (Arabic)

### J. Tablet and web layouts

- [ ] TB-1 Transactions, wide
- [ ] TB-2 Overview, wide
- [ ] TB-3 Sign in, web

### K. Dark mode, app icon and fix-ups

- [ ] DK-1 Dark mode: every screen checked in dark
- [x] IC-1 App icon (already in the app)

How each step is worked on (branches, commits, checks) is described in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
