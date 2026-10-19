// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      codeExpiresIn: (json['code_expires_in'] as num).toInt(),
      resendAvailableIn: (json['resend_available_in'] as num).toInt(),
      email: json['email'] as String,
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'code_expires_in': instance.codeExpiresIn,
      'resend_available_in': instance.resendAvailableIn,
      'email': instance.email,
    };
