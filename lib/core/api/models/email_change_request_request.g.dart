// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_change_request_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailChangeRequestRequest _$EmailChangeRequestRequestFromJson(
  Map<String, dynamic> json,
) => EmailChangeRequestRequest(
  email: json['email'] as String,
  currentPassword: json['current_password'] as String,
);

Map<String, dynamic> _$EmailChangeRequestRequestToJson(
  EmailChangeRequestRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'current_password': instance.currentPassword,
};
