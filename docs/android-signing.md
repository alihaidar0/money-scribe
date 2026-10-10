# Android signing

Money Scribe builds its Android release files in GitHub Actions and signs them with a key
that belongs to the environment: the **staging key** for the staging app and the **upload
key** for the production app ([`environments.md`](environments.md)). Nothing needs to be
uploaded to Google Play for this to work; the production key can be used for Play later
(section 7).

| Build | Signed with | Produces |
| --- | --- | --- |
| Pull request | the debug key (test build, no secret) | one APK and one App Bundle, kept 14 days |
| Push to `develop`, or manual staging run | the staging key | signed APKs and App Bundle in the draft release "Staging" |
| Push to `main`, or manual production run | the upload key | signed APKs and App Bundle in the draft release `v<version>` |

Only the signing job reads the secrets. Each GitHub environment is restricted to one
branch, so a pull request or another branch can never read a key. Keeping two keys means a
leak of the staging key cannot sign a production build.

## 1. Create the two keystores (once, on your machine)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
        -storetype JKS -keysize 2048 -validity 10000 -alias upload

keytool -genkey -v -keystore ~/staging-keystore.jks -keyalg RSA \
        -storetype JKS -keysize 2048 -validity 10000 -alias staging
```

Keep the files outside the repository, or in the folder `.signing/` of the workspace, which
Git ignores and which survives a rebuild of the dev container (use
`.signing/upload-keystore.jks` instead of `~/upload-keystore.jks` in the commands). Use a
different password for each, without a backslash. Back up both `.jks` files and all
passwords in a password manager straight away: the dev container's home folder is lost when
the container is rebuilt, and without a key no later build can carry the same signature. The
repository ignores `*.jks`, `*.keystore` and `android/key.*.properties`; never commit them.

Print the certificate fingerprint (SHA-256) of each key. It is public information and is
used in section 4:

```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload | grep "SHA256:"
keytool -list -v -keystore ~/staging-keystore.jks -alias staging | grep "SHA256:"
```

## 2. Sign a build locally (optional check)

Create `android/key.production.properties` (and `android/key.staging.properties` the same
way, with its own passwords, alias and file); both are ignored by Git:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

`android/app/build.gradle.kts` signs the release build of a flavor with its key when the file
exists, and with the debug key when it does not, so builds without the file keep working.
After changing the Gradle file or a key, run `flutter clean`. Then build and check which key
signed the files:

```bash
flutter build apk --release --flavor production --split-per-abi
flutter build appbundle --release --flavor production
"$ANDROID_HOME"/build-tools/*/apksigner verify --print-certs build/app/outputs/flutter-apk/app-*arm64-v8a*-release.apk
keytool -printcert -jarfile build/app/outputs/bundle/productionRelease/app-production-release.aab
```

The certificate must be yours, not `CN=Android Debug`.

## 3. Prepare GitHub (once)

Create two environments under **Settings → Environments → New environment**:

| Environment | Deployment branches and tags |
| --- | --- |
| `staging` | selected branches and tags: `develop` only |
| `production` | selected branches and tags: `main` only (optionally require a reviewer) |

On each environment, untick **Allow administrators to bypass configured protection rules**
and click **Save protection rules**, so nobody can skip the branch restriction. Leave
**Required reviewers** and **Wait timer** off for `staging` (they would hold every build on
`develop`); for `production` a reviewer is optional.

Each environment gets the same four **secrets**, with the values of its own key
(`base64 -w0 <file>.jks`; on macOS `base64 -i <file>.jks`):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the keystore, base64 encoded |
| `ANDROID_STORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_PASSWORD` | the key password |
| `ANDROID_KEY_ALIAS` | `staging` or `upload` |

and one **variable** (not a secret):

| Variable | Value |
| --- | --- |
| `ANDROID_CERT_SHA256` | the SHA-256 fingerprint of that environment's key (section 1) |

With the variable set, a build fails if any file is signed with another key. Without it, the
build still fails for the debug key and prints the fingerprint in the run summary.

## 4. Builds and releases

[`environments.md`](environments.md) describes what each event builds and how the draft
releases work. In short: a merge into `develop` refreshes the draft "Staging", and a merge into
`main` refreshes the draft `v<version>`, which you publish when it is final. The first
production build comes with the first pull request from `develop` into `main`, so set up
section 3 before it. The signed files are also kept for 30 days as the workflow artifact
`android-release-signed-<environment>`.

Raise the version in `pubspec.yaml` for every new release. The build number needs no
attention: CI uses its own run number.

## 5. Which APK to install

| Phone | File |
| --- | --- |
| Almost every current phone | `arm64-v8a` |
| Older 32-bit phones | `armeabi-v7a` |
| Emulators on a PC | `x86_64` |

Install with `adb install <file>.apk` or copy the file to the phone and open it. The staging
and production apps can be installed together. Signed with a stable key, each one updates in
place.

## 6. Debug symbols

The signed builds are obfuscated, so a stack trace shows meaningless names. The symbol files
that translate it back are kept as the workflow artifact
`android-debug-symbols-<environment>` for 30 days (the repository's artifact retention). They
are not attached to a release, because the repository is public and they would undo the
obfuscation. To read a trace:

```bash
flutter symbolize -i stack-trace.txt -d build/symbols/app.android-arm64.symbols
```

Download the artifact into `build/symbols/` first. The app sends no crash reports, so this
only matters for traces you collect yourself.

## 7. Google Play (later)

The production key works as the Play **upload key**. With Play App Signing (the default), you
upload the `.aab` signed with it and Google re-signs what users receive with its own key. Two
consequences:

- The first release of a new app is set up in the Play Console by hand; automating uploads
  comes afterwards (for example with fastlane `supply` and a service-account key stored as an
  environment secret).
- An APK installed from Play carries Google's signature, so it cannot be updated over an APK
  installed from GitHub (and the other way round); uninstall one before installing the other.
  Play can also accept your own key as the app signing key, but only when the app is first
  set up; check the Play Console help before relying on it.

The application ID `com.alihaidar.moneyscribe` cannot be changed after the first upload. The
staging app has its own ID, so it can get its own Play listing or internal track later without
touching the production app.
