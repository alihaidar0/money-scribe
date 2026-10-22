// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error_item.g.dart';

@JsonSerializable()
class ErrorItem {
  const ErrorItem({
    required this.code,
    required this.detail,
    required this.attr,
    this.attemptsLeft,
    this.minLength,
    this.maxLength,
  });

  factory ErrorItem.fromJson(Map<String, Object?> json) =>
      _$ErrorItemFromJson(json);

  /// A stable, machine-readable code; act on it, not on `detail`. Registered codes: `invalid_credentials`, `email_not_registered`, `wrong_password`, `captcha_required`, `captcha_invalid`, `token_expired`, `token_invalid`, `session_signed_out`, `session_revoked_by_user`, `session_password_changed`, `session_email_changed`, `session_token_reuse`, `session_expired`, `email_not_verified`, `sign_in_locked`, `throttled`, `code_invalid`, `code_expired`, `code_attempts_exceeded`, `resend_too_soon`, `resend_limit_reached`, `email_already_registered`, `invalid_password`, `password_too_short`, `password_too_long`, `password_too_similar`, `password_compromised`, `password_too_common`, `service_unavailable`, `invalid_amount`, `currency_mismatch`, `exceeds_remaining`, `account_has_transactions`, `category_has_transactions`, `category_is_builtin`. Codes raised by the framework for malformed or incomplete input: `required`, `blank`, `null`, `invalid`, `max_length`, `min_length`, `parse_error`, `authentication_failed`, `not_authenticated`, `permission_denied`, `not_found`, `method_not_allowed`, `not_acceptable`, `unsupported_media_type`. A client treats a code it does not know as a generic failure of the status.
  final String code;

  /// Human-readable text; not for display.
  final String detail;

  /// The field the error belongs to, or null for the request as a whole. Sign-in sets it on `email_not_registered` (`email`) and `wrong_password` (`password`).
  final String? attr;

  /// Only on `code_invalid`: how many wrong tries the email code still allows.
  @JsonKey(name: 'attempts_left')
  final int? attemptsLeft;

  /// Only on `password_too_short`: the shortest password the server accepts.
  @JsonKey(name: 'min_length')
  final int? minLength;

  /// Only on `password_too_long`: the longest password the server accepts.
  @JsonKey(name: 'max_length')
  final int? maxLength;

  Map<String, Object?> toJson() => _$ErrorItemToJson(this);
}
