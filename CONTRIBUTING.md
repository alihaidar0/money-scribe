# Contributing

Thanks for improving **Money Scribe**, a personal finance tracker built with Flutter. The app handles people's money, so changes are kept small, tested and reviewed.

## Scope

In scope: the app (`lib/`, `test/`, the platform folders), its documentation, and the tooling that builds and checks it (dev container, git hooks, workflows, repository governance).

Out of scope:

- Anything that belongs in the dev image (SDKs, system packages, shell aliases, the prompt). That is [`flutter-devcontainer`](https://github.com/alihaidar0/flutter-devcontainer).
- Analytics, crash reporting or tracking of what users do, for now; this is revisited when the backend is chosen. A backend with sign-in and synchronization is planned, but its provider is not chosen yet, so discuss backend work in an issue before starting it.

## Branching and pull requests

- `main` is the stable, released state; `develop` is the integration branch, the default branch and where Dependabot pull requests land. Neither branch accepts direct pushes.
- Work on a topic branch off `develop` (`feat/…`, `fix/…`, `docs/…`, `ci/…`, `chore/…`, `deps/…`, `refactor/…`, `test/…`) and open the pull request against **`develop`**.
- Only a `develop` → `main` release pull request may target `main`.
- Merge with a **merge commit**. Squash and rebase merging are disabled.
- Fill in the [pull request template](.github/PULL_REQUEST_TEMPLATE.md) and use a Conventional Commit title: labels (they drive the release notes) are added automatically from it, and you can add more by hand.
- The **CI passed** check must be green before merging.
- One concern per pull request. The build plan is tracked in [`docs/steps.md`](docs/steps.md); tick a step in the pull request that completes it.

The branch model, repository settings and rulesets are described in [`docs/github-setup.md`](docs/github-setup.md).

## Before you start

Open the repository in the dev container (**Dev Containers: Reopen in Container**). Flutter, Dart, the Android SDK, Node and pnpm come from the image, pinned in `docker-compose.yml`. The Husky hooks activate when the container is created (`postCreateCommand` runs `pnpm install`):

- `pre-commit` runs the same checks as CI on every commit: line endings, trailing whitespace and final newlines of the staged files, executable scripts, `dart format`, `flutter analyze --fatal-infos` and `flutter test`.
- `commit-msg` checks the Conventional Commit message.
- `pre-push` blocks direct pushes to `main` and `develop` and runs `flutter analyze --fatal-infos` again.

To register them again:

```bash
pnpm run prepare
```

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/), enforced locally by commitlint and Husky's `commit-msg` hook and again in CI for every commit of a pull request:

```text
feat(transactions): add the transaction list screen
fix(money): keep the currency when negating an amount
docs(readme): describe the supported platforms
build(deps): bump the commitlint group
```

Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert` `wip`. The type is lower-case, the subject is not sentence-, start-, Pascal- or upper-case and has no trailing period. A breaking change (for example a database change without a migration path) uses `feat!:` with a `BREAKING CHANGE:` footer.

## Making changes

- **Structure** — feature-first and layered: `lib/app/` (app shell, theme, router), `lib/core/` (shared code), `lib/features/<name>/{data,domain,application,presentation}`. `test/` mirrors `lib/`.
- **Money** — never use `double` for amounts. Amounts are integer minor units with an ISO 4217 currency code, wrapped in the `Money` value object; rounding happens in one place only. Amounts in different currencies are never added without an explicit conversion.
- **Dates** — timestamps are stored in UTC and converted to local time only for display. Periods (months, reports) define their boundaries explicitly.
- **Data** — the server is the source of truth and the device keeps a local copy that stays usable without a connection (the backend is not chosen yet, so for now the local database holds everything). All remote access sits behind repository interfaces. Transactions are the record; balances are derived, never edited directly. Deleting a financial record is explicit and confirmed. Database changes ship with a versioned migration and a migration test. CSV export and import must round-trip without loss.
- **Privacy** — no amounts, account names or personal data in logs, crash reports or test fixtures; tests use invented numbers. Secrets only through `--dart-define` or a local `.env` (see `.env.example`), never in source; server credentials and admin keys never belong in the app or the repository.
- **Text and formatting** — user-facing strings live in ARB files; currency and dates are formatted with `intl`, never by hand.
- **Accessibility** — semantic labels, sufficient contrast, scalable text, and no meaning carried by colour alone (income and expense also differ by sign or icon).
- **Dependencies** — pin every package version in `pubspec.yaml` and commit `pubspec.lock`. GitHub Actions are pinned to a full commit SHA with a `# vX.Y.Z` comment.
- **Toolchain** — the dev image and Flutter are frozen by `scripts/pin-image.sh` (`docker-compose.yml` and `environment: flutter:` in `pubspec.yaml`). Move to a newer toolchain only through a reviewed pull request, and update the Stack table in `README.md` in the same change.
- **Node stays on 24**, matching the image. `engines.node` and the Dependabot ignore rule must agree.
- **Shell scripts and hooks use LF line endings** and are executable in Git; a CRLF script fails inside the container.
- **Workflow hygiene** — least-privilege `permissions:`, `persist-credentials: false` on checkout, `timeout-minutes` on every job, and `${{ }}` values reach `run:` scripts through `env:`, never inline.
- **Spelling** — `cspell.json` configures the spell checker (VS Code runs it through the Code Spell Checker extension). British and American English are both accepted. Add a genuine project word (a name, a tool, a technical term; never a typo) to `.cspell/project-words.txt`, lowercase and in alphabetical order. The generated `android/` and `ios/` folders are not checked. To check the whole project: `pnpm dlx cspell --no-progress "**"`.
- **Keep the documentation true** — update `README.md` and `docs/` in the same pull request as the code.

## Checking your change locally

The same checks CI runs on every pull request (the `pre-commit` hook runs them too):

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

For changes to scripts, hooks or workflows, CI runs ShellCheck, actionlint and zizmor. The commands below use Docker; the dev container has none, so inside it run ShellCheck with `pnpm dlx shellcheck@latest --shell=sh .husky/commit-msg .husky/pre-commit .husky/pre-push` (and without `--shell=sh` on `scripts/*.sh`), and download the actionlint and zizmor release binaries from their GitHub releases pages.

```bash
bash -n scripts/*.sh
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable scripts/*.sh
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable --shell=sh .husky/commit-msg .husky/pre-commit .husky/pre-push
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -no-color
docker run --rm -v "$PWD:/repo:ro" -w /repo ghcr.io/zizmorcore/zizmor:latest --no-progress --offline .
git ls-files -s scripts .husky   # every mode must be 100755 (new files: git add --chmod=+x <file>)
```

## Bugs and feature requests

Use the issue forms under **New issue**. Never paste real financial data (amounts, account names, balances) into an issue; use invented numbers. Problems with the base Docker image itself belong in [`flutter-devcontainer`](https://github.com/alihaidar0/flutter-devcontainer/issues).

## Security issues

Do not open a public issue for a vulnerability. See [`SECURITY.md`](SECURITY.md).

## Conduct

Participation is governed by the [Code of Conduct](.github/CODE_OF_CONDUCT.md).
