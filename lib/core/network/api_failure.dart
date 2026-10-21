import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';

/// One error of the server's error body: `{code, detail, attr, ...}`. Act on
/// [code], never on [detail], which is text for developers.
final class ApiErrorItem extends Equatable {
  const new({
    required this.code,
    this.detail,
    this.attr,
    this.attemptsLeft,
    this.minLength,
    this.maxLength,
  });

  /// A stable, machine-readable code such as `code_invalid`.
  final String code;

  /// The server's English text. Shown only for a code the app does not know,
  /// where the contract says to.
  final String? detail;

  /// The field the error belongs to, or `null` for the request as a whole.
  final String? attr;

  /// Only on `code_invalid`: how many wrong tries remain.
  final int? attemptsLeft;

  /// Only on `password_too_short`: the shortest password the server accepts.
  final int? minLength;

  /// Only on `password_too_long`: the longest password the server accepts.
  final int? maxLength;

  @override
  List<Object?> get props => [
    code,
    detail,
    attr,
    attemptsLeft,
    minLength,
    maxLength,
  ];
}

/// What went wrong with a request, read from a [DioException] once, so no
/// other code parses a response by hand.
final class ApiFailure {
  const new({
    this.statusCode,
    this.items = const [],
    this.retryAfter,
    this.reachedServer = true,
  });

  /// Reads the answer of the server, or notes that there was none.
  factory from(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ApiFailure(reachedServer: false);
    }
    return ApiFailure(
      statusCode: response.statusCode,
      items: _items(response.data),
      retryAfter: _retryAfter(response.headers.value('retry-after')),
    );
  }

  /// The status of the answer, or `null` when the server was not reached.
  final int? statusCode;

  /// The errors of the body, empty when the body is not the documented one
  /// (a page of the platform, for instance).
  final List<ApiErrorItem> items;

  /// How long the server asks to wait (`Retry-After`, whole seconds).
  final Duration? retryAfter;

  /// Whether the server answered at all. `false` for a lost connection, a
  /// timeout or any failure before an answer.
  final bool reachedServer;

  /// The first error of the body, which names the problem.
  ApiErrorItem? get first => items.isEmpty ? null : items.first;

  /// The code of the first error, if any.
  String? get code => first?.code;

  bool hasCode(String code) => items.any((item) => item.code == code);

  /// The error of the field [attr], if the server named one.
  ApiErrorItem? forField(String attr) {
    for (final item in items) {
      if (item.attr == attr) return item;
    }
    return null;
  }

  /// The failure as the exceptions every repository shares: no connection, a
  /// busy server (`503`), or a server that failed.
  DataException toDataException() {
    if (!reachedServer) return const NoConnectionException();
    if (statusCode == 503) return const ServiceUnavailableException();
    return const ServerException();
  }

  static List<ApiErrorItem> _items(Object? data) {
    if (data is! Map<String, dynamic>) return const [];
    final errors = data['errors'];
    if (errors is! List<Object?>) return const [];
    return [
      for (final error in errors)
        if (error is Map<String, dynamic> && error['code'] is String)
          ApiErrorItem(
            code: error['code'] as String,
            detail: error['detail'] is String
                ? error['detail'] as String
                : null,
            attr: error['attr'] is String ? error['attr'] as String : null,
            attemptsLeft: _int(error['attempts_left']),
            minLength: _int(error['min_length']),
            maxLength: _int(error['max_length']),
          ),
    ];
  }

  static int? _int(Object? value) => value is int ? value : null;

  static Duration? _retryAfter(String? header) {
    final seconds = int.tryParse(header?.trim() ?? '');
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }
}
