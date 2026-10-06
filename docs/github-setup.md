# GitHub repository setup

Everything that can live in the repository (workflows, templates, labels, Dependabot, rulesets as JSON) is versioned under `.github/`. This guide covers the parts that can only be configured on GitHub. It applies twice: once to the `flutter-template` repository, and again to **every project created from it**, because the workflows and rulesets are copied along but the repository settings are not. Menu names change occasionally; the setting names below are what to look for.

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
| Template repository | **On** for `flutter-template` only (leave **Off** in projects created from it) |
| Features | Issues on · Wikis off · Projects off · Discussions off |
| Pull Requests → Allow merge commits | **On** (default message: pull request title and description) |
| Pull Requests → Allow squash merging | **Off** |
| Pull Requests → Allow rebase merging | **Off** |
| Pull Requests → Always suggest updating pull request branches | On |
| Pull Requests → Allow auto-merge | On |
| Pull Requests → Automatically delete head branches | On |
| Releases → Enable release immutability (if offered) | On |

For `flutter-template` also set a description, the website field if you have one, and these topics: `flutter`, `dart`, `android`, `firebase`, `docker`, `devcontainer`, `husky`, `commitlint`, `github-template`, `cicd`.

The default branch is `develop`, the integration branch, so every automatic pull request (Dependabot *version* and *security* updates) and every new pull request targets it by default, and `main` is reached only through the `develop` → `main` release pull request. A repository created from this template starts with the template's default branch (`develop`); create `main` from it once (section 6). Set the default branch under Settings → General → Default branch.

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

Every workflow also declares its own top-level `permissions:` block (`contents: read`, or none at all for `release.yml`); the jobs that need more request it explicitly: `release.yml` and `bootstrap-main.yml` (`contents: write`, to publish a release and to create the `main` branch), `labels.yml` (`issues: write`) and `pr-labels.yml` (`pull-requests: write`, to add labels from the pull request title; it needs the labels to exist; the **Labels** workflow creates them on the first push).

Workflows run on an explicit runner image (`ubuntu-24.04`) rather than `ubuntu-latest`. GitHub moves `ubuntu-latest` to a new Ubuntu release on its own schedule, which changes the toolchain under every job at once. Moving to a newer image is a deliberate edit of the `runs-on:` lines once the build has been verified on it.

## 3. Environments and secrets

The template needs **no secrets and no environments**: CI and the build workflow only use the automatic `GITHUB_TOKEN`. Add them per project when you add a deployment workflow:

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
- **CI passed** is the only required check. It always runs, fails if any job failed or was cancelled, and passes when jobs were skipped by design (the Flutter jobs on a project that has no `pubspec.yaml` yet, or the template guard in a generated project).
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

## 6. First-time bootstrap

### The template repository

1. Push `main` and `develop` (both exist before the rulesets are imported), then make `develop` the default branch (section 1).
2. Apply sections 1, 2 and 4.
3. Check that the **Labels** workflow created every label (Actions → Labels); if the labels are missing, run it with Actions → Labels → Run workflow.
4. Import the three rulesets (section 5).
5. Tick **Template repository** (section 1) once everything above is in place.
6. Verify (next section).

### Every project created from the template

1. **Use this template** → Create a new repository. Leave **Include all branches** unchecked: the new repository starts with one branch, the template's default (`develop`). `main` is created for you by the **Bootstrap main** workflow, the first time it is missing. It starts by itself on the repository's first commit, so `main` appears within a minute; if it did not run, start it through Actions → Bootstrap main → Run workflow. To do it by hand instead: `git push origin develop:main` (the `pre-push` hook only blocks a branch that already exists on the remote) or Branches → New branch. The workflow never touches an existing `main` and can be deleted once `main` exists. `main` must exist before the rulesets are imported and before the first release pull request.
   The **Labels** workflow creates every label by itself on that first push, because the first commit contains `.github/labels.yml`. Check Actions → Labels before the first pull requests (Dependabot opens its first pull requests within minutes and `pr-labels.yml` labels every pull request from its title, and both need the labels to exist); only if the labels are missing, run it with Actions → Labels → Run workflow, or `gh workflow run labels.yml`. Later edits of `.github/labels.yml` sync by themselves when they reach `develop` or `main`.
2. Update `.github/CODEOWNERS` with your username, and review `LICENSE`, `README.md`, `SECURITY.md` and `CONTRIBUTING.md`: they describe the template until you replace them. Delete `CHANGELOG.md`: your changelog is the GitHub Releases page, whose notes are generated from pull-request labels.
3. Run `flutter create --org <your.org> .` in the container, then `flutter pub get` so `pubspec.lock` exists (CI switches to its full Tier 3 checks on the next pull request).
4. Freeze the toolchain: run `scripts/pin-image.sh`. It pins the dev image in `docker-compose.yml` to the newest permanent `flutter-X.Y.Z.R` tag of your Flutter plus its digest and writes `environment: flutter: <version>` to `pubspec.yaml`, so CI and the builds use the same Flutter; it also refreshes `pubspec.lock`. Commit the three files. Then replace the template guide with your app's README: `scripts/init-readme.sh --description "What the app does."` (name, badges, platforms, stack versions, template release and license line are filled in from the project).
5. Uncomment the `pub` and `docker-compose` blocks in `.github/dependabot.yml` so package and image updates arrive as reviewed pull requests.
6. Apply sections 1, 2 and 4 (with **Template repository** left off), and import the rulesets once CI has run on `main` (section 5). The labels were created in step 1.
7. `image-contract.yml`, the `release` job and the template guard job are inert in a project (they only run where the repository is a template). Delete them if you like. The `app-release` job of `release.yml` publishes a GitHub Release for the version in `pubspec.yaml` when `main` changes.
8. Optional: set the repository variable `BUILD_IOS` to `true` to add an unsigned iOS compile check to `build.yml`, and follow [`android-signing.md`](android-signing.md) to sign the production Android build.
9. Add deployment workflows, environments and secrets when you need them (section 3).

## 7. Verify the protection works

- `git push origin main` and `git push origin develop` are rejected by the rulesets.
- A pull request from a topic branch into `main` fails **Verify source branch**, so **CI passed** is red and the pull request cannot merge.
- A pull request from `develop` into `main` offers only **Create a merge commit**.
- On a fresh checkout (no `pubspec.yaml`) **CI passed** is green, with every Flutter job skipped but **Lint**, **Format**, **Commit messages** and **Node dependency audit** still run.
- After `flutter create`, a pull request runs **Flutter format**, **Flutter analyze**, **Flutter test**, **Dependency audit** and **Flutter doctor**, and `build.yml` builds the APK, AAB and web app: a pull request into `develop` produces the `*-staging` artifacts, one into `main` the `*-production` artifacts.
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

# 2. create a topic branch (feat/ fix/ docs/ ci/ chore/ deps/)
git switch -c fix/example-topic

# 3. stage explicit paths, commit with a Conventional Commit message, push
git add path/to/changed-file
git commit -m "fix(scope): describe the change"
git push -u origin fix/example-topic

# 4. open a pull request into develop and merge it with "Create a merge commit"
```

If the email is not the one you want on this repository, set it for this repository only (never `--global`): `git config user.email "you@example.com"`. A repository-level setting (stored in `.git/config`) applies on the host and inside the dev container alike, because both work on the same folder.

If you use several GitHub accounts, give each one its own SSH host alias in `~/.ssh/config` (`Host github.com-<account>` with `HostName github.com`, `User git`, its own `IdentityFile` and `IdentitiesOnly yes`) and keep `origin` on that alias, for example `git@github.com-<account>:OWNER/REPO.git`. Do not rewrite it to `github.com` or `https://`, or the wrong key and account get used. The container never receives your private keys: VS Code forwards your host ssh-agent, and `welcome.sh` maps a `github.com-<account>` alias in the `origin` URL to `github.com` inside the container. Load only that account's key into the agent (`ssh-add -D`, then `ssh-add <key>`), because GitHub accepts the first key the agent offers.

Promotion: open a pull request `develop` → `main` (title `release: <summary>`) and merge it with a merge commit. That push runs **Build** (production APK, AAB and web artifacts, once the project has a `pubspec.lock`) and **Release**. In a project, **Release** publishes a GitHub Release for the version in `pubspec.yaml` (`1.4.0+7` → `v1.4.0`) with notes grouped by pull request label — raise the version in this pull request, otherwise nothing is published. In the template repository it publishes a calendar-versioned release (`vYYYY.MM.DD`); a promotion that only changes documentation produces none.

Once a week **Image contract** (template repository only) compares the template with the `flutter-devcontainer` image: the pnpm version Corepack must not download, the Node major, the image name and every documented shell alias. A red run means one of the two repositories moved on; fix it with a topic branch like any other change.
