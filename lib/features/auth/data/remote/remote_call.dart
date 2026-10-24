import 'package:dio/dio.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';

/// Runs a call of the generated client and turns its failure into the
/// exceptions of the screens through [map]. [onFailure] sees the failure and
/// its exception first, to remember what the server said (a wait, an address).
Future<T> callApi<T>(
  Future<T> Function() request,
  Exception Function(ApiFailure failure) map, {
  void Function(ApiFailure failure, Exception exception)? onFailure,
}) async {
  try {
    return await request();
  } on DioException catch (error) {
    final failure = ApiFailure.from(error);
    final exception = map(failure);
    onFailure?.call(failure, exception);
    throw exception;
  } on FormatException {
    // An answer that is not what the contract says.
    throw const ServerException();
    // A body of another shape fails inside the generated `fromJson` with a
    // `TypeError`: it is the same thing, an answer that is not the contract.
    // ignore: avoid_catching_errors
  } on TypeError {
    throw const ServerException();
  }
}
