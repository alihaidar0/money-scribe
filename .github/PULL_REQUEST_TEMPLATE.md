## Summary

<!-- What does this PR change and why? -->

## Type of change

- [ ] New feature
- [ ] Bug fix
- [ ] Refactor (no behaviour change)
- [ ] Tests only
- [ ] Database schema change (with a migration)
- [ ] Dependency or toolchain bump
- [ ] CI / dev container / repository automation
- [ ] Documentation only
- [ ] Other (describe above)

## How it was verified

<!-- Commands run and their result (format, analyze, test), and what was checked by hand on which platform. -->

## Screenshots

<!-- For UI changes: before and after, light and dark mode. Use invented data only. -->

## Breaking change

- [ ] This change breaks existing data or behaviour (use a `feat!:` or `fix!:` commit type and a `BREAKING CHANGE:` footer; the `breaking change` label is added automatically)

## Checklist

- [ ] This PR targets `develop` (only the `develop` → `main` release PR targets `main`)
- [ ] The **CI passed** check is green
- [ ] `dart format`, `flutter analyze --fatal-infos` and `flutter test` pass locally
- [ ] New or changed logic has tests (unit tests for domain logic, widget tests for screens, migration tests for database changes)
- [ ] Money is handled as integer minor units with a currency (no `double`), and dates are stored in UTC
- [ ] No real financial or personal data in code, tests, screenshots or logs
- [ ] User-facing text is in the ARB files, and the UI keeps semantic labels, contrast and scalable text
- [ ] New dependencies are pinned in `pubspec.yaml`, `pubspec.lock` is committed, and new GitHub Actions are pinned to a full commit SHA with a `# vX.Y.Z` comment
- [ ] `README.md`, `docs/` and `docs/steps.md` are updated where the change affects them
- [ ] The title is a Conventional Commit (labels are added from it and drive the release notes), or `skip-changelog` if this should not appear in them

## Related issues

<!-- Closes #123 -->
