// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_sent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodeSent _$CodeSentFromJson(Map<String, dynamic> json) => CodeSent(
  codeExpiresIn: (json['code_expires_in'] as num).toInt(),
  resendAvailableIn: (json['resend_available_in'] as num).toInt(),
);

Map<String, dynamic> _$CodeSentToJson(CodeSent instance) => <String, dynamic>{
  'code_expires_in': instance.codeExpiresIn,
  'resend_available_in': instance.resendAvailableIn,
};
