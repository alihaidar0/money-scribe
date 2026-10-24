part of 'device_key_setting_bloc.dart';

/// What a turn on or turn off came to. Only the action that has just ended
/// sees it: the next action starts with none.
enum DeviceKeyOutcome {
  turnedOn,
  turnedOff,

  /// The password was wrong.
  wrongPassword,

  /// The fingerprint did not match, or the check was cancelled: nothing is
  /// said beyond "it was not turned on".
  notMatched,

  /// The server refused the key of this phone, giving no reason.
  refused,

  /// The account has the most phones it can have.
  limitReached,

  /// The challenge ran out, or the proof was wrong: trying again is enough.
  expired,

  /// The phone cannot check a fingerprint now.
  cannotCheck,

  /// Too many wrong passwords: see [DeviceKeySettingState.waitSeconds].
  waitForPassword,

  /// The server is busy.
  busy,

  /// The server could not be reached.
  offline,

  /// Anything else.
  failed,
}

final class DeviceKeySettingState extends Equatable {
  const new({
    this.isLoaded = false,
    this.support = DeviceKeySupport.unsupported,
    this.isEnabled = false,
    this.isBusy = false,
    this.outcome,
    this.waitSeconds = 0,
  });

  /// Whether the first answer arrived. Until then the switch is off and cannot
  /// be pressed.
  final bool isLoaded;

  /// What the phone can do.
  final DeviceKeySupport support;

  /// Whether the sign-in is on for the signed-in account on this phone.
  final bool isEnabled;

  /// Whether the server or the fingerprint is being waited for.
  final bool isBusy;

  /// How the last action ended, or `null` before one did.
  final DeviceKeyOutcome? outcome;

  /// The wait the server asked for, in seconds, with
  /// [DeviceKeyOutcome.waitForPassword].
  final int waitSeconds;

  bool get canTurnOn => isLoaded && support == DeviceKeySupport.available;

  DeviceKeySettingState copyWith({
    bool? isLoaded,
    DeviceKeySupport? support,
    bool? isEnabled,
    bool? isBusy,
    DeviceKeyOutcome? outcome,
    bool clearOutcome = false,
    int? waitSeconds,
  }) {
    return DeviceKeySettingState(
      isLoaded: isLoaded ?? this.isLoaded,
      support: support ?? this.support,
      isEnabled: isEnabled ?? this.isEnabled,
      isBusy: isBusy ?? this.isBusy,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      waitSeconds: waitSeconds ?? this.waitSeconds,
    );
  }

  @override
  List<Object?> get props => [
    isLoaded,
    support,
    isEnabled,
    isBusy,
    outcome,
    waitSeconds,
  ];
}
