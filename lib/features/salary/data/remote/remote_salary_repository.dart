import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/paged.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/features/salary/data/remote/salary_wire.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';

/// The saved salary months on the server: the real [SalaryRepository].
class RemoteSalaryRepository implements SalaryRepository {
  new({required this._client, required this._baseUrl});

  /// The salary calls over [dio], which carries the token of the session and
  /// renews it.
  factory create({required Dio dio}) {
    return RemoteSalaryRepository(
      client: api.SalaryClient(dio),
      baseUrl: dio.options.baseUrl,
    );
  }

  /// Most months a page holds, to read a long history in few calls.
  static const _pageSize = 100;

  final api.SalaryClient _client;

  /// The address of the server: a page of a list is followed only there.
  final String _baseUrl;

  /// The server does not push changes, and the app is the only writer on this
  /// device: a screen loads again when it is opened.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<SalaryMonth?> month(YearMonth month) async {
    try {
      final wire = await callApi(
        () => _client.salaryMonthRead(month: month.param),
        _mapMissing,
      );
      return SalaryWire.month(wire);
    } on _Missing {
      return null;
    }
  }

  @override
  Future<List<SalaryMonth>> savedMonths() async {
    final wire = await readAllPages<api.SalaryMonth>((next) async {
      final page = await callApi(
        () => _client.salaryMonthList(
          cursor: cursorOfNextPage(next, baseUrl: _baseUrl),
          limit: _pageSize,
        ),
        _map,
      );
      return Paged(items: page.results, next: page.next);
    });
    return [for (final month in wire) SalaryWire.month(month)];
  }

  @override
  Future<SalaryDefaults> defaults(YearMonth month) async {
    final wire = await callApi(
      () => _client.salaryMonthDefaults(month: month.param),
      _map,
    );
    return SalaryWire.defaults(wire);
  }

  @override
  Future<SalaryMonth> save(SalaryMonth month) async {
    final body = SalaryWire.monthInput(month);
    final version = month.version;
    final wire = await callApi(
      // A month that was not found is created only if it still does not
      // exist, so one made meanwhile on another device is never replaced.
      () => _client.salaryMonthPut(
        month: month.month.param,
        body: body,
        ifMatch: version == null ? null : WriteSafetyHeaders.ifMatch(version),
        ifNoneMatch: version == null ? WriteSafetyHeaders.ifNoneMatchAny : null,
      ),
      _map,
    );
    return SalaryWire.month(wire);
  }

  @override
  Future<void> delete(YearMonth month, {required int version}) async {
    try {
      await callApi(
        () => _client.salaryMonthDelete(
          month: month.param,
          ifMatch: WriteSafetyHeaders.ifMatch(version),
        ),
        _mapMissing,
      );
    } on _Missing {
      // Already gone: the person wanted it gone.
    }
  }

  Exception _map(ApiFailure failure) => failure.toDataException();

  /// Like [_map], but a `404` with the code `not_found` is "there is no such
  /// month", which is not a failure.
  Exception _mapMissing(ApiFailure failure) {
    return failure.isNotFound ? const _Missing() : _map(failure);
  }
}

/// The answer was `404 not_found`: nothing is saved there.
final class _Missing implements Exception {
  const new();
}
