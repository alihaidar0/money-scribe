// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/patched_settings_update_request.dart';
import '../models/settings.dart';

part 'settings_client.g.dart';

@RestApi()
abstract class SettingsClient {
  factory SettingsClient(Dio dio, {String? baseUrl}) = _SettingsClient;

  /// Read the settings.
  ///
  /// Every setting, with the app's own default for one that was never set (language `en`, time zone `UTC`, currency `RUB`, one payment, pay days 20 and 5, reminders off). The first read makes the row, so there is always a `version` and an `ETag`.
  @GET('/api/v1/settings/')
  Future<Settings> settingsRead();

  /// Change the settings.
  ///
  /// Changes the fields sent and answers all the settings. The language and the time zone are the ones the emails, the reminders and "today" use (sign-in still sets them from the device it happens on). `default_currency`, `payment_mode`, `first_pay_day` and `second_pay_day` can be sent as `null` to go back to "not set". Send `If-Match` with the `version` read: a stale one is `412` and changes nothing. Errors: `400` on the field that is wrong (`invalid_choice`, `invalid`, `min_value`, `max_value`, `null` for a field that cannot be cleared), `400` `invalid_pay_days` on `second_pay_day` when the pay days that would result leave the second on or after the first, `400` `read_only` for a field that is not a setting.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @PATCH('/api/v1/settings/')
  Future<Settings> settingsUpdate({
    @Header('If-Match') String? ifMatch,
    @Body() PatchedSettingsUpdateRequest? body,
  });
}
