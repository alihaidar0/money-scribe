// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_confirm_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordResetConfirmRequest _$PasswordResetConfirmRequestFromJson(
  Map<String, dynamic> json,
) => PasswordResetConfirmRequest(
  resetToken: json['reset_token'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$PasswordResetConfirmRequestToJson(
  PasswordResetConfirmRequest instance,
) => <String, dynamic>{
  'reset_token': instance.resetToken,
  'password': instance.password,
};
