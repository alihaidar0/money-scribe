// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'account_import_dataset_enum.dart';
import 'account_import_request.dart';
import 'account_import_row_request.dart';
import 'category_import_dataset_enum.dart';
import 'category_import_request.dart';
import 'category_import_row_request.dart';
import 'debt_import_dataset_enum.dart';
import 'debt_import_request.dart';
import 'debt_import_row_request.dart';
import 'salary_month_import_dataset_enum.dart';
import 'salary_month_import_request.dart';
import 'salary_month_import_row_request.dart';
import 'transaction_import_dataset_enum.dart';
import 'transaction_import_request.dart';
import 'transaction_import_row_request.dart';

part 'import_request.g.dart';

@JsonSerializable(createFactory: false)
sealed class ImportRequest {
  const ImportRequest();

  factory ImportRequest.fromJson(Map<String, dynamic> json) =>
      ImportRequestSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension ImportRequestSealedDeserializer on ImportRequest {
  static ImportRequest tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'dataset',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      ImportRequestAccountImportRequest: 'accounts',
      ImportRequestCategoryImportRequest: 'categories',
      ImportRequestTransactionImportRequest: 'transactions',
      ImportRequestDebtImportRequest: 'debts',
      ImportRequestSalaryMonthImportRequest: 'salary_months',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[ImportRequestAccountImportRequest] =>
        ImportRequestAccountImportRequest.fromJson(json),
      _ when value == effective[ImportRequestCategoryImportRequest] =>
        ImportRequestCategoryImportRequest.fromJson(json),
      _ when value == effective[ImportRequestTransactionImportRequest] =>
        ImportRequestTransactionImportRequest.fromJson(json),
      _ when value == effective[ImportRequestDebtImportRequest] =>
        ImportRequestDebtImportRequest.fromJson(json),
      _ when value == effective[ImportRequestSalaryMonthImportRequest] =>
        ImportRequestSalaryMonthImportRequest.fromJson(json),
      _ => throw FormatException(
        'Unknown discriminator value "${json[key]}" for ImportRequest',
      ),
    };
  }
}

@JsonSerializable()
class ImportRequestAccountImportRequest extends ImportRequest
    implements AccountImportRequest {
  @override
  final bool dryRun;
  @override
  final AccountImportDatasetEnum dataset;
  @override
  final List<AccountImportRowRequest> rows;

  const ImportRequestAccountImportRequest({
    required this.dryRun,
    required this.dataset,
    required this.rows,
  });

  factory ImportRequestAccountImportRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$ImportRequestAccountImportRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$ImportRequestAccountImportRequestToJson(this);
}

@JsonSerializable()
class ImportRequestCategoryImportRequest extends ImportRequest
    implements CategoryImportRequest {
  @override
  final bool dryRun;
  @override
  final CategoryImportDatasetEnum dataset;
  @override
  final List<CategoryImportRowRequest> rows;

  const ImportRequestCategoryImportRequest({
    required this.dryRun,
    required this.dataset,
    required this.rows,
  });

  factory ImportRequestCategoryImportRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$ImportRequestCategoryImportRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$ImportRequestCategoryImportRequestToJson(this);
}

@JsonSerializable()
class ImportRequestTransactionImportRequest extends ImportRequest
    implements TransactionImportRequest {
  @override
  final bool dryRun;
  @override
  final TransactionImportDatasetEnum dataset;
  @override
  final List<TransactionImportRowRequest> rows;

  const ImportRequestTransactionImportRequest({
    required this.dryRun,
    required this.dataset,
    required this.rows,
  });

  factory ImportRequestTransactionImportRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$ImportRequestTransactionImportRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$ImportRequestTransactionImportRequestToJson(this);
}

@JsonSerializable()
class ImportRequestDebtImportRequest extends ImportRequest
    implements DebtImportRequest {
  @override
  final bool dryRun;
  @override
  final DebtImportDatasetEnum dataset;
  @override
  final List<DebtImportRowRequest> rows;

  const ImportRequestDebtImportRequest({
    required this.dryRun,
    required this.dataset,
    required this.rows,
  });

  factory ImportRequestDebtImportRequest.fromJson(Map<String, dynamic> json) =>
      _$ImportRequestDebtImportRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ImportRequestDebtImportRequestToJson(this);
}

@JsonSerializable()
class ImportRequestSalaryMonthImportRequest extends ImportRequest
    implements SalaryMonthImportRequest {
  @override
  final bool dryRun;
  @override
  final SalaryMonthImportDatasetEnum dataset;
  @override
  final List<SalaryMonthImportRowRequest> rows;

  const ImportRequestSalaryMonthImportRequest({
    required this.dryRun,
    required this.dataset,
    required this.rows,
  });

  factory ImportRequestSalaryMonthImportRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$ImportRequestSalaryMonthImportRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$ImportRequestSalaryMonthImportRequestToJson(this);
}
