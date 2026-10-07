# GitHub repository setup

Everything that can live in the repository (workflows, issue and pull request forms, labels, Dependabot, rulesets as JSON) is versioned under `.github/`. This guide covers the parts of the `money-scribe` repository that can only be configured on GitHub. Menu names change occasionally; the setting names below are what to look for.

## Branch model

```text
feat/*  fix/*  docs/*  ci/*  chore/*  deps/*
        │  pull request, merge commit
        ▼
     develop   ← integration branch, protected
        │  pull request, merge commit, source must be `develop`
        ▼
       main    ← stable branch, protected
        │  push
        ▼
  build.yml (APK, AAB, web artifacts) + release.yml (GitHub Release)
```

- Nobody pushes to `develop` or `main` directly (rulesets enforce it; the `pre-push` hook blocks both locally as a convenience).
- `develop` is the default branch; only a pull request from `develop` may target `main` (the **Verify source branch** job of `CI passed`).
- Every change goes on a topic branch and opens a pull request against `develop`.
- When `develop` is verified, one pull request `develop` → `main` promotes it.
- Both branches use **merge commits** (no squash, no rebase). Squashing into `main` rewrites `develop`'s commits and makes the next promotion conflict.

A pull request into `main` from any branch other than `develop` fails the **Verify source branch** job. GitHub rulesets cannot restrict a pull request's source branch, so the rule is enforced in `ci.yml` and made mandatory through the required **CI passed** check.

## 1. Settings → General

| Setting | Value |
| --- | --- |
| Default branch | `develop` |
| Template repository | **Off** |
| Features | Issues on · Wikis off · Projects off · Discussions off |
| Pull Requests → Allow merge commits | **On** (default message: pull request title and description) |
| Pull Requests → Allow squash merging | **Off** |
| Pull Requests → Allow rebase merging | **Off** |
| Pull Requests → Always suggest updating pull request branches | On |
| Pull Requests → Allow auto-merge | On |
| Pull Requests → Automatically delete head branches | On |
| Releases → Enable release immutability (if offered) | On |

Also set the description ("Money Scribe: Budget & Expense Tracker") and these topics: `flutter`, `dart`, `android`, `ios`, `personal-finance`, `budget`, `expense-tracker`, `offline-first`.

The default branch is `develop`, the integration branch, so every automatic pull request (Dependabot *version* and *security* updates) and every new pull request targets it by default, and `main` is reached only through the `develop` → `main` release pull request. Set it under Settings → General → Default branch.

## 2. Settings → Actions → General

| Setting | Value |
| --- | --- |
| Actions permissions | Allow `<your user>`, and select non-`<your user>`, actions and reusable workflows |
| Allow actions created by GitHub | On |
| Allow Marketplace actions by verified creators | Off |
| Allowed actions (one per line) | `raven-actions/actionlint@*`, `zizmorcore/zizmor-action@*`, `google/osv-scanner-action/*` |
| Require actions to be pinned to a full-length commit SHA | **On** |
| Artifact and log retention | 30 days |
| Fork pull request workflows | Require approval for all external contributors |
| Send write tokens / secrets to fork pull request workflows | Off |
| Workflow permissions | **Read repository contents and packages permissions** |
| Allow GitHub Actions to create and approve pull requests | Off |

Every workflow also declares its own top-level `permissions:` block (`contents: read`, or none at all for `release.yml`); the jobs that need more request it explicitly: `release.yml` (`contents: write`, to publish a release), `labels.yml` (`issues: write`, to sync `.github/labels.yml` when it changes) and `pr-labels.yml` (`pull-requests: write`, to add labels from the pull request title).

Workflows run on an explicit runner image (`ubuntu-24.04`) rather than `ubuntu-latest`. GitHub moves `ubuntu-latest` to a new Ubuntu release on its own schedule, which changes the toolchain under every job at once. Moving to a newer image is a deliberate edit of the `runs-on:` lines once the build has been verified on it.

## 3. Environments and secrets

CI and the build workflow need **no secrets and no environments**: they only use the automatic `GITHUB_TOKEN`. Add them when release signing or a deployment workflow is added:

- Create an environment per deployment target (for example `production`), restrict it to `main` under **Deployment branches and tags**, and put the target's credentials there as environment secrets rather than repository secrets (a repository secret stays readable from any branch).
- Optionally require a reviewer on the environment for production deployments.
- Never commit a keystore, signing password or service-account key; any file in the repository is readable by everyone who can read the repository, so secrets belong in environment secrets.

## 4. Settings → Advanced Security (Code security)

| Feature | Value |
| --- | --- |
| Dependency graph | On |
| Dependabot alerts | On |
| Dependabot security updates | On |
| Grouped security updates | On |
| Dependabot version updates | Driven by `.github/dependabot.yml` (weekly, grouped, 7-day cooldown, pull requests to `develop`) |
| Secret scanning | On |
| Push protection | **On** |
| Private vulnerability reporting | **On** (`SECURITY.md` links to it) |
| Code scanning → CodeQL | Default setup, language **Actions** (analyses the workflow files; CodeQL does not cover Dart) |

## 5. Rulesets

Settings → Rules → Rulesets → **New ruleset** → **Import a ruleset**, once per file:

| File | Targets | What it enforces |
| --- | --- | --- |
| `.github/rulesets/main-protect.json` | `main` | No deletion, no force-push, pull request required (merge commits only, conversations resolved, stale approvals dismissed), required check **CI passed** |
| `.github/rulesets/develop-protect.json` | `develop` | Same as `main`, and the branch must be up to date with `develop` before merging |
| `.github/rulesets/tags-protect.json` | `v*` tags | Released tags cannot be moved or deleted |

Notes:

- **The bypass list is empty** on purpose, so the rules apply to administrators too.
- **The required check is bound to GitHub Actions** (`integration_id` 15368), so no other app or status API can report a green **CI passed** on its own.
- **Required approvals are 0.** A pull request author cannot approve their own pull request, so requiring 1 approval would stop a solo maintainer from merging at all. Once a second maintainer joins, set `required_approving_review_count` to `1` and `require_code_owner_review` to `true` (`CODEOWNERS` is already in place), then import the file again.
- **`main-protect` does not require "up to date"** (`strict_required_status_checks_policy: false`). After every promotion `main` holds one merge commit that `develop` does not, so a strict rule would force a `main` → `develop` sync before each release.
- **CI passed** is the only required check. It always runs, fails if any job failed or was cancelled, and passes when jobs were skipped by design (for example **Verify source branch** on a pull request into `develop`).
- Import the rulesets *after* the workflows exist on `main` and have run once, otherwise nothing has reported the required check yet.
- Rulesets are free on public repositories; on private repositories they depend on your GitHub plan, so check that before relying on them.

Optional, if you prefer scripting over clicking, with the GitHub CLI authenticated for the repository (run it from the repository root):

```bash
gh api repos/OWNER/REPO --method PATCH \
  -F allow_merge_commit=true -F allow_squash_merge=false -F allow_rebase_merge=false \
  -F allow_auto_merge=true -F delete_branch_on_merge=true \
  -F has_wiki=false -F has_projects=false -F has_discussions=false
for ruleset in main-protect develop-protect tags-protect; do
  gh api repos/OWNER/REPO/rulesets --method POST --input ".github/rulesets/$ruleset.json"
done
```

## 6. First-time setup

1. `main` and `develop` exist on GitHub, and `develop` is the default branch (section 1).
2. The labels are created from `.github/labels.yml` by the **Labels** workflow, which runs whenever that file changes on `develop` or `main` (Actions → Labels → Run workflow to sync them by hand).
3. Open the first pull request into `develop` and let CI run, so the **CI passed** check has reported once.
4. Apply sections 1, 2 and 4.
5. Import the three rulesets (section 5).
6. Optional: set the repository variable `BUILD_IOS` to `true` to add an unsigned iOS compile check to `build.yml`.
7. Before the first store release, follow [`android-signing.md`](android-signing.md) to sign the production Android build (section 3).
8. Verify (next section).

## 7. Verify the protection works

- `git push origin main` and `git push origin develop` are rejected by the rulesets.
- A pull request from a topic branch into `main` fails **Verify source branch**, so **CI passed** is red and the pull request cannot merge.
- A pull request from `develop` into `main` offers only **Create a merge commit**.
- A pull request runs **Lint**, **Format**, **Commit messages** and **Node dependency audit**, and **Flutter format**, **Flutter analyze**, **Flutter test**, **Dependency audit** and **Flutter doctor**, and `build.yml` builds the APK, AAB and web app: a pull request into `develop` produces the `*-staging` artifacts, one into `main` the `*-production` artifacts.
- A commit message such as `Fixed stuff` fails **Commit messages**.

## 8. Everyday workflow

```bash
# 0. confirm the identity the commit will use, and where the push will go
git config user.name
git config user.email
git config --show-origin --get user.email   # which config file the email comes from
git remote -v

# 1. start from an up-to-date develop
git switch develop
git pull --ff-only

# 2. create a topic branch (feat/ fix/ docs/ ci/ chore/ deps/ refactor/ test/)
git switch -c fix/example-topic

# 3. stage explicit paths, commit with a Conventional Commit message, push
git add path/to/changed-file
git commit -m "fix(scope): describe the change"
git push -u origin fix/example-topic

# 4. open a pull request into develop and merge it with "Create a merge commit"
```

If the email is not the one you want on this repository, set it for this repository only (never `--global`): `git config user.email "you@example.com"`. A repository-level setting (stored in `.git/config`) applies on the host and inside the dev container alike, because both work on the same folder.

If you use several GitHub accounts, give each one its own SSH host alias in `~/.ssh/config` (`Host github.com-<account>` with `HostName github.com`, `User git`, its own `IdentityFile` and `IdentitiesOnly yes`) and keep `origin` on that alias, for example `git@github.com-<account>:OWNER/REPO.git`. Do not rewrite it to `github.com` or `https://`, or the wrong key and account get used. The container never receives your private keys: VS Code forwards your host ssh-agent, and `welcome.sh` maps a `github.com-<account>` alias in the `origin` URL to `github.com` inside the container. Load only that account's key into the agent (`ssh-add -D`, then `ssh-add <key>`), because GitHub accepts the first key the agent offers.

Promotion: open a pull request `develop` → `main` (title `release: <summary>`) and merge it with a merge commit. That push runs **Build** (production APK, AAB and web artifacts) and **Release**, which publishes a GitHub Release for the version in `pubspec.yaml` (`1.4.0+7` → `v1.4.0`) with notes grouped by pull request label. Raise the version in this pull request, otherwise nothing is published; a promotion that only changes documentation produces none.
