// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `one_payment` - One payment.
/// * `two_payments` - Two payments.
@JsonEnum()
enum PaymentModeEnum {
  @JsonValue('one_payment')
  onePayment('one_payment'),
  @JsonValue('two_payments')
  twoPayments('two_payments'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const PaymentModeEnum(this.json);

  factory PaymentModeEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<PaymentModeEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
