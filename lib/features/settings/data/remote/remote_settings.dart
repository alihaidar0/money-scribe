import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/features/settings/domain/account_locale_repository.dart';

/// The settings of the account on the server, one record that three
/// repositories share: the pay schedule, the default currency, and the
/// language and time zone of the account.
///
/// An edit reads the settings first and sends the edit with the `version` it
/// read (`If-Match`), so a change made on another device meanwhile is never
/// overwritten unseen: the edit is read again and sent once more. The server's
/// answer to the edit carries every setting, which [read] callers use.
class RemoteSettings implements AccountLocaleRepository {
  new({
    required this._client,
    required this._timeZone,
    required this._language,
    required this._isSignedIn,
  });

  /// The settings of the account, sent over [dio], which carries the token of
  /// the session and renews it.
  factory create({
    required Dio dio,
    required TimeZoneSource timeZone,
    required String Function() language,
    required bool Function() isSignedIn,
  }) {
    return RemoteSettings(
      client: SettingsClient(dio),
      timeZone: timeZone,
      language: language,
      isSignedIn: isSignedIn,
    );
  }

  final SettingsClient _client;
  final TimeZoneSource _timeZone;

  /// The language of the app now: `en` or `ar`.
  final String Function() _language;

  final bool Function() _isSignedIn;

  /// Every setting, as the server holds it.
  Future<Settings> read() => callApi(_client.settingsRead, _mapFailure);

  /// Changes the settings that are not `null` and returns all of them. The
  /// language and the time zone of the app go with every edit.
  Future<Settings> update({
    CurrencyEnum? defaultCurrency,
    PaymentModeEnum? paymentMode,
    int? firstPayDay,
    int? secondPayDay,
    bool? remindOnPayDays,
  }) async {
    final zone = await _timeZone.read();
    for (var attempt = 0; ; attempt++) {
      final current = await read();
      try {
        return await _send(
          current,
          zone,
          defaultCurrency: defaultCurrency,
          paymentMode: paymentMode,
          firstPayDay: firstPayDay,
          secondPayDay: secondPayDay,
          remindOnPayDays: remindOnPayDays,
        );
      } on StaleRecordException {
        // Changed on another device between the read and the edit: once more
        // from the new version, then give up.
        if (attempt > 0) rethrow;
      }
    }
  }

  @override
  Future<void> sync() async {
    if (!_isSignedIn()) return;
    final zone = await _timeZone.read();
    final current = await read();
    final language = _language();
    if (current.language == language &&
        (zone == null || current.timeZone == zone)) {
      return;
    }
    await _send(current, zone);
  }

  Future<Settings> _send(
    Settings current,
    String? zone, {
    CurrencyEnum? defaultCurrency,
    PaymentModeEnum? paymentMode,
    int? firstPayDay,
    int? secondPayDay,
    bool? remindOnPayDays,
  }) {
    // A field left `null` is left out of the request and stays as it is. The
    // time zone is required: an unreadable one keeps the server's.
    final body = PatchedSettingsUpdateRequest(
      language: _language() == 'ar' ? LanguageEnum.ar : LanguageEnum.en,
      timeZone: zone ?? current.timeZone,
      defaultCurrency: defaultCurrency,
      paymentMode: paymentMode,
      firstPayDay: firstPayDay,
      secondPayDay: secondPayDay,
      remindOnPayDays: remindOnPayDays ?? current.remindOnPayDays,
    );
    return callApi(
      () => _client.settingsUpdate(
        ifMatch: WriteSafetyHeaders.ifMatch(current.version),
        body: body,
      ),
      _mapFailure,
    );
  }

  Exception _mapFailure(ApiFailure failure) => failure.toDataException();
}
