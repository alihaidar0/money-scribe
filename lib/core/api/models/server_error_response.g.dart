// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerErrorResponse _$ServerErrorResponseFromJson(Map<String, dynamic> json) =>
    ServerErrorResponse(
      type: ServerErrorEnum.fromJson(json['type'] as String),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => ErrorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServerErrorResponseToJson(
  ServerErrorResponse instance,
) => <String, dynamic>{
  'type': _$ServerErrorEnumEnumMap[instance.type]!,
  'errors': instance.errors,
};

const _$ServerErrorEnumEnumMap = {
  ServerErrorEnum.serverError: 'server_error',
  ServerErrorEnum.$unknown: r'$unknown',
};
