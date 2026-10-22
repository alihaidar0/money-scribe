// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_verify_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordResetVerifyRequest _$PasswordResetVerifyRequestFromJson(
  Map<String, dynamic> json,
) => PasswordResetVerifyRequest(
  email: json['email'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$PasswordResetVerifyRequestToJson(
  PasswordResetVerifyRequest instance,
) => <String, dynamic>{'email': instance.email, 'code': instance.code};
