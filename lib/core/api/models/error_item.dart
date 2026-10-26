// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

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
    this.remaining,
  });

  factory ErrorItem.fromJson(Map<String, Object?> json) =>
      _$ErrorItemFromJson(json);

  /// A stable, machine-readable code; act on it, not on `detail`. Registered codes: `invalid_credentials`, `email_not_registered`, `wrong_password`, `captcha_required`, `captcha_invalid`, `token_expired`, `token_invalid`, `session_signed_out`, `session_revoked_by_user`, `session_password_changed`, `session_email_changed`, `session_token_reuse`, `session_expired`, `session_limit_reached`, `email_not_verified`, `sign_in_locked`, `throttled`, `device_sign_in_failed`, `challenge_invalid`, `public_key_invalid`, `attestation_invalid`, `platform_not_supported`, `device_key_limit_reached`, `code_invalid`, `code_expired`, `code_attempts_exceeded`, `resend_too_soon`, `resend_limit_reached`, `email_already_registered`, `email_unchanged`, `invalid_password`, `password_too_short`, `password_too_long`, `password_too_similar`, `password_compromised`, `password_too_common`, `password_unchanged`, `password_attempts_exceeded`, `reset_token_invalid`, `name_taken`, `account_limit_reached`, `category_limit_reached`, `does_not_exist`, `category_not_allowed`, `transaction_limit_reached`, `date_out_of_range`, `invalid_date_range`, `too_many_values`, `amount_below_repaid`, `due_before_start`, `repayment_before_start`, `start_after_repayment`, `debt_limit_reached`, `repayment_limit_reached`, `unknown_category`, `unknown_account`, `duplicate`, `idempotency_key_required`, `idempotency_key_invalid`, `idempotency_key_reused`, `idempotency_in_progress`, `precondition_failed`, `fixed_item_limit_reached`, `month_has_fixed_items`, `service_unavailable`, `invalid_characters`, `request_too_large`, `invalid_amount`, `currency_mismatch`, `exceeds_remaining`, `account_has_transactions`, `category_has_transactions`, `category_is_builtin`. Codes raised by the framework for malformed or incomplete input: `required`, `blank`, `null`, `invalid`, `max_length`, `min_length`, `parse_error`, `authentication_failed`, `not_authenticated`, `permission_denied`, `not_found`, `method_not_allowed`, `not_acceptable`, `unsupported_media_type`, `read_only`. A client treats a code it does not know as a generic failure of the status.
  final String code;

  /// Human-readable text; not for display.
  final String detail;

  /// The field the error belongs to, or null for the request as a whole. Sign-in sets it on `email_not_registered` (`email`) and `wrong_password` (`password`); `invalid_password` is on `current_password` (password change) or `password` (account deletion); `reset_token_invalid` is on `reset_token`.
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

  /// Only on `exceeds_remaining`: what the repayment may be at most, an amount in the debt's currency (what the debt still allows, without the repayment that is being changed).
  final Amount? remaining;

  Map<String, Object?> toJson() => _$ErrorItemToJson(this);
}
