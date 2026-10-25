import 'package:flutter_timezone/flutter_timezone.dart';

/// The time zone of the device as an IANA name such as `Europe/Berlin`, or
/// `null` when it cannot be read. The server takes it at sign-in; an unreadable
/// one is left out of the request.
abstract interface class TimeZoneSource {
  Future<String?> read();
}

/// Reads the time zone from the platform.
class PlatformTimeZoneSource implements TimeZoneSource {
  const new();

  /// The server accepts at most 64 characters.
  static const maxLength = 64;

  static final _ianaName = RegExp(r'^[A-Za-z0-9_+\-/]+$');

  @override
  Future<String?> read() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      return validName(zone.identifier);
    } on Exception {
      return null;
    }
  }

  /// [name] if it looks like an IANA name the server can take, else `null`.
  static String? validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) return null;
    return _ianaName.hasMatch(trimmed) ? trimmed : null;
  }
}
