# Environments and releases

Money Scribe has two environments. Each one is a Flutter flavor with its own app, so both
can be installed on one phone, and each one has its own signing key, GitHub environment and
release.

| | **Staging** | **Production** |
| --- | --- | --- |
| Git branch | `develop` | `main` |
| Flutter flavor and `APP_ENV` | `staging` | `production` |
| Android application ID | `com.alihaidar.moneyscribe.staging` | `com.alihaidar.moneyscribe` |
| App name | Money Scribe Staging | Money Scribe |
| Icon | the icon with an amber badge | the icon |
| Signing key | the staging key | the upload key |
| GitHub environment | `staging`, restricted to `develop` | `production`, restricted to `main` |
| Release | the draft "Staging" (tag `staging`) | the draft `v<version>` |
| Google Cloud and Firebase project | one for staging | one for production |

The production ID has no suffix because it is the ID of the app in the stores and cannot be
changed once published. The signing keys are described in
[`android-signing.md`](android-signing.md).

## Working with the flavors

`pubspec.yaml` sets `default-flavor: staging`, so a plain `flutter run` starts the staging
app. Name the flavor for anything else (Android only; the web has no flavors):

```bash
flutter run                          # staging
flutter run --flavor production
flutter build apk --release --flavor production --split-per-abi
flutter build appbundle --release --flavor production
```

In Dart, `AppEnvironment.current` (`lib/app/environment/app_environment.dart`) tells the app
which environment it was built for. It reads `APP_ENV` (`--dart-define`, which CI passes to
every build, web included) first, then the Flutter flavor (`appFlavor`), and counts anything
else as staging, so a misconfigured build never counts as production. VS Code has a launch
configuration for each flavor on the host emulator.

The web build has no flavors: it uses `--dart-define=APP_ENV=<environment>` only.

## What the build does

The **Build** workflow (`.github/workflows/build.yml`) decides by event:

| Event | Result |
| --- | --- |
| Pull request into `develop` | Staging test build (debug key, no secrets), kept 14 days |
| Merge into `develop` | Signed staging build; its files replace those of the draft release "Staging" |
| Pull request into `main` | Production test build (debug key, no secrets), kept 14 days; test this one before merging |
| Merge into `main` | Signed production build; its files go into the draft release `v<version>` |
| Manual run (Actions → Build → Run workflow) | Signed build of the chosen environment, from `develop` for staging or `main` for production |

A signed build produces one APK per CPU type (`arm64-v8a`, `armeabi-v7a`, `x86_64`), the
App Bundle, a checksum file and the web build. It is obfuscated, and the job checks that
every file is signed with the right key.

**Build number.** Signed builds use the run number of the workflow as the Android version
code, so it only ever increases and nobody edits `+N` in `pubspec.yaml`
for CI builds. The release name comes from the version in `pubspec.yaml` without the build
number, and the release notes show the build number and the commit.

**Staging release.** One draft called "Staging" (tag `staging`) holds the files of the latest
build on `develop`. Every merge replaces its files and notes. Never publish it: a published
release is immutable, and the build would then leave it alone.

**Production release.** The draft `v0.1.0` belongs to version `0.1.0` (any build number). A
new build of the same version replaces its files and notes. When the version is final,
publish the draft on the Releases page. A published release is immutable (repository
setting and the `tags-protect` ruleset), so the build only warns about it; to release again
raise the version in `pubspec.yaml` and merge into `main`. Drafts are visible to people with
write access to the repository only.

## Not set up yet

- **iOS flavors.** Flutter needs Xcode schemes named `staging` and `production`, build
  configurations and a bundle identifier per flavor
  ([Flutter guide](https://docs.flutter.dev/deployment/flavors-ios)); that needs a Mac. Until
  then `default-flavor` makes an iOS build fail, so the opt-in iOS job of `build.yml` waits for
  it. The iOS bundle IDs will mirror the Android IDs.
- **Google Play.** Later, a merge into `main` can also upload the App Bundle (first to an
  internal or closed track); see the end of [`android-signing.md`](android-signing.md).
- **Firebase Cloud Messaging.** Firebase is used for push notifications only; the backend
  (sign-in and data storage) is still undecided, and Analytics and crash reporting stay off.
  Each flavor gets its own `google-services.json` in `android/app/src/<flavor>/` (the file
  name is ignored by Git), from one Firebase project per environment, registered with the
  application IDs above. The build workflow writes the file from a secret of the GitHub
  environment; test builds of pull requests have no secrets and use a placeholder file with
  invented values. Until the backend can send messages, push messages are tested from the
  Firebase console. A notification never contains amounts, names or other financial data.
