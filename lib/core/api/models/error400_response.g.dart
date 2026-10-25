// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error400_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Error400Response _$Error400ResponseFromJson(Map<String, dynamic> json) =>
    Error400Response(
      type: Error400ResponseTypeEnum.fromJson(json['type'] as String),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => ErrorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$Error400ResponseToJson(Error400Response instance) =>
    <String, dynamic>{
      'type': _$Error400ResponseTypeEnumEnumMap[instance.type]!,
      'errors': instance.errors,
    };

const _$Error400ResponseTypeEnumEnumMap = {
  Error400ResponseTypeEnum.validationError: 'validation_error',
  Error400ResponseTypeEnum.clientError: 'client_error',
  Error400ResponseTypeEnum.$unknown: r'$unknown',
};
