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

/// The state of the demo panel. Fake data sources read it on every call, so a
/// change applies to the next thing the person does.
final class DemoSettings extends Equatable {
  const new({
    this.scenario = DemoScenario.normal,
    this.signIn = DemoSignIn.accepted,
    this.registration = DemoRegistration.accepted,
    this.code = DemoCode.accepted,
    this.paymentMode = PaymentMode.onePayment,
  });

  final DemoScenario scenario;
  final DemoSignIn signIn;
  final DemoRegistration registration;
  final DemoCode code;

  /// How the fake account is paid: one payment or two a month.
  final PaymentMode paymentMode;

  DemoSettings copyWith({
    DemoScenario? scenario,
    DemoSignIn? signIn,
    DemoRegistration? registration,
    DemoCode? code,
    PaymentMode? paymentMode,
  }) {
    return DemoSettings(
      scenario: scenario ?? this.scenario,
      signIn: signIn ?? this.signIn,
      registration: registration ?? this.registration,
      code: code ?? this.code,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  @override
  List<Object> get props => [scenario, signIn, registration, code, paymentMode];
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

  Future<void> dispose() => _changes.close();
}
