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
                             # demo settings, time, widgets, the generated API client (api/)
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

## Navigation

`go_router` with a `StatefulShellRoute` around the five top-level screens: a navigation bar below
840 dp and a rail from 840 dp (`app/shell/`). Secondary screens and the whole authentication flow
sit above the shell, so they hide the bar. The exception is a screen that is a segment of a tab, such
as Fixed items in the Salary tab: it is a child route of the tab and keeps the bar. A signed-out person is redirected to the Welcome screen
and a signed-in one leaves the sign-in screens for the Overview (`app/router/`); the route paths
and which of them need a sign-in are in `core/routing/app_routes.dart`.

A screen pushed above the shell is wrapped once, in the router, in `WideFrame` (`core/widgets/`), which
centres the whole screen in a column on a window from 600 dp and changes nothing on a phone; it also gives
its child the width of the column as the window width. A screen therefore never constrains its own width:
widths come from `FrameWidth` (narrow, regular, wide), and a screen that adapts to its room (list and detail,
`TwoColumns`) reads it with `LayoutBuilder`, never with the window size.

The shell keeps every visited tab alive, so each floating button sets `heroTag: null`: two of them
under one route would otherwise share the default hero tag and fail the assertion when a screen is
pushed above the shell. A message at the bottom of a form (a failed save) must not cover its button, so
the pinned button of a form sits in the `Scaffold`'s `bottomNavigationBar`, where a snack bar rises above it.
