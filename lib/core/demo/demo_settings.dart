import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// What the fake data sources pretend the server is doing. It lets every
/// loading, empty, error and "no connection" screen be tried without a server.
enum DemoScenario { normal, loading, empty, error, noConnection }

/// What the next sign-in attempt does.
enum DemoSignIn {
  accepted,

  /// No account has the email address.
  emailNotRegistered,

  /// The account exists but the password is wrong (locks after 5).
  wrongPassword,

  /// The server asks for a bot challenge; any solved challenge signs in.
  challengeRequired,

  /// The server asks for a bot challenge and refuses every token.
  challengeRejected,
  locked,

  /// The password is right but the email address is not verified yet.
  emailNotVerified,

  /// The server is busy (`503`).
  unavailable,
}

/// What the next attempt to create an account does.
enum DemoRegistration {
  accepted,

  /// The server refuses the email address and the password.
  rejected,

  /// The same address was registered a moment ago: wait before sending again.
  tooSoon,

  /// The server is busy (`503`).
  unavailable,
}

/// What a code typed on the verification screens, or a new code asked for,
/// does.
enum DemoCode {
  accepted,
  wrong,
  expired,

  /// Too many wrong codes: the code is dead and a new one can be asked for
  /// after a wait.
  attemptsExceeded,

  /// The server is busy (`503`).
  unavailable,
}

/// What the next attempt to set a new password after a reset does.
enum DemoPasswordReset {
  accepted,

  /// The server refuses the password (the token stays valid).
  passwordRefused,

  /// The reset ran out: a new code has to be asked for.
  tokenInvalid,

  /// Too many requests: wait before the password is sent again.
  tooSoon,

  /// The server is busy (`503`).
  unavailable,
}

/// What the next attempt to save something does.
enum DemoSave { accepted, fails }

/// The state of the demo panel. Fake data sources read it on every call, so a
/// change applies to the next thing the person does.
final class DemoSettings extends Equatable {
  const new({
    this.scenario = DemoScenario.normal,
    this.signIn = DemoSignIn.accepted,
    this.registration = DemoRegistration.accepted,
    this.code = DemoCode.accepted,
    this.passwordReset = DemoPasswordReset.accepted,
    this.save = DemoSave.accepted,
    this.paymentMode = PaymentMode.onePayment,
  });

  final DemoScenario scenario;
  final DemoSignIn signIn;
  final DemoRegistration registration;
  final DemoCode code;
  final DemoPasswordReset passwordReset;
  final DemoSave save;

  /// How the fake account is paid: one payment or two a month.
  final PaymentMode paymentMode;

  DemoSettings copyWith({
    DemoScenario? scenario,
    DemoSignIn? signIn,
    DemoRegistration? registration,
    DemoCode? code,
    DemoPasswordReset? passwordReset,
    DemoSave? save,
    PaymentMode? paymentMode,
  }) {
    return DemoSettings(
      scenario: scenario ?? this.scenario,
      signIn: signIn ?? this.signIn,
      registration: registration ?? this.registration,
      code: code ?? this.code,
      passwordReset: passwordReset ?? this.passwordReset,
      save: save ?? this.save,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  @override
  List<Object> get props => [
    scenario,
    signIn,
    registration,
    code,
    passwordReset,
    save,
    paymentMode,
  ];
}

/// Holds the [DemoSettings] and tells whoever is listening when they change.
/// Plain Dart, so the fake data sources of any feature can use it.
class DemoController {
  new({
    DemoSettings initial = const DemoSettings(),
    this.latency = const Duration(milliseconds: 500),
    this.fakeAccount = true,
  }) : _settings = initial;

  /// How long a fake request takes, so loading states can be seen.
  final Duration latency;

  /// Whether the account (sign in, register, the codes) is fake. A build with
  /// a server address has the real account, so the switches that force its
  /// answers do nothing and the demo panel leaves them out.
  final bool fakeAccount;

  final _changes = StreamController<DemoSettings>.broadcast();
  final _scheduleChanges = StreamController<void>.broadcast();
  DemoSettings _settings;

  /// How each month that was saved with its own schedule is paid. A saved
  /// month keeps its schedule whatever the account's current one is.
  final _monthModes = <YearMonth, PaymentMode>{};

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

  /// How [month] is paid: the schedule it was saved with, or else the
  /// account's current one.
  PaymentMode paymentModeOf(YearMonth month) {
    return _monthModes[month] ?? _settings.paymentMode;
  }

  /// Remembers that [month] was saved with the schedule [mode], so every screen
  /// that shows the month agrees on whether it has two parts.
  void setMonthPaymentMode(YearMonth month, PaymentMode mode) {
    if (_monthModes[month] == mode) return;
    _monthModes[month] = mode;
    _scheduleChanges.add(null);
  }

  /// Forgets the schedule of [month], for example when its salary is deleted.
  void clearMonthPaymentMode(YearMonth month) {
    if (_monthModes.remove(month) != null) _scheduleChanges.add(null);
  }

  /// [dataChanges], and also emits when a month was saved with another
  /// schedule. For the screens that show the parts of a month, which have to
  /// follow the salary of each month. Every call returns a stream of its own,
  /// to be listened to once.
  Stream<void> get dataChangesWithSchedules {
    late StreamController<void> controller;
    StreamSubscription<void>? data;
    StreamSubscription<void>? schedules;
    controller = StreamController<void>(
      onListen: () {
        data = dataChanges.listen(controller.add);
        schedules = _scheduleChanges.stream.listen(controller.add);
      },
      onCancel: () async {
        await data?.cancel();
        await schedules?.cancel();
      },
    );
    return controller.stream;
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

  Future<void> dispose() async {
    await _changes.close();
    await _scheduleChanges.close();
  }
}
