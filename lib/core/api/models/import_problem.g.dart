// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportProblem _$ImportProblemFromJson(Map<String, dynamic> json) =>
    ImportProblem(
      row: (json['row'] as num).toInt(),
      code: json['code'] as String,
      attr: json['attr'] as String?,
    );

Map<String, dynamic> _$ImportProblemToJson(ImportProblem instance) =>
    <String, dynamic>{
      'row': instance.row,
      'code': instance.code,
      'attr': instance.attr,
    };
