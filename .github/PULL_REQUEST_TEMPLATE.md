## Summary

<!-- What does this PR change and why? -->

## Type of change

- [ ] Dev container / compose / VS Code configuration
- [ ] GitHub Actions workflow / repository automation
- [ ] Husky / commitlint / git hook
- [ ] Dependency version bump
- [ ] Documentation only
- [ ] Other (describe above)

## How it was verified

<!-- Commands run and their result, or why CI alone is enough. -->

## Breaking change

- [ ] This change forces projects generated from the template to adapt (use a `feat!:` or `fix!:` commit type and a `BREAKING CHANGE:` footer; the `breaking change` label is added automatically)

## Checklist

- [ ] This PR targets `develop` (only the `develop` → `main` release PR targets `main`)
- [ ] The **CI passed** check is green
- [ ] `ci.yml` still passes, and `build.yml` still skips, on a fresh (Tier 1) checkout, so the template never fails before a project exists
- [ ] A change to `build.yml` or `release.yml` still builds staging for pull requests into `develop` and production for `main`, and needs no edit in a generated project
- [ ] No Flutter application code (`lib/`, `pubspec.yaml`, `android/`, `ios/`, `web/`) was introduced — this repo stays a zero-code template
- [ ] New or updated GitHub Actions are pinned to a full commit SHA with a `# vX.Y.Z` comment, and any pinned version change is named in the PR title (see [CONTRIBUTING.md](../CONTRIBUTING.md))
- [ ] Anything that must match the `flutter-devcontainer` image (pnpm and Node versions, aliases, image name) still does, or the image change is linked below
- [ ] `README.md` and `CHANGELOG.md` describe the change where users would notice it
- [ ] The title is a Conventional Commit (labels are added from it and drive the release notes), or `skip-changelog` if this should not appear in them

## Related issues

<!-- Closes #123 -->
