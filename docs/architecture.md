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
                             # demo settings, time, widgets
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
- `main` chooses the implementations. To connect the server, add `data/remote/` next to
  `data/fake/`, switch the feature in `main`, and delete its `data/fake/` folder. Nothing in
  `bloc/` or `presentation/` changes.
- `core/demo/` holds `DemoController`, the plain-Dart switchboard the fake data sources read on every
  request: the scenario (normal, loading, empty, error, no connection) and what the next sign-in,
  registration and code check answer. Builds that are not production show a small handle on the
  end edge of the screen that opens the demo panel (`app/demo/`), where these are changed, the
  language is switched and the screens no button leads to can be opened. The panel and the
  controller go away with the fake data.
- A repository throws a `DataException` (`core/errors/`) when the server cannot be reached or fails;
  a Bloc turns it into a state, and the screen shows the full-screen "No connection" or
  "Something went wrong" view (`FlowPage` keeps the form underneath, so nothing typed is lost).

## Navigation

`go_router` with a `StatefulShellRoute` around the five top-level screens: a navigation bar below
840 dp and a rail from 840 dp (`app/shell/`). Secondary screens and the whole authentication flow
sit above the shell, so they hide the bar. A signed-out person is redirected to the Welcome screen
and a signed-in one leaves the sign-in screens for the Overview (`app/router/`); the route paths
and which of them need a sign-in are in `core/routing/app_routes.dart`.
