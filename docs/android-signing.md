# Android release signing

`build.yml` builds the APK and the App Bundle without a signing key: a release build
with no signing configuration is signed with the **debug key**, which is fine for
testing and not accepted by the Play Store. This guide adds real signing to a project
created from the template. It is a per-project step because the key, the Play
Console and the Gradle files belong to the app, not to the template.

The snippets are adapted from the official
[Flutter Android deployment guide](https://docs.flutter.dev/deployment/android) and
have not been run in this template; check them against the guide for your Flutter
version.

The plan: sign **only** the production build that runs when `main` is updated, keep the
key in a GitHub **environment** that only `main` can use, and leave staging and pull
request builds debug-signed so they never touch a secret.

## 1. Create the upload keystore (once, on your machine)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
        -storetype JKS -keysize 2048 -validity 10000 -alias upload
```

Back the file and its passwords up somewhere safe (a password manager). With **Play App
Signing** (the default for new apps) this is only the *upload* key, and Google can reset
it if you lose it. The repository ignores `*.jks`, `*.keystore` and
`android/key.properties`; never commit them.

## 2. Teach Gradle to read the key, without requiring it

Create `android/key.properties` locally (it is ignored by Git) for signed local builds:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

In `android/app/build.gradle.kts`, load it and fall back to the debug key when the file
is absent, so builds without the secret (pull requests, staging, a fresh clone) keep
working:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
```

## 3. Store the key in a protected environment

1. **Settings → Environments → New environment** named `production`.
2. Under **Deployment branches and tags**, allow only `main` (see
   [`github-setup.md`](github-setup.md) §3). Optionally require a reviewer.
3. Add environment secrets:

   | Secret | Value |
   | --- | --- |
   | `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/upload-keystore.jks` (on macOS: `base64 -i ~/upload-keystore.jks`) |
   | `ANDROID_STORE_PASSWORD` | the keystore password |
   | `ANDROID_KEY_PASSWORD` | the key password |
   | `ANDROID_KEY_ALIAS` | `upload` |

Environment secrets are only handed to jobs that run on an allowed branch, so a pull
request can never read them.

## 4. Add a signing job to `build.yml`

Add this job next to `build` in your project's `.github/workflows/build.yml`. It runs
only for pushes to `main` (the merged production release), is the only job that uses the
environment, and uploads a signed bundle next to the debug-signed one. Copy the
`Checkout`, `Set up Flutter` and `flutter pub get` steps from the `build` job above it.

```yaml
  build-android-signed:
    name: Android AAB (signed)
    needs: detect
    if: needs.detect.outputs.ready == 'true' && github.event_name == 'push'
    environment: production
    runs-on: ubuntu-24.04
    timeout-minutes: 25
    steps:
      # - Checkout, Set up Flutter and `flutter pub get --enforce-lockfile`:
      #   copy them from the `build` job.

      - name: Prepare signing
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/upload-keystore.jks"
          {
            echo "storePassword=$STORE_PASSWORD"
            echo "keyPassword=$KEY_PASSWORD"
            echo "keyAlias=$KEY_ALIAS"
            echo "storeFile=$RUNNER_TEMP/upload-keystore.jks"
          } > android/key.properties

      - name: Build signed App Bundle
        run: flutter build appbundle --release --dart-define=APP_ENV=production

      - name: Upload signed App Bundle
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: android-aab-production-signed
          path: build/app/outputs/bundle/release/app-release.aab
          if-no-files-found: error
          retention-days: 30
```

Keep the `uses:` SHA the same as in the other jobs (Dependabot updates them together).
If you use `env/production.json`, add `--dart-define-from-file=env/production.json` to
the build command as the `build` job does.

Uploading the signed bundle to the Play Console (for example with the Play Developer API
or Fastlane) is a deployment step and is added per project, in this job or a separate
workflow.
