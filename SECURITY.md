# Security Policy

## Scope

Money Scribe is a personal finance tracker. It stores the user's financial
records (salary, income, expenses, purchases and debts). Once the backend
exists, they live only on the server; the device keeps simple settings, such
as the language, and nothing else, so protecting that data is the main
security concern.

In scope:

- Exposure of the user's financial or personal data: through logs, crash
  output, exported files, platform backups, or another app on the device
- Weaknesses in what the device stores (settings, sign-in credentials), app
  lock or data import (for example a
  crafted CSV file that corrupts data or causes unintended behaviour)
- Weaknesses in how data is sent to or stored on the server
  (authentication, authorization, transport), once a backend exists
- Secrets or credentials committed to the repository history
- A GitHub Actions workflow that could allow unauthorized code execution or
  exfiltration of secrets (e.g. via script injection through untrusted
  input, or an unpinned/compromised third-party action)
- A Husky hook or `postCreateCommand` that executes untrusted code
- A dependency (pub, npm or GitHub Action) with a known critical CVE

## Supported Versions

Only the latest release (the newest tag on `main`) receives security fixes.

## Data handling

- Financial data lives on the server, not on the device; it is sent only over
  encrypted connections. The device keeps only non-financial settings and,
  after sign-in, the session credentials in the platform's secure storage.
  The app sends no analytics or tracking data.
- Amounts, account names and other personal data are never written to logs
  or crash reports.
- Secrets are passed at build time (`--dart-define`) or kept in a local,
  gitignored `.env`; none are stored in the source. Server credentials and
  admin keys are never part of the app.

## Supply chain

- Every GitHub Action is pinned to a full commit SHA, workflows run with
  least-privilege `permissions:` and `persist-credentials: false`, and
  `${{ }}` values reach scripts only through `env:`. Dependabot proposes
  updates weekly with a 7-day cooldown, and `actionlint` and `zizmor` check
  every workflow on each pull request.
- Every pull request scans the packages resolved in `pubspec.lock` against
  the OSV vulnerability database, and audits the npm dependencies.
- The npm dependencies (Husky, commitlint) are locked in `pnpm-lock.yaml`;
  the Dart packages are locked in `pubspec.lock`.
- The dev image and the Flutter version are pinned to an exact build, so the
  toolchain changes only through a reviewed pull request.
- Release signing keys live only in the `production` environment's secrets
  ([`docs/android-signing.md`](docs/android-signing.md)).

## Reporting a Vulnerability

**Please do not open a public issue for security vulnerabilities**, and never
include real financial data in a report.

Report privately via [GitHub Security Advisories](https://github.com/alihaidar0/money-scribe/security/advisories/new)
for this repository. Include:

- A description of the vulnerability and its potential impact
- Steps to reproduce (a minimal example is ideal)
- A suggested fix, if you have one

Expect an initial response within **5 business days**. Once confirmed, a fix
will be prioritized and a GitHub Security Advisory published when a patch is
available.

## Related

Vulnerabilities in the base Docker image itself (OS packages, SDKs, CLI
tools) belong to [`flutter-devcontainer`'s security policy](https://github.com/alihaidar0/flutter-devcontainer/blob/main/SECURITY.md).
