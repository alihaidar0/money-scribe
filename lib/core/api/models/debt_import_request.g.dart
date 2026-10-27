// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtImportRequest _$DebtImportRequestFromJson(Map<String, dynamic> json) =>
    DebtImportRequest(
      dataset: DebtImportDatasetEnum.fromJson(json['dataset'] as String),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => DebtImportRowRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      dryRun: json['dry_run'] as bool? ?? false,
    );

Map<String, dynamic> _$DebtImportRequestToJson(DebtImportRequest instance) =>
    <String, dynamic>{
      'dry_run': instance.dryRun,
      'dataset': _$DebtImportDatasetEnumEnumMap[instance.dataset]!,
      'rows': instance.rows,
    };

const _$DebtImportDatasetEnumEnumMap = {
  DebtImportDatasetEnum.debts: 'debts',
  DebtImportDatasetEnum.$unknown: r'$unknown',
};
