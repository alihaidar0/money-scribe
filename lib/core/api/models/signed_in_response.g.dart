// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_in_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedInResponse _$SignedInResponseFromJson(Map<String, dynamic> json) =>
    SignedInResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$SignedInResponseToJson(SignedInResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'user': instance.user,
    };
