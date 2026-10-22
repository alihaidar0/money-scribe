// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_change_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailChangeResponse _$EmailChangeResponseFromJson(Map<String, dynamic> json) =>
    EmailChangeResponse(
      codeExpiresIn: (json['code_expires_in'] as num).toInt(),
      resendAvailableIn: (json['resend_available_in'] as num).toInt(),
      email: json['email'] as String,
    );

Map<String, dynamic> _$EmailChangeResponseToJson(
  EmailChangeResponse instance,
) => <String, dynamic>{
  'code_expires_in': instance.codeExpiresIn,
  'resend_available_in': instance.resendAvailableIn,
  'email': instance.email,
};
