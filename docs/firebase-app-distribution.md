# Firebase App Distribution for testers

Draft GitHub Releases are visible only to people with write access to the repository. Testers
get their builds from **Firebase App Distribution** instead: the build workflow uploads the
arm64-v8a APK of every signed build, and a tester opens one invitation link, signs in with a
Google account and installs from there. Nothing of Firebase is added to the app; the service
is used by the build workflow only (job `distribute-firebase` in `.github/workflows/build.yml`).

| | Staging | Production |
| --- | --- | --- |
| Firebase and Google Cloud project | the staging project | the production project |
| GitHub environment | `staging` (branch `develop`) | `production` (branch `main`) |
| Releases kept in App Distribution | only the newest (older ones are deleted after each upload) | all (Firebase removes a release after 150 days) |

The setup is done **once per environment**, in this order: the Firebase console (section 1), Google
Cloud (section 2), GitHub (section 3). Nothing in the repository changes between environments.

No key is stored anywhere. The job signs in to Google Cloud with the identity token of the
workflow run (Workload Identity Federation) and acts as a service account whose only role is
*Firebase App Distribution Admin*. The provider of each project accepts this repository and the
GitHub environment of that project only, and each GitHub environment is restricted to one branch.

## 1. Firebase console (per project)

1. Open the [Firebase console](https://console.firebase.google.com) and select the project of the
   environment (the staging or the production one).
2. In the left menu open **DevOps & Engagement** → **App Distribution** (or use **Search for
   products**) and click **Get started**. Do not use **Release Monitoring**: that page is
   Crashlytics, which stays off. Leave the banner "Opt in entire project" alone: it is the
   separate App Testing agent.
3. Open the **Testers & Groups** tab → **Add group**. Name it `testers` and check that the alias
   under the name reads `testers`: the workflow sends every build to that alias.
4. Copy the **App ID** of the Android app of this environment: gear icon → **Project settings** →
   **General** → **Your apps** → the app `com.alihaidar.moneyscribe.staging` (staging) or
   `com.alihaidar.moneyscribe` (production) → **App ID**. It looks like
   `1:<project number>:android:<hex>`. You need it in section 3.

## 2. Google Cloud (per project)

Open the [Google Cloud console](https://console.cloud.google.com), select the same project and
click **Activate Cloud Shell** (the `>_` icon, top right); `gcloud` is installed and signed in
there. Run the blocks in order. A `does not exist` error right after something was created is
a short propagation delay: wait 30 seconds and run only that command again.

Set the values of the environment first (the project ID is on the project's Settings page; use
`staging` or `production` for `ENVIRONMENT`, matching the GitHub environment):

```bash
PROJECT_ID=<project ID of this environment>
ENVIRONMENT=staging
REPO=alihaidar0/money-scribe
gcloud config set project "$PROJECT_ID"
gcloud projects list --format="table(projectId,name,projectNumber)"   # check the project
```

Turn on the APIs the upload needs, create the service account and give it its one role:

```bash
gcloud services enable firebaseappdistribution.googleapis.com iam.googleapis.com \
  iamcredentials.googleapis.com sts.googleapis.com

gcloud iam service-accounts create app-distribution \
  --display-name "App Distribution uploads from GitHub"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:app-distribution@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role roles/firebaseappdistro.admin \
  --condition=None
```

Create the identity pool and the provider that trusts GitHub. The condition lets in this
repository and this GitHub environment only, and nothing else:

```bash
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

gcloud iam workload-identity-pools create github \
  --location global --display-name "GitHub Actions"

gcloud iam workload-identity-pools providers create-oidc github-actions \
  --location global --workload-identity-pool github \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.environment=assertion.environment" \
  --attribute-condition "assertion.repository == '${REPO}' && assertion.environment == '${ENVIRONMENT}'"
```

Allow identities of the pool for this repository to act as the service account, then print the two
values for section 3:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  "app-distribution@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO}"

echo "GCP_WORKLOAD_IDENTITY_PROVIDER=projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/providers/github-actions"
echo "GCP_SERVICE_ACCOUNT=app-distribution@${PROJECT_ID}.iam.gserviceaccount.com"
```

Check the result at any time:

```bash
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:app-distribution@" \
  --format="table(bindings.role)"          # only roles/firebaseappdistro.admin
gcloud iam workload-identity-pools providers describe github-actions \
  --location global --workload-identity-pool github \
  --format="value(attributeCondition)"     # the repository and the environment
```

## 3. GitHub (per environment)

Repository → **Settings** → **Environments** → the environment (`staging` or `production`) →
**Environment variables** → **Add environment variable**, three times. They are variables, not
secrets: none of them lets anyone do anything without the identity token of a run that the
provider accepts. Paste each value as printed, with no quotes or spaces.

| Variable | Value |
| --- | --- |
| `FIREBASE_APP_ID` | the App ID from section 1, step 4 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | the first line printed at the end of section 2 |
| `GCP_SERVICE_ACCOUNT` | the second line printed at the end of section 2 |

While all three are empty, the job is skipped and the build still passes; a value of the wrong
shape stops the job with a message that names the variable.

## 4. Check it and invite the testers

1. A merge into `develop` (staging) or `main` (production) that changes the app, or a manual run
   (**Actions** → **Build** → **Run workflow**), starts the build. In the run, the job
   **Firebase App Distribution (staging)** shows in its summary which build was sent. On
   staging it also says how many older releases were removed.
2. In the Firebase console → **App Distribution** → **Releases**, the new build is listed.
3. **Invite links** tab → **Create invite link** → choose the group `testers`. Share the link with
   the people who should have the builds. Anyone who has the link can join the group, so revoke
   it there if it spreads. A tester opens it on the phone, signs in with a Google account, and
   installs from the page or the notification each new build sends.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| The job is skipped ("not set up") | The three variables are empty in this GitHub environment |
| The job stops on a variable | The message names it; the value has the wrong shape or extra characters |
| The Google sign-in step is refused | The provider condition does not match the repository or the environment name, or the APIs of section 2 are not on |
| The upload is refused (403) | The role of the service account is missing, or the App Distribution API is not on |
| The upload says the app is not found | `FIREBASE_APP_ID` belongs to another project, or it is not the Android app of this environment |
| Testers get no build | The group alias is not `testers`, or the person has not joined the group yet |

To switch the feature off, empty the three variables: the job is skipped again.
