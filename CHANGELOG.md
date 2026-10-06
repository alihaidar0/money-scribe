# Changelog

All notable changes to this template are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); commit history
follows [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

> **⚠️ Revisit before Node 26 LTS:** Node's TSC voted to stop distributing
> Corepack from Node 25 onward; Node 24 still bundles it as an experimental
> feature. `flutter-devcontainer` moves to Node 26 LTS around Oct/Nov 2026.
> Corepack and pnpm are prepared in the image, so this template only runs
> `pnpm install`; the migration must keep `pnpm` on the `developer` user's
> `PATH` at the version pinned by `packageManager` (for example by installing
> pnpm in the image without Corepack) and update the `image-contract.yml`
> check if the way pnpm is provided changes.

### Added

- `scripts/init-readme.sh`: replaces the template guide in a new app's
  `README.md` with a short README for the app (title from the repository name,
  your description, CI/Build/License badges, platforms, a Stack table read from
  the project, the template release it started from and the license line). It
  refuses to overwrite a README that is no longer the guide unless `--force` is
  given, and the `welcome.sh` banner lists it as step 3.
- `setup-flutter-test.yml`: a smoke test of the local `setup-flutter` action
  on Linux and macOS (newest stable, a `3.x` line and an exact version). It runs
  only when the action or the workflow changes, and on demand, so it is not
  part of `CI passed`.
- `bootstrap-main.yml`: a repository created from the template starts with
  only the default branch, `develop`. This workflow creates `main` from it the
  first time it is missing (it starts on the repository's first commit, and again
  on every push to `develop` or on demand as a safety net), never
  touches an existing `main`, and never runs in the template repository itself.
  It needs only `contents: write` on its one job and is not part of `CI passed`.
- `pr-labels.yml`: adds labels to a pull request from its Conventional Commit
  title (`feat` → `feature`, `fix` → `bug`, `docs` → `documentation`, `ci` →
  `ci`, `deps` scope → `dependencies`, `!` → `breaking change`, a
  `develop` → `main` promotion → `skip-changelog`) so the generated release
  notes no longer depend on setting labels by hand. It only adds labels and is
  not part of `CI passed`.
- `.editorconfig` for consistent formatting across editors.
- `.env.example` — starter environment variable template.
- `.vscode/extensions.json`, `settings.json`, `launch.json` — shared editor
  settings and forward-ready Flutter debug configurations.
- `LICENSE` (MIT), `SECURITY.md`, `CONTRIBUTING.md`.
- `.github/PULL_REQUEST_TEMPLATE.md` and `.github/ISSUE_TEMPLATE/` (bug
  report, feature request, contact links to `flutter-devcontainer`).
- `repomix.config.json` — Repomix configuration for a single-file
  repository snapshot.
- `security` label.
- Importable rulesets for `main`, `develop` and `v*` tags
  (`.github/rulesets/`) and `docs/github-setup.md`, which lists every GitHub
  setting and the bootstrap order for the template and for each project
  created from it.
- `ci.yml` jobs: **Verify source branch** (only `develop` may target
  `main`), **Lint** (ShellCheck, actionlint), **Format**, **Commit messages**
  (commitlint over every PR commit), **Template guard** (template repository
  only) and **Dependency audit** (OSV-Scanner on `pubspec.lock`).
- `release.yml` (calendar-versioned GitHub Releases) and `image-contract.yml`
  (weekly template ↔ `flutter-devcontainer` check), both template repository
  only, plus `.github/release.yml` and the `ci` and `skip-changelog` labels.
- `.github/CODE_OF_CONDUCT.md` (Contributor Covenant 2.1) and `pnpm-lock.yaml`.
- `ci.yml` jobs **Node dependency audit** (`pnpm audit`, high and critical
  fail) and a zizmor workflow-security step in **Lint**; the template guard
  also checks the executable bit of `.github/scripts/`.

### Changed

- Labels: the **Labels** workflow already runs on the first push of a repository
  created from the template (the first commit contains `.github/labels.yml`), so
  the README and `docs/github-setup.md` now say to check that the labels exist
  and to run the workflow by hand only if they are missing. `workflow_dispatch`
  stays as the fallback.
- The `wont fix` label is now `wontfix`, the name GitHub creates in every new
  repository, so the sync updates the default label instead of adding a second
  one. Existing projects keep both labels until you delete one by hand; the
  workflow never deletes labels.
- `.husky/pre-push` runs `flutter analyze --fatal-infos`, the same command as the
  CI analyze job, so an info-level lint fails before the push instead of in CI.
  The README troubleshooting entry names the flag (the `fanalyze` alias in the
  image does not pass it).
- README: step 5 and the "What to change" table tell new apps to decide the
  application ID before the first commit, because with an underscore in the
  project name Android and iOS get different IDs.
- `labels.yml` syncs `.github/labels.yml` with the `gh` CLI (`gh label create
  --force` per label, parsed with the runner's preinstalled `yq` and `jq`)
  instead of the `EndBug/label-sync` action, which still declares Node 20 and
  made every run print a deprecation warning. Behaviour is unchanged (labels
  are created or updated, unlisted labels are left alone), one third-party
  action is gone, and `EndBug/label-sync@*` is no longer needed in the allowed
  actions list (repositories that already list it can leave it).
- **`develop` is now the default branch** (set in the repository settings). Dependabot
  security updates, which always target the default branch, now arrive against
  `develop` like version updates, so nothing has to be re-targeted by hand;
  new pull requests default to it too. Rulesets, the **Verify source branch**
  job (only `develop` may target `main`) and the release flow are unchanged.
  A repository created from the template starts with `develop`; the new
  `bootstrap-main.yml` workflow creates `main` from it (see
  `docs/github-setup.md`).
- `labels.yml` also runs when `.github/labels.yml` changes on `develop`, now
  the default branch, so label edits no longer wait for a release. The setup
  guide and the README run it right after the repository is created, before the
  first pull requests, because Dependabot and `pr-labels.yml` need the labels.
- `.husky/pre-push` blocks direct pushes to `develop` as well as `main`, once the
  branch exists on the remote (creating it still works). The rulesets remain
  the real gate.
- README: apps are told to note the template release they started from and to
  read the template's Releases page to see what changed since (sections 2.4
  and 7.3).
- `scripts/pin-image.sh` follows the image's new permanent tag format
  `flutter-X.Y.Z.R` (Flutter release plus image revision): by default it pins
  the newest revision for the Flutter in the container, then resolves it to its
  digest. The old `sha-xxxxxxx` and date tags are no longer published; the
  README tag table and the bug report example are updated. The template itself
  still follows `:latest`.
- **Bumped `packageManager` from `pnpm@11.28.2` to `pnpm@12.9.1`** and
  `engines.pnpm` to `^12.0.0`. This is a **major** version bump, made together
  with `flutter-devcontainer` (which pre-caches the same version). The
  existing lockfile content is unchanged and installs with
  `--frozen-lockfile`; pnpm 12 additionally records the package manager
  itself in a leading section of `pnpm-lock.yaml`. Projects already created
  from the template keep their pinned image and stay on pnpm 11 until they
  move to the new image.
- The rulesets bind the required **CI passed** check to the GitHub Actions app
  (`integration_id`), `build.yml` fails when an expected artifact is missing,
  and the issue forms and PR template gained a pre-submission checklist,
  reproduction steps and a breaking-change section.
- Every workflow now pins all actions to full commit SHAs, uses
  `persist-credentials: false`, explicit `ubuntu-24.04` runners and
  `env:`-based expression handling; `ci.yml` runs on pull requests (and on
  demand) instead of on every push, and its aggregate **CI passed** job
  evaluates results through `env:`.
- Flutter CI job names are now prefixed `Flutter …` and the dependency audit
  uses OSV-Scanner instead of the third-party `dart_audit` (Dart has no
  `pub audit` command); the README no longer documents a `daudit` alias the
  image does not provide.
- VS Code configuration is deduplicated: the dev container installs the
  extensions (adding ShellCheck and GitHub Pull Requests, dropping cosmetic and
  project-specific ones), `.vscode/extensions.json` only recommends Dev
  Containers, and `.vscode/settings.json` holds the shared editor settings once
  instead of repeating `.editorconfig` and `devcontainer.json`. Removed
  `dart.lineLength` (it made the editor format at 120 while `dart format`,
  the pre-commit hook and CI use the width from `analysis_options.yaml`),
  `git.enableSmartCommit` and the Chrome launch configuration, which a
  container cannot display.
- The README is now the complete guide: creating an app from the template to
  the first run on an emulator and in a browser, what to change in the new app,
  GitHub settings and rulesets, branches, git inside and outside the container,
  the hooks, CI/CD, releases and troubleshooting, with 12 mermaid diagrams.
  `welcome.sh` re-installs missing Husky hooks on every start so the first
  commit and push of a new project are always checked, and
  `check-image-contract.sh` accepts the alias table under a level-2 or
  level-3 heading.
- `docs/` was listed in `.gitignore`, so `docs/github-setup.md` (linked from the
  README and CONTRIBUTING) never reached GitHub or generated projects; it is
  tracked now, together with the new `docs/android-signing.md`.
- `node_modules` moved to a named volume (`node-modules`): on a Windows bind
  mount commitlint took 9.2 s per commit and now takes 0.55 s; `entrypoint.dev.sh`
  fixes the ownership of the new mount point once.
- Release automation without a bot: `release.yml` gained an `app-release` job
  that publishes a GitHub Release with generated, label-grouped notes for the
  version in a project's `pubspec.yaml` (once per version; the Releases page is
  the changelog, so a project deletes `CHANGELOG.md`). The template keeps its
  calendar-versioned release. release-please and git-cliff were not adopted:
  they need Actions to open pull requests (disabled in `docs/github-setup.md`),
  their pull requests would not trigger **CI passed** with `GITHUB_TOKEN`, and
  they would conflict with the rule that only `develop` may target `main`.
- `docs/android-signing.md` documents Android release signing (keystore in a
  `production` environment limited to `main`, a signing job for pushes to
  `main`, a Gradle snippet that falls back to the debug key), and `build.yml`
  gained an opt-in unsigned iOS compile check (repository variable
  `BUILD_IOS=true`, `macos-15`).
- `build.yml` builds for the two environments of the branching model, so a
  generated project needs no workflow edits: pull requests into `develop`
  produce staging artifacts, pull requests into `main` and merges to `main`
  produce production artifacts (APK, AAB and web, `--dart-define=APP_ENV=…`,
  optional `env/<environment>.json`, 14 or 30 days retention), draft pull
  requests are skipped, and the three jobs became one matrix job. `ci.yml` and
  `build.yml` run `flutter pub get --enforce-lockfile`, and `ci.yml` warns
  until the dev image and the Flutter version are pinned.
  `scripts/pin-image.sh` now also writes `environment: flutter:` to
  `pubspec.yaml` and refreshes `pubspec.lock`.
- Running on the host is automatic: `scripts/connect-emulator.sh` connects the
  container's adb to an emulator on the host (at container start and, through
  the new `.vscode/tasks.json` task, before every Android launch, waiting while
  the emulator boots); `launch.json` now offers **Flutter (Android — host
  emulator)**, **Flutter (Web — host browser)** and the compound
  **Flutter (Emulator + Browser)**. The README's host section replaces the
  firewall click-path with one PowerShell command.
- Git works from the container and from the host: the Husky hooks that need the
  toolchain (`commit-msg`, `pre-commit`, the analysis in `pre-push`) skip with a
  notice outside the dev container, and CI enforces the same checks.
- Per-project version pinning: `scripts/pin-image.sh` freezes the `image:` line
  of `docker-compose.yml` to an exact `<tag>@sha256:<digest>`; `ci.yml` and
  `build.yml` install the Flutter version pinned under `environment: flutter:`
  in `pubspec.yaml` (newest stable when there is no pin); a commented-out
  Dependabot `docker-compose` block turns image updates into reviewed pull
  requests. The template itself keeps following `:latest`.
- Git identity and SSH keys are no longer bind-mounted: VS Code copies the Git
  identity and forwards the host ssh-agent (README → Git and SSH), and
  `welcome.sh` maps a host-only SSH alias in the `origin` URL to `github.com`.
  `entrypoint.dev.sh` shrinks to the Husky permission fix.
- `.husky/pre-commit` checks only the staged Dart files with `dart format`;
  `flutter analyze` moved to `.husky/pre-push`, which still blocks `main`.
- Removed `.dockerignore` (the template builds no image), the `frunc` alias
  documentation (a container cannot open Chrome), the duplicated
  Dart/Flutter extensions, `dart.flutterSdkPath` and `remoteUser` from
  `devcontainer.json` (the image's `devcontainer.metadata` label provides
  them), and the `DOCKERHUB_USERNAME` variable from the image reference.
- The dev environment relies on the current `flutter-devcontainer` image
  instead of repeating what it provides: `postCreateCommand` is just
  `pnpm install` (Corepack and pnpm are prepared in the image), and the
  `safe.directory` setting, the Gradle wrapper sync in `welcome.sh` (the
  image has no standalone Gradle) and the named-volume ownership loop in
  `entrypoint.dev.sh` are gone. **Requires the `flutter-devcontainer` image
  published after its "harden the image and publish pipeline" release.**
- `docker-compose.yml` no longer fixes `name:` or `container_name:` (projects
  created from the template no longer share one Compose project, volumes and
  container name), drops the Android SDK volume (the SDK ships in the image
  and a volume hid image updates), the custom network, `restart`, `command`,
  `:cached` and the duplicate `8080` port mapping (VS Code forwards it), and
  adds `init: true`. `GIT_SSH_COMMAND` is set once, in compose.
  `devcontainer.json` gained `hostRequirements` for Codespaces. After pulling
  a newer image run `docker compose down -v` (see README).
- `packageManager` is now `pnpm@11.28.2`, the version the dev image
  pre-caches, and `engines.pnpm` is `^11.0.0`.
- Dependabot gained a 7-day cooldown; `.github/CODEOWNERS`, labels, the
  pull-request template and the issue forms were extended; `CONTRIBUTING.md`
  and `SECURITY.md` describe the current rules and supply-chain controls.
- `.husky/commit-msg` runs `pnpm exec commitlint` instead of `npx`, matching
  the package manager the project uses.
- `.husky/pre-push` no longer trips ShellCheck (`read -r`, no unused
  variables); behaviour is unchanged.
- Dependabot (`github-actions`, `pub`, `npm`) now opens PRs against
  `develop` instead of `main`, matching `flutter-devcontainer`.
- `ci.yml` / `build.yml` / `labels.yml` now declare explicit least-privilege
  `permissions` and `timeout-minutes` per job. No pinned action versions
  changed.
- `.gitignore` — `.vscode/settings.json`, `extensions.json`, and
  `launch.json` are now tracked as shared team defaults; only
  `.vscode/*.local.json` is ignored.
- `scripts/entrypoint.dev.sh` no longer aborts the container if it can't
  fix SSH/Husky permissions (e.g. root-owned bind mounts from Windows
  Docker Desktop). It now retries via non-interactive `sudo -n` and, if
  that also fails, prints a warning and continues rather than blocking
  container startup over a permissions cosmetic issue.
- **Bumped `packageManager` from `pnpm@10.33.0` to `pnpm@11.22.0`**
  (`engines.pnpm` floor raised to `>=11.0.0` to match). ⚠️ This is a
  **major** version bump — pnpm 11 requires Node ≥ 22 (already satisfied
  by this template's Node ≥ 24 floor), switches the store index to
  SQLite, drops the npm-CLI fallback for `pnpm publish` in favor of a
  native implementation, turns on `minimumReleaseAge` (1 day) and
  `blockExoticSubdeps` by default, and removes several legacy
  `onlyBuiltDependencies`-adjacent settings in favor of `allowBuilds`. None
  of that affects this template today (no `.npmrc`, no custom
  `onlyBuiltDependencies`/patch settings, `pnpm-workspace.yaml` only sets
  `engineStrict`/`nodeLinker`, both still valid in v11) — but re-check
  this note if you've added workspace-level pnpm config since. See
  [pnpm 11.0 release notes](https://pnpm.io/blog/releases/11.0) before
  merging if you're unsure.

### Fixed

- `pr-labels.yml` no longer cancels a run that has already started when the
  pull request title or description is edited again; only a run still waiting
  is replaced by the newest one, so editing a pull request right after opening
  it no longer leaves a cancelled run with error annotations.
- The **Format** job no longer fails the first pull request of a new app: files
  that `flutter create` writes under `android/`, `ios/`, `web/`, `macos/`,
  `linux/` and `windows/` (for example an iOS launch-image `README.md` without a
  final newline) are skipped by the trailing-whitespace and final-newline
  checks. The CRLF check and every other file are still checked.
- CI and builds no longer fail at job setup when a repository turns on
  **Require actions to be pinned to a full-length commit SHA**. That setting
  also covers the actions called inside a composite action, and the third-party
  Flutter setup action called `actions/cache` by tag. The workflows now use a
  local `.github/actions/setup-flutter` action that resolves the stable
  release from Google's release manifest, checks the SDK archive against the
  published SHA-256 and caches the SDK and the pub cache with a SHA-pinned
  `actions/cache` (Dependabot watches it). The third-party action is removed,
  so drop `subosito/flutter-action@*` from a project's allowed actions. Its
  downloads accept only HTTPS (also across redirects) and have a time limit.
- `git push` from the dev container no longer authenticates as the wrong
  GitHub account when the forwarded ssh-agent holds keys for several accounts.
  `welcome.sh` now runs the new `scripts/pin-ssh-key.sh`, which finds the key
  that belongs to the repository's account and writes a `Host` entry for the
  `origin` host alias (a plain `github.com` remote is left alone) with
  `IdentityFile` set to that key's public file and `IdentitiesOnly yes`, so ssh
  offers that one key instead of every key in the agent. No private key enters
  the container, and the pin is re-chosen when its key leaves the agent or with
  `--force`. `scripts/pin-ssh-key.sh --key SHA256:...` chooses the key
  explicitly instead of guessing (for example when two accounts can read the
  same repository): the fingerprint is remembered in the clone's `.git/config`
  as `devcontainer.sshkey`, nothing is probed, and a key missing from the agent
  is reported rather than replaced by another account's key.

## [0.1.0] — Initial template

### Added

- Dev container (`devcontainer.json`, `docker-compose.yml`) pulling the
  pre-built `flutter-devcontainer` image.
- Three-tier graceful-degradation CI (`ci.yml`) and production build
  pipeline (`build.yml`).
- Husky + commitlint git hooks.
- Dependabot for GitHub Actions, pub, and npm ecosystems (Node frozen at 24).
