// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorItem _$ErrorItemFromJson(Map<String, dynamic> json) => ErrorItem(
  code: json['code'] as String,
  detail: json['detail'] as String,
  attr: json['attr'] as String?,
  attemptsLeft: (json['attempts_left'] as num?)?.toInt(),
  minLength: (json['min_length'] as num?)?.toInt(),
  maxLength: (json['max_length'] as num?)?.toInt(),
);

Map<String, dynamic> _$ErrorItemToJson(ErrorItem instance) => <String, dynamic>{
  'code': instance.code,
  'detail': instance.detail,
  'attr': instance.attr,
  'attempts_left': instance.attemptsLeft,
  'min_length': instance.minLength,
  'max_length': instance.maxLength,
};
