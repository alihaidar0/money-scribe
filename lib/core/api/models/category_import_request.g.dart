// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryImportRequest _$CategoryImportRequestFromJson(
  Map<String, dynamic> json,
) => CategoryImportRequest(
  dataset: CategoryImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => CategoryImportRowRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
  dryRun: json['dry_run'] as bool? ?? false,
);

Map<String, dynamic> _$CategoryImportRequestToJson(
  CategoryImportRequest instance,
) => <String, dynamic>{
  'dry_run': instance.dryRun,
  'dataset': _$CategoryImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$CategoryImportDatasetEnumEnumMap = {
  CategoryImportDatasetEnum.categories: 'categories',
  CategoryImportDatasetEnum.$unknown: r'$unknown',
};
