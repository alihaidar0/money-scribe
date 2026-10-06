# Contributing

Thanks for improving `flutter-template`. This repository provides the developer toolchain and CI/CD scaffolding that every new Flutter project starts from, so a change here reaches every project generated from it. Changes are kept small and verified.

## Scope

In scope: the dev container and compose setup, the git hooks, the CI and build workflows, repository governance (rulesets, labels, templates, Dependabot) and the documentation.

Out of scope:

- Flutter application code, `lib/`, `pubspec.yaml`, `pubspec.lock`, `android/`, `ios/`, `web/` or `test/`. This template must stay a zero-code starting point; `flutter create` makes them per project.
- Anything that belongs in the dev image (SDKs, system packages, shell aliases, the prompt). That is [`flutter-devcontainer`](https://github.com/alihaidar0/flutter-devcontainer).
- Deployment workflows and secrets. Targets differ per project (release signing is documented in [`docs/android-signing.md`](docs/android-signing.md), not configured).

## Branching and pull requests

- `main` is the stable, released state; `develop` is the integration branch, the default branch (what "Use this template" copies) and where Dependabot pull requests land. Neither branch accepts direct pushes.
- Work on a topic branch (`feat/…`, `fix/…`, `docs/…`, `ci/…`, `chore/…`, `deps/…`) and open the pull request against **`develop`**.
- Only a `develop` → `main` pull request may target `main`.
- Merge with a **merge commit**. Squash and rebase merging are disabled.
- Fill in the [pull request template](.github/PULL_REQUEST_TEMPLATE.md) and use a Conventional Commit title: labels (they drive the release notes) are added automatically from it, and you can add more by hand.
- The **CI passed** check must be green before merging.

The full branch model, repository settings and rulesets are described in [`docs/github-setup.md`](docs/github-setup.md).

## Before you start

Husky hooks activate when the dev container is created (`postCreateCommand` runs `pnpm install`). To register them again:

```bash
pnpm install
```

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/), enforced locally by commitlint and Husky's `commit-msg` hook and again in CI for every commit of a pull request:

```text
feat(ci): add coverage upload to the test job
fix(devcontainer): correct flutterSdkPath
docs(readme): clarify emulator setup
build(deps): bump the commitlint group
```

Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert` `wip`. The type is lower-case, the subject is not sentence-, start-, Pascal- or upper-case and has no trailing period. A change that forces already-generated projects to adapt is breaking: `feat!:` with a `BREAKING CHANGE:` footer.

## Making changes

- **Dev container, compose, VS Code config** — edit `.devcontainer/devcontainer.json`, `docker-compose.yml` or `.vscode/*`, and test with **Dev Containers: Rebuild Container**. Anything the image already provides (user, paths, aliases, pnpm, Chrome) is not repeated here.
- **Workflows** — edit `.github/workflows/*.yml`. The template must pass on a fresh checkout (Tier 1, no `pubspec.yaml`) and on an initialised project (Tier 3); every new job needs a tier condition and a place in the `ci-passed` job's `needs:`. `build.yml` is not a required check: it must skip cleanly until `pubspec.yaml` and `pubspec.lock` exist, then build **staging** for pull requests into `develop` and **production** for pull requests into and merges to `main`, with no edit needed in a generated project. `release.yml` publishes calendar-versioned releases here and `pubspec.yaml`-versioned ones in a project.
- **Git hooks** — edit `.husky/*`. They must never block a commit or push when `pubspec.yaml` is absent (see the Tier-1 guard in `.husky/pre-commit`).
- **Template follows the newest, projects freeze** — the template stays on `:latest` and the newest stable Flutter; a project runs `scripts/pin-image.sh` to freeze the dev image (the newest permanent `flutter-X.Y.Z.R` tag plus its digest) and its Flutter version. Do not pin the template itself.
- **Pinned versions** — GitHub Actions are pinned to a full commit SHA with a `# vX.Y.Z` comment, and `packageManager` (pnpm) equals the version the image pre-caches. Verify a version on its official channel before changing it, and name the bump in the pull request title.
- **Node stays on 24**, matching the image. `engines.node` and the Dependabot ignore rule must agree.
- **Shell scripts and hooks use LF line endings** and are executable in Git; a CRLF script fails inside the container.
- **Workflow hygiene** — least-privilege `permissions:`, `persist-credentials: false` on checkout, `timeout-minutes` on every job, and `${{ }}` values reach `run:` scripts through `env:`, never inline.
- **Keep the documentation true** — update `README.md` and `CHANGELOG.md` in the same pull request.

## Checking your change locally

```bash
bash -n scripts/*.sh
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable scripts/*.sh
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable --shell=sh .husky/commit-msg .husky/pre-commit .husky/pre-push
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -no-color
docker run --rm -v "$PWD:/repo:ro" -w /repo ghcr.io/zizmorcore/zizmor:latest --no-progress --offline .
docker compose config --quiet
echo "chore: example" | pnpm exec commitlint     # must pass
echo "bad message" | pnpm exec commitlint        # must fail
git ls-files -s scripts .husky .github/scripts   # every mode must be 100755 (new files: git add --chmod=+x <file>)
```

CI runs the same checks and more.

## Bugs and feature requests

Use the issue templates under **New issue**. Problems with the base Docker image itself belong in [`flutter-devcontainer`](https://github.com/alihaidar0/flutter-devcontainer/issues).

## Security issues

Do not open a public issue for a vulnerability. See [`SECURITY.md`](SECURITY.md).

## Conduct

Participation is governed by the [Code of Conduct](.github/CODE_OF_CONDUCT.md).
