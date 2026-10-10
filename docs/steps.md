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
- [x] App shell: feature-first folders (`app/`, `core/`, `features/<name>/`), Riverpod and `go_router`
- [x] Material 3 theme with light and dark modes
- [x] Localization with ARB files: English and Arabic, with the language following the system and a setting
- [x] Arabic font and right-to-left layout, added to the design system and checked on every screen
- [ ] Data layer base: repository interfaces with fake data sources (invented data), ready to be replaced by the server
- [ ] Immutable models with `freezed`, added with the first model that needs it

## 3. Core features

- [ ] `Money` value object: integer minor units, currency code, one place for rounding, Western digits in every language
- [ ] Monthly salary calculator, with every month saved
- [ ] Recurring monthly income and expenses
- [ ] Transactions and purchases
- [ ] Debts: borrowed and lent, partial repayments, settled status
- [ ] Backend and sign-in, with the server as the only place the data is stored (provider chosen when needed)
- [ ] Decide on crash reporting and opt-in analytics (none until then; never amounts or personal data)
- [ ] Notifications: local reminders first (for example debts due), push once the backend is chosen

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
- [ ] Raise the version, open the `develop` → `main` release pull request, test its files, merge, check the signed production build, publish the release
- [ ] Create one Google Cloud project per environment (staging and production)
- [ ] Register the staging and production Android apps in their projects (no SDK or keys in the app yet)
- [ ] Google Play: developer account, app, first internal-testing upload, store listing and privacy policy
- [ ] Upload to Google Play from the build workflow (staging to an internal track, production on merge into `main`)
- [ ] iOS: flavors, signing and TestFlight (needs a Mac and an Apple Developer account)
- [ ] Optional: set the repository variable `BUILD_IOS` to `true` for the iOS compile check in CI (after the iOS flavors)
- [ ] Register the domain and check the USPTO and WIPO trademark databases

How each step is worked on (branches, commits, checks) is described in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
