// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      type: ClientErrorEnum.fromJson(json['type'] as String),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => ErrorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'type': _$ClientErrorEnumEnumMap[instance.type]!,
      'errors': instance.errors,
    };

const _$ClientErrorEnumEnumMap = {
  ClientErrorEnum.clientError: 'client_error',
  ClientErrorEnum.$unknown: r'$unknown',
};
