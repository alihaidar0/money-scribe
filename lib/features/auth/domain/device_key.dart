import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/device/device_info.dart';

/// Whether this phone can hold a fingerprint sign-in key.
enum DeviceKeySupport {
  /// It has secure hardware and an enrolled fingerprint.
  available,

  /// It can, but no fingerprint is enrolled yet.
  notEnrolled,

  /// It cannot: no sensor, no secure hardware, or the system is too old.
  unsupported,
}

/// The account the fingerprint of this phone signs in, as the sign-in screen
/// shows it. Only a name and a masked address: the phone keeps nothing else
/// about the account next to the key.
final class FingerprintAccount extends Equatable {
  const new({
    required this.accountId,
    required this.name,
    required this.maskedEmail,
  });

  final String accountId;
  final String name;

  /// The email with most of the name hidden, such as `a***@gmail.com`.
  final String maskedEmail;

  @override
  List<Object> get props => [accountId, name, maskedEmail];
}

/// A phone that can sign the account in with its fingerprint, as the server
/// lists it.
final class DeviceKeyEntry extends Equatable {
  const new({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.attested,
    required this.isCurrent,
    required this.createdAt,
    required this.expiresAt,
    this.lastUsedAt,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final DevicePlatform platform;

  /// Whether the server could check that the key lives in secure hardware.
  final bool attested;

  /// Whether this entry is the phone the app runs on.
  final bool isCurrent;

  final DateTime createdAt;

  /// `null` until the key signed anybody in.
  final DateTime? lastUsedAt;

  /// When the key stops working: 30 days after it was last used.
  final DateTime expiresAt;

  @override
  List<Object?> get props => [
    id,
    deviceId,
    deviceName,
    platform,
    attested,
    isCurrent,
    createdAt,
    lastUsedAt,
    expiresAt,
  ];
}

/// Hides most of an email address: `alex@gmail.com` is `a***@gmail.com`.
String maskEmail(String email) {
  final at = email.lastIndexOf('@');
  if (at < 1) return '***';
  return '${email.substring(0, 1)}***${email.substring(at)}';
}
