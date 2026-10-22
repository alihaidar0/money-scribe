// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetTokenResponse _$ResetTokenResponseFromJson(Map<String, dynamic> json) =>
    ResetTokenResponse(
      resetToken: json['reset_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$ResetTokenResponseToJson(ResetTokenResponse instance) =>
    <String, dynamic>{
      'reset_token': instance.resetToken,
      'expires_in': instance.expiresIn,
    };
