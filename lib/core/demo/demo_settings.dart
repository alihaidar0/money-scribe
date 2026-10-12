import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// What the fake data sources pretend the server is doing. It lets every
/// loading, empty, error and "no connection" screen be tried without a server.
enum DemoScenario { normal, loading, empty, error, noConnection }

/// What the next sign-in attempt does.
enum DemoSignIn { accepted, wrongPassword, locked }

/// What the next attempt to create an account does.
enum DemoRegistration { accepted, rejected }

/// What a code typed on the verification screens does.
enum DemoCode { accepted, wrong, expired }

/// What the next attempt to save something does.
enum DemoSave { accepted, fails }

/// Which colours the app is shown in: the device's choice, or one of the two.
enum DemoTheme { system, light, dark }

/// The state of the demo panel. Fake data sources read it on every call, so a
/// change applies to the next thing the person does.
final class DemoSettings extends Equatable {
  const new({
    this.scenario = DemoScenario.normal,
    this.signIn = DemoSignIn.accepted,
    this.registration = DemoRegistration.accepted,
    this.code = DemoCode.accepted,
    this.save = DemoSave.accepted,
    this.paymentMode = PaymentMode.onePayment,
    this.theme = DemoTheme.system,
  });

  final DemoScenario scenario;
  final DemoSignIn signIn;
  final DemoRegistration registration;
  final DemoCode code;
  final DemoSave save;

  /// The theme of the app, for trying the screens in light and dark.
  final DemoTheme theme;

  /// How the fake account is paid: one payment or two a month.
  final PaymentMode paymentMode;

  DemoSettings copyWith({
    DemoScenario? scenario,
    DemoSignIn? signIn,
    DemoRegistration? registration,
    DemoCode? code,
    DemoSave? save,
    PaymentMode? paymentMode,
    DemoTheme? theme,
  }) {
    return DemoSettings(
      scenario: scenario ?? this.scenario,
      signIn: signIn ?? this.signIn,
      registration: registration ?? this.registration,
      code: code ?? this.code,
      save: save ?? this.save,
      paymentMode: paymentMode ?? this.paymentMode,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object> get props => [
    scenario,
    signIn,
    registration,
    code,
    save,
    paymentMode,
    theme,
  ];
}

/// Holds the [DemoSettings] and tells whoever is listening when they change.
/// Plain Dart, so the fake data sources of any feature can use it.
class DemoController {
  new({
    DemoSettings initial = const DemoSettings(),
    this.latency = const Duration(milliseconds: 500),
  }) : _settings = initial;

  /// How long a fake request takes, so loading states can be seen.
  final Duration latency;

  final _changes = StreamController<DemoSettings>.broadcast();
  DemoSettings _settings;

  DemoSettings get settings => _settings;

  Stream<DemoSettings> get changes => _changes.stream;

  /// Emits when what the fake data answers with changed: the scenario or the
  /// payment mode. Screens that show data load it again then; the other
  /// switches only apply to the next thing the person does. Every call returns
  /// a stream of its own, to be listened to once.
  Stream<void> get dataChanges {
    var previous = (_settings.scenario, _settings.paymentMode);
    return _changes.stream
        .where((settings) {
          final current = (settings.scenario, settings.paymentMode);
          if (current == previous) return false;
          previous = current;
          return true;
        })
        .map((_) {});
  }

  void update(DemoSettings settings) {
    if (settings == _settings) return;
    _settings = settings;
    _changes.add(settings);
  }

  /// Waits [latency] like a real request would, then fails the way the
  /// scenario says. Fake data sources call it at the start of every request.
  Future<void> simulateRequest() async {
    // "Loading" is a request that takes long enough to look at.
    final delay = _settings.scenario == DemoScenario.loading
        ? const Duration(seconds: 8)
        : latency;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    switch (_settings.scenario) {
      case DemoScenario.noConnection:
        throw const NoConnectionException();
      case DemoScenario.error:
        throw const ServerException();
      case DemoScenario.normal || DemoScenario.loading || DemoScenario.empty:
        break;
    }
  }

  /// Like [simulateRequest], for a request that saves something: it also
  /// fails when the panel says the next save does.
  Future<void> simulateSave() async {
    await simulateRequest();
    if (_settings.save == DemoSave.fails) throw const NoConnectionException();
  }

  Future<void> dispose() => _changes.close();
}
