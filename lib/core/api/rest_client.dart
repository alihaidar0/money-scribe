// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'accounts/accounts_client.dart';
import 'auth/auth_client.dart';
import 'sessions/sessions_client.dart';
import 'categories/categories_client.dart';
import 'debts/debts_client.dart';
import 'exports/exports_client.dart';
import 'imports/imports_client.dart';
import 'overview/overview_client.dart';
import 'reports/reports_client.dart';
import 'salary/salary_client.dart';
import 'settings/settings_client.dart';
import 'transactions/transactions_client.dart';

/// API `v0.1.0`.
///
/// The HTTP API of this project, generated from its code.
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  AccountsClient? _accounts;
  AuthClient? _auth;
  SessionsClient? _sessions;
  CategoriesClient? _categories;
  DebtsClient? _debts;
  ExportsClient? _exports;
  ImportsClient? _imports;
  OverviewClient? _overview;
  ReportsClient? _reports;
  SalaryClient? _salary;
  SettingsClient? _settings;
  TransactionsClient? _transactions;

  AccountsClient get accounts =>
      _accounts ??= AccountsClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  SessionsClient get sessions =>
      _sessions ??= SessionsClient(_dio, baseUrl: _baseUrl);

  CategoriesClient get categories =>
      _categories ??= CategoriesClient(_dio, baseUrl: _baseUrl);

  DebtsClient get debts => _debts ??= DebtsClient(_dio, baseUrl: _baseUrl);

  ExportsClient get exports =>
      _exports ??= ExportsClient(_dio, baseUrl: _baseUrl);

  ImportsClient get imports =>
      _imports ??= ImportsClient(_dio, baseUrl: _baseUrl);

  OverviewClient get overview =>
      _overview ??= OverviewClient(_dio, baseUrl: _baseUrl);

  ReportsClient get reports =>
      _reports ??= ReportsClient(_dio, baseUrl: _baseUrl);

  SalaryClient get salary => _salary ??= SalaryClient(_dio, baseUrl: _baseUrl);

  SettingsClient get settings =>
      _settings ??= SettingsClient(_dio, baseUrl: _baseUrl);

  TransactionsClient get transactions =>
      _transactions ??= TransactionsClient(_dio, baseUrl: _baseUrl);
}
