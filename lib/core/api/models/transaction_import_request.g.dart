// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionImportRequest _$TransactionImportRequestFromJson(
  Map<String, dynamic> json,
) => TransactionImportRequest(
  dataset: TransactionImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map(
        (e) => TransactionImportRowRequest.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  dryRun: json['dry_run'] as bool? ?? false,
);

Map<String, dynamic> _$TransactionImportRequestToJson(
  TransactionImportRequest instance,
) => <String, dynamic>{
  'dry_run': instance.dryRun,
  'dataset': _$TransactionImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$TransactionImportDatasetEnumEnumMap = {
  TransactionImportDatasetEnum.transactions: 'transactions',
  TransactionImportDatasetEnum.$unknown: r'$unknown',
};
