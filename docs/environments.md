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
| Testers | the group `testers` of the staging project, newest build only | the group `testers` of the production project |

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

**The address of the server** (`API_BASE_URL`) is a variable of the GitHub environment and a line in
the local, ignored file `.env.<environment>`; the signed Android build writes the file from the
variable. An empty value means "no server": the app keeps its fake data. See
[`backend-api.md`](backend-api.md), section 6.

**The public Turnstile site key** (`TURNSTILE_SITE_KEY`) of the sign-in bot check is kept the same way:
a variable (not a secret) of the GitHub environment and a line in `.env.<environment>`. Its secret
key belongs to the backend alone.

## What the build does

The **Build** workflow (`.github/workflows/build.yml`) decides by event:

| Event | Result |
| --- | --- |
| Pull request into `develop` | Staging test build (debug key, no secrets), kept 14 days |
| Merge into `develop` | Signed staging build; its files replace those of the draft release "Staging", and the arm64-v8a APK goes to the testers (Firebase App Distribution) |
| Pull request into `main` | Production test build (debug key, no secrets), kept 14 days; test this one before merging |
| Merge into `main` | Signed production build; its files go into the draft release `v<version>` and the arm64-v8a APK to the testers |
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
release is immutable, and the build would then leave it alone. GitHub renames the tag of a
draft once the draft has been updated (to `untagged-…`), so the build finds a draft by its tag
or by its title. If more than one release matches, the build uses the newest and warns; delete
the others on the Releases page.

**Production release.** The draft `v0.1.0` belongs to version `0.1.0` (any build number). A
new build of the same version replaces its files and notes. When the version is final,
publish the draft on the Releases page. A published release is immutable (repository
setting and the `tags-protect` ruleset), so the build only warns about it; to release again
raise the version in `pubspec.yaml` and merge into `main`. Drafts are visible to people with
write access to the repository only.

## Testers: Firebase App Distribution

Draft releases are visible only to people with write access, so testers get their builds
from Firebase App Distribution instead. A tester opens the invitation link of the group
`testers` once, signs in with a Google account, and then installs each new build from the
App Distribution page or the notification. Nothing of Firebase is added to the app; the
service is used by the build workflow only (job `distribute-firebase`). The complete setup,
with every console step and command, is in
[`firebase-app-distribution.md`](firebase-app-distribution.md).

- **What is sent.** The arm64-v8a APK of the signed build, with the build number, the version
  and the commit in the release notes. **Staging** keeps only its newest release: after each
  upload the job deletes the older ones. **Production** keeps its history (Firebase removes a
  release after 150 days).
- **No stored key.** The job signs in to Google Cloud with the OIDC token of the run
  (Workload Identity Federation) and acts as a service account whose only role is
  Firebase App Distribution Admin. Each Firebase project has its own provider, which accepts
  this repository and the GitHub environment of that project only, and the environments are
  restricted to one branch each.
- **Variables of each GitHub environment** (none is a secret): `FIREBASE_APP_ID` (the Android
  app ID from the Firebase console), `GCP_WORKLOAD_IDENTITY_PROVIDER` (the full name of the
  provider) and `GCP_SERVICE_ACCOUNT` (the email address of the service account). While all
  three are empty the job is skipped and the build still passes; a wrong value stops it.
- **The invitation link** comes from Firebase console → App Distribution → Testers & Groups →
  `testers` → Invite links. Anyone with the link can join the group, so share it with the
  people who should have the builds and revoke it there if it spreads.

## Not set up yet

- **iOS flavors.** Flutter needs Xcode schemes named `staging` and `production`, build
  configurations and a bundle identifier per flavor
  ([Flutter guide](https://docs.flutter.dev/deployment/flavors-ios)); that needs a Mac. Until
  then `default-flavor` makes an iOS build fail, so the opt-in iOS job of `build.yml` waits for
  it. The iOS bundle IDs will mirror the Android IDs.
- **Google Play.** Later, a merge into `main` can also upload the App Bundle (first to an
  internal or closed track); see the end of [`android-signing.md`](android-signing.md).
- **Secure window (Android).** The production build sets `FLAG_SECURE` on its window
  (`SECURE_WINDOW` in `android/app/build.gradle.kts`, read by `MainActivity`): the app is blank in the
  recent-apps list and cannot be captured by a screenshot or a screen recording. Staging builds leave it
  off, so the screens can be checked. iOS has no flavors yet; hiding the app in its app switcher comes
  with the iOS work.
- **Firebase Cloud Messaging.** In the app, Firebase is used for push notifications only (the
  build workflow also uses App Distribution, see above); the backend
  (sign-in and data storage) is still undecided, and Analytics and crash reporting stay off.
  Each flavor gets its own `google-services.json` in `android/app/src/<flavor>/` (the file
  name is ignored by Git), from one Firebase project per environment, registered with the
  application IDs above. The build workflow writes the file from a secret of the GitHub
  environment; test builds of pull requests have no secrets and use a placeholder file with
  invented values. Until the backend can send messages, push messages are tested from the
  Firebase console. A notification never contains amounts, names or other financial data. The app
  deletes the push token of the device whenever the person is signed out (sign-out, account deletion, a
  session the server ended); the Firebase installation ID is not deleted by that and is dropped by
  Firebase when the installation is inactive.

  To build an Android flavor on your own machine, download its file from the Firebase
  console (Project settings → General → Your apps) and save it as
  `android/app/src/<flavor>/google-services.json`. Without it the build stops with a message
  from the Google services plugin; only the flavor being built needs its file.
