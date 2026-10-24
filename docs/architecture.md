# Architecture

How the app is organised and how state is managed. The rules here are checked in review;
the lints in `analysis_options.yaml` and the tests in `test/` enforce what they can.

## Layers

The code is split by feature, and each feature by layer:

```text
lib/
  main.dart                  # start-up only: observer, preferences, Firebase, runApp
  app/                       # MoneyScribeApp, theme, router, navigation shell, demo panel,
                             # BlocObserver (wires everything)
  core/                      # shared and feature-independent: money, environment, routing
                             # paths, l10n, clipboard, formatting, theme extensions, errors,
                             # demo settings, time, widgets, the generated API client (api/),
                             # network (Dio, session), device, secure storage
  features/<feature>/
    domain/                  # entities, value objects, repository interfaces (plain Dart)
    data/                    # repository implementations, data sources
    bloc/                    # <name>_bloc.dart, <name>_event.dart, <name>_state.dart
    presentation/            # screens and widgets
```

Dependencies point inward:

- `app/` may import anything; it is the only place that knows every feature.
- `core/` imports neither `app/` nor a feature.
- A feature imports `core/` and itself, never `app/`. Inside a feature, `domain/` imports
  nothing else (and no Flutter), `data/` implements `domain/`, a Bloc depends on `domain/`
  only (no Flutter, no `data/`, no `presentation/`), and `presentation/` uses the Bloc.
- Only a feature's `data/` uses the generated API client in `core/api/`; `domain/`, a Bloc and
  `presentation/` never import it ([`backend-api.md`](backend-api.md)).
- A feature reaches another one only through its screens (for example Settings shows the
  Notifications section); never through its Bloc, data or domain.

`test/architecture_test.dart` checks these rules on every import, so a violation fails CI.
Route paths live in `core/routing/` and the build environment in `core/environment/`, which
is how a screen can link to another and read the environment without importing `app/`.

## State management: Bloc

State is managed with [`flutter_bloc`](https://bloclibrary.dev), one `Bloc` per feature,
with **events everywhere**: even a simple feature has event and state classes (no `Cubit`).

- **Events** are a `sealed` class with `final` subclasses, named in the past tense for what
  happened (`LanguageSelected`, `NotificationPermissionRequested`).
- **States** are immutable and extend `Equatable`, so a Bloc only emits real changes. A state
  with several phases uses a status enum and `copyWith`.
- **Parts.** A Bloc, its events and its states live in three files linked with `part` and
  `part of`, so they stay together in the feature's `bloc/` folder.
- **Handlers** are registered with `on<Event>`. Each one picks a transformer from
  `bloc_concurrency`: `droppable()` for actions that must not run twice at once (asking for a
  permission), `sequential()` where order matters (saving a setting), `restartable()` for
  searches. A failure is caught in the handler, reported with `addError` and turned into a
  failure state; the app never relies on an uncaught exception.
- **Dependencies** come in through the constructor, as interfaces. A Bloc has no static
  access and no service locator.
- **Providing.** `main` creates the repositories and passes them to `MoneyScribeApp`, which
  provides them with `RepositoryProvider.value`. A Bloc is created with `BlocProvider` where
  its screen lives (the language Bloc, which the whole app needs, at the root). The build
  environment is read with `AppEnvironmentScope.of(context)`; a Bloc never reads it, it is
  given the plain values it needs (for example `canCopyPushToken`).
- **Reading.** Widgets rebuild on the smallest slice they need (`BlocSelector`,
  `context.select`, `buildWhen`) and send events with `context.read<Bloc>().add(...)`.
  One-time effects, such as a snackbar or navigation, belong in a `BlocListener`, not in
  `build`.
- **Observing.** `AppBlocObserver` logs the type of each event and error in debug builds,
  never their contents, because they can hold personal or financial data.

## Testing

- Every Bloc has a `bloc_test` file that asserts the exact sequence of states for each event,
  including failures and ignored events.
- Repositories are faked with small in-memory classes in `test/support/`, not mocked.
- Screens have widget tests; `test/app/layout_test.dart` opens every route in English and
  Arabic at 200% text size.
- `test/app/navigation_test.dart` (sign-in flow) and `test/app/navigation_screens_test.dart` (the main
  screens and the Settings) are the link tests: every button leads where the design says.
- `test/render/screens_render_test.dart` draws every screen and state to `build/screens/` in English and
  Arabic, light and dark, at phone and 1280 x 800 sizes, to be looked at. A floating button shows a hard
  black outline there: the test renderer draws elevation shadows that way, the app does not. It takes
  about three minutes, so `flutter test`, the commit hook and CI skip it (`dart_test.yaml`); run it when a
  screen changes: `flutter test --run-skipped --tags render test/render`.
- `test/architecture_test.dart` enforces the dependency rules above.

### Which tests run when

- **Commit hook.** `scripts/dart-affecting.sh` says whether a change can affect the Dart checks at all; if not,
  format, analyze and the tests are skipped. Otherwise `tool/changed_scope.dart` reads the import graph of
  `lib/`, `test/` and `tool/` (`part` files count as one unit with their library) and selects the tests that
  import a changed file, directly or through a chain of imports. A change to a file of `lib/` always adds
  `test/architecture_test.dart`, which reads every source file, and `docs/DESIGN.md` counts as a change to the
  parser the theme tests read it with. The whole suite runs whenever the graph cannot say: a change to the
  dependencies, the analyzer settings, the strings or the assets, a deleted Dart file, a changed file that
  cannot be found, or an error. `FULL_CHECKS=1` forces everything.
- **CI.** A pull request into `develop` that changes nothing the Dart checks read skips the Flutter jobs
  (`CI passed` counts a skipped job as passed). Otherwise the whole suite runs, split over three runners
  (`--total-shards`), at the same time as format and analyze, so the required check never depends on the
  selection and the run lasts as long as the slowest check. A pull request into `main`, a
  manual run and a change CI cannot read run everything, and only then is coverage collected.

## Data

The data lives only on the server. Until the backend exists, repository interfaces have fake
implementations with invented data; the device keeps only simple settings in
`shared_preferences`. See [`environments.md`](environments.md) for the build environments.

### Fake data now, the server later

- A feature's `domain/` holds the repository **interface**; Blocs and screens know nothing else.
- `data/fake/` holds the in-memory implementation and its seed (invented figures only). It
  simulates a short delay and can be told to be empty, slow, failing or offline, so every
  loading, empty, error and no-connection state can be tried without a server.
- `main` chooses the implementations. The remote implementations use the client generated from the
  backend's contract ([`backend-api.md`](backend-api.md)). To connect the server, add `data/remote/` next to
  `data/fake/`, switch the feature in `main`, and delete its `data/fake/` folder. Nothing in
  `bloc/` or `presentation/` changes.
- `core/demo/` holds `DemoController`, the plain-Dart switchboard the fake data sources read on every
  request: the scenario (normal, loading, empty, error, no connection), what the next sign-in,
  registration, code check and save answer, and how the account is paid; it also remembers the schedule
  each month was saved with (`paymentModeOf`), so a month saved with two payments has its parts on every
  screen, whatever the account's current schedule is. Builds that are not production show a small handle on the
  end edge of the screen that opens the demo panel (`app/demo/`), where these are changed, the
  language and the theme (light or dark, the same saved settings as in Settings) are switched and the screens no button leads to can be opened. The panel and the
  controller go away with the fake data.
- A repository can tell its screens that its data may have changed without the app saving it
  (`Stream<void> changes`, for example `OverviewRepository` and `SalaryRepository`), and the Bloc
  loads again. The fake ones follow `DemoController.dataChanges`, so switching the scenario or the
  payment mode refreshes the visible screen while the other switches wait for the next request; a
  real one can emit when the server pushes a change. A screen that saves updates its own state
  with what it sent, so it never needs to load again after saving.
- The fake account has one payment mode (one or two payments a month) and one scenario. A new
  account starts as "empty" (so the Overview shows its first-launch screen) and signing in to an
  existing one brings the data; the first-start pay question sets the mode.
- A repository throws a `DataException` (`core/errors/`) when the server cannot be reached or fails;
  a Bloc turns it into a state, and the screen shows the full-screen "No connection" or
  "Something went wrong" view (`FlowPage` keeps the form underneath, so nothing typed is lost).
  The other kinds are "The service is busy" (`ServiceUnavailableException`, a `503`) and "Not available
  yet" (`FeatureNotAvailableException`: the screen exists and the server side is still to come; the
  only way out is Go back).

### The network layer

`core/network/` is what every remote repository shares; `core/api/` is the client generated from the
contract, which only a feature's `data/` imports.

- **`createPlainDio` / `createAuthenticatedDio`** build the Dio of the server from `ApiConfig`
  (`core/environment/`): JSON only, long timeouts (the free staging server wakes slowly), and no
  logging interceptor, ever, because requests hold personal and financial data.
- **`AuthInterceptor`** puts the access token on the requests a feature says need it and keeps the
  session alive. Only `401 token_expired` refreshes, and the request is sent again once. One refresh
  runs at a time, and requests that expire together wait for it. The new pair is stored before it is
  used. A refresh whose answer is lost is sent again with the same token inside the server's 30
  seconds. Only a `401` from the refresh clears the tokens: a bad connection never signs anyone out.
  Any other `401` on a signed-in request is final. The refresh call is injected, so `core/` never
  imports `core/api/`: the feature that owns the paths builds it with its generated client.
- **`SlowRequestMonitor`** notices a request that has waited more than 5 seconds, and `MonitoredHttpAdapter`
  tells it about every real request (below the interceptors, so a request sent again after a refresh counts
  once). The `connection` feature turns this into a note above the screen, in staging builds only: the free
  staging server sleeps after 15 minutes and its first request takes about a minute, while a production
  server does not sleep. `warmUpServer` sends one `GET /healthz` at start in staging, to wake it early.
- **`OmitNullsInterceptor`** drops every `null` from a request body: the generated models write a missing
  optional field as `null`, and the server wants it left out.
- **`ApiFailure`** reads a failed call once: the status, the error items (`code`, `detail`, `attr`,
  `attempts_left`, `min_length`, `max_length`), `Retry-After`, and whether the server answered at all.
  A repository maps it to its own exceptions; the generic ones are `NoConnectionException`,
  `ServiceUnavailableException` (a `503`) and `ServerException`.
- **Write safety** (`IdempotencyKeys`, `WriteSafetyHeaders`, `readAllPages`) is what the backend agreed
  for every write after the account. A create that is repeated (a lost answer, a retry) must not make a
  second record, so each action of the person (one press of Save, Add or Import) gets one random UUID
  `Idempotency-Key`, kept in memory while the action has no answer and dropped once it has one: a
  success or a refusal no retry changes. Two presses that each got an answer have two keys, so a second
  purchase with the same amount is never taken for a repeat of the first. A key is also dropped after 20
  hours, because the server forgets it after 24. Edits and deletes send `If-Match` with the `version` of
  the record they read; a month created with `PUT` sends `If-None-Match: *` when the app did not find it.
  `412` becomes `StaleRecordException` (the record changed on another device: read it again and let the
  person decide) and `409 idempotency_in_progress` becomes `RequestInProgressException` (try again a
  moment later). A list the server cuts into pages is read to the end with `readAllPages`, which stops a
  server that loops. The generated client takes the three headers as plain string parameters, written by
  `WriteSafetyHeaders`. The salary repositories already follow this: a `SalaryMonth` and a `FixedItem`
  carry their `version`, saving a month without a version means "create it" and fails if it exists, an
  edit or delete passes the version it read, and the Blocs answer a `StaleRecordException` by keeping
  what was typed (the month) or loading the list again (the items) and offering to apply the change
  once more.
- **Fingerprint sign-in** (`features/auth`) keeps the private key in the phone's secure hardware, behind
  `DeviceKeyStore` (the only place the `biometric_signature` plugin is used), and the public half on the
  server. `RemoteDeviceKeyRepository` asks for a challenge, has the key sign it after a fingerprint, and
  registers or uses the result; next to the key the phone keeps only the name and a masked email of the
  account, in the secure storage, so the sign-in screen can say whom the fingerprint signs in. The calls
  that need no session (challenge, sign-in) are in `authPublicPaths`. `DeviceKeySync` compares the key with
  the server's list after every sign-in and lets go of one the server removed (a changed password, a
  deleted account, a key that expired) or one that belongs to another account. The emulator has no secure
  hardware, so a build without a server address uses `FakeDeviceKeyRepository`, driven by the demo panel.
- **`TokenStore`** keeps the session tokens in the platform's secure storage (`core/storage/`), as
  one value. A value that cannot be read is no session. The Android manifest turns automatic backup
  off, so a restored copy of the tokens never meets a Keystore that cannot decrypt it.
- **`core/device/`** describes the device for the server (a random UUID kept in the secure storage,
  the model name, the system and app versions) and reads the time zone as an IANA name. The plugins
  are used in one place each, behind small interfaces.

## Navigation

`go_router` with a `StatefulShellRoute` around the five top-level screens: a navigation bar below
840 dp and a rail from 840 dp (`app/shell/`). Secondary screens and the whole authentication flow
sit above the shell, so they hide the bar. The exception is a screen that is a segment of a tab, such
as Fixed items in the Salary tab: it is a child route of the tab and keeps the bar. A signed-out person is redirected to the Welcome screen
and a signed-in one leaves the sign-in screens for the Overview (`app/router/`); the route paths
and which of them need a sign-in are in `core/routing/app_routes.dart`.

The email change is two screens that hand their result back (`EmailChangeOutcome`): the form
(`ChangeEmailBloc`) and the code screen, which reuses `CodeEntryPage` and `CodeVerificationBloc` with the
purpose `CodePurpose.changeEmail`. A new code for it needs the password again, which the page asks for
with a dialog and passes with the resend event; the password is never kept.

The app lock (`features/auth/`) has three parts. `AppLockRepository` is the device side: the PIN as a
salted PBKDF2 hash in the secure storage (`SecureAppLockRepository`, `PinHasher`), the count of wrong PINs,
the pause they started (`PinLockoutPolicy`: none for four, then 30 s, 1 min, 5 min, 15 min, 15 min, and the
tenth wrong PIN in a row signs the person out) and the timeout; `BiometricAuthenticator` is the fingerprint
through the system (`local_auth`). `AppLockGate` (`app/app_lock_gate.dart`) watches the app move to the
background (`hidden` and `paused`, never `inactive`) and locks it after the timeout; it implements the
domain interface `AppLockSession`, so the screens only report "unlocked". The router sends every screen of a
locked app to the lock screen with a `from` address and goes back to it (`AppRoutes.returnTo` accepts only
a screen of the app). The lock belongs to the account that made it (`AppLockRepository.boundAccount`,
`AuthRepository.accountId`) and stays when the person signs out. `AppLockGate` forgets it when another
account signs in; "Forgot PIN?", ten wrong PINs and deleting the account forget it on their own. The
fingerprint is a separate switch (`biometricsEnabled`) that turns on only after a fingerprint matched and
needs the PIN: with no PIN it is confirmed first (`confirmBiometrics`), then the Create a PIN screen opens
and the fingerprint turns on when the PIN is saved (`enableConfirmedBiometrics`). The lock screen asks for
it only while it is on and the device still has one. A new lock asks every time the app comes back
(`LockTimeout.standard` is `immediately`).

Whenever the person is signed out (signing out, deleting the account, or a session the server ended),
`PushTokenCleanup` (`app/push_token_cleanup.dart`) deletes the push token of the device through
`PushMessagingRepository.forgetToken()`, so a signed-out device keeps no token that an earlier sign-in
registered. A failure to delete it is logged by type only and never blocks the sign-out.

A screen pushed above the shell is wrapped once, in the router, in `WideFrame` (`core/widgets/`), which
centres the whole screen in a column on a window from 600 dp and changes nothing on a phone; it also gives
its child the width of the column as the window width. A screen therefore never constrains its own width:
widths come from `FrameWidth` (narrow, regular, wide), and a screen that adapts to its room (list and detail,
`TwoColumns`) reads it with `LayoutBuilder`, never with the window size.

The shell keeps every visited tab alive, so each floating button sets `heroTag: null`: two of them
under one route would otherwise share the default hero tag and fail the assertion when a screen is
pushed above the shell. A message at the bottom of a form (a failed save) must not cover its button, so
the pinned button of a form sits in the `Scaffold`'s `bottomNavigationBar`, where a snack bar rises above it.
