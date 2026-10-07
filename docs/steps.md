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
- [ ] Strict lints in `analysis_options.yaml`
- [ ] Feature-first folders: `app/`, `core/`, `features/<name>/{data,domain,application,presentation}`
- [ ] Riverpod, `go_router`, `drift` and `freezed`
- [ ] Material 3 theme with light and dark modes
- [ ] Localization-ready strings (ARB files)

## 3. Core features

- [ ] `Money` value object: integer minor units, currency code, one place for rounding
- [ ] Monthly salary calculator, with every month saved
- [ ] Recurring monthly income and expenses
- [ ] Transactions and purchases
- [ ] Debts: borrowed and lent, partial repayments, settled status

## 4. Insight and polish

- [ ] Monthly overview
- [ ] Reports: by category, month over month, debts summary
- [ ] CSV export and import that round-trips without loss
- [ ] App lock
- [ ] Accessibility review

## 5. Release

- [ ] Register the domain and check the USPTO and WIPO trademark databases
- [ ] Create the `production` environment, restricted to `main`, for the signing secrets ([`github-setup.md`](github-setup.md))
- [ ] Android release signing ([`android-signing.md`](android-signing.md))
- [ ] Optional: set the repository variable `BUILD_IOS` to `true` for the iOS compile check in CI
- [ ] Raise the version and open the `develop` → `main` release pull request

How each step is worked on (branches, commits, checks) is described in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
