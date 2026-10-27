import 'dart:convert';

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
    this.remaining,
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

  /// Only on `exceeds_remaining`: what is left of the debt, as the decimal
  /// string the server sent.
  final String? remaining;

  @override
  List<Object?> get props => [
    code,
    detail,
    attr,
    attemptsLeft,
    minLength,
    maxLength,
    remaining,
  ];
}

/// What went wrong with a request, read from a [DioException] once, so no
/// other code parses a response by hand.
final class ApiFailure {
  const new({
    this.statusCode,
    this.items = const [],
    this.retryAfter,
    this.requestId,
    this.reachedServer = true,
    this.cause,
  });

  /// Reads the answer of the server, or notes that there was none.
  factory from(DioException error) {
    final response = error.response;
    final cause = error.error;
    if (response == null) {
      return ApiFailure(
        reachedServer: false,
        cause: cause is DataException ? cause : null,
      );
    }
    return ApiFailure(
      statusCode: response.statusCode,
      items: _items(response.data),
      retryAfter: _retryAfter(response.headers.value('retry-after')),
      requestId: _requestId(response.headers.value('x-request-id')),
    );
  }

  /// The wait to show when the server answers `429` without `Retry-After`,
  /// which the contract says it never does. It is only a safety net for a
  /// server that breaks the contract: every real wait comes from the answer.
  static const missingRetryAfter = Duration(seconds: 30);

  /// The status of the answer, or `null` when the server was not reached.
  final int? statusCode;

  /// The errors of the body, empty when the body is not the documented one
  /// (a page of the platform, for instance).
  final List<ApiErrorItem> items;

  /// How long the server asks to wait (`Retry-After`, whole seconds).
  final Duration? retryAfter;

  /// The reference of the request (`X-Request-ID`), which support can find in
  /// the server's logs without any personal data. `null` when the answer has
  /// none or it is not of the documented form.
  final String? requestId;

  /// Whether the server answered at all. `false` for a lost connection, a
  /// timeout or any failure before an answer.
  final bool reachedServer;

  /// A failure that was not the network's (the secure storage, an answer that
  /// broke the contract), already worded as the exception to report.
  final DataException? cause;

  /// The first error of the body, which names the problem.
  ApiErrorItem? get first => items.isEmpty ? null : items.first;

  /// The code of the first error, if any.
  String? get code => first?.code;

  /// Whether the server said the record does not exist: a `404` with the
  /// documented body and the code `not_found`. Any other `404` (a page of the
  /// platform, a path the server does not route) is a failure, not "gone".
  bool get isNotFound => statusCode == 404 && hasCode('not_found');

  bool hasCode(String code) => items.any((item) => item.code == code);

  /// The error of the field [attr], if the server named one.
  ApiErrorItem? forField(String attr) {
    for (final item in items) {
      if (item.attr == attr) return item;
    }
    return null;
  }

  /// The failure as the exceptions every repository shares: no connection, a
  /// wait the server asks for (`429`), a busy server (`503`), a record that
  /// changed meanwhile (`412`), a first try that is still running (`409
  /// idempotency_in_progress`), or a server that failed.
  DataException toDataException() {
    final cause = this.cause;
    if (cause != null) return cause;
    if (!reachedServer) return const NoConnectionException();
    if (statusCode == 429) {
      return TooManyRequestsException(retryAfter ?? missingRetryAfter);
    }
    if (statusCode == 503) return const ServiceUnavailableException();
    if (statusCode == 412) return const StaleRecordException();
    if (statusCode == 409 && hasCode('idempotency_in_progress')) {
      return const RequestInProgressException();
    }
    return const ServerException();
  }

  static List<ApiErrorItem> _items(Object? body) {
    // A call that downloads a file reads every answer as bytes, its error
    // body too.
    final data = body is List<int> ? _json(body) : body;
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
            remaining: error['remaining'] is String
                ? error['remaining'] as String
                : null,
          ),
    ];
  }

  static Object? _json(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  static final _requestIdForm = RegExp(r'^[A-Za-z0-9-]{8,64}$');

  static String? _requestId(String? header) {
    final id = header?.trim();
    return id != null && _requestIdForm.hasMatch(id) ? id : null;
  }

  static int? _int(Object? value) => value is int ? value : null;

  static Duration? _retryAfter(String? header) {
    final seconds = int.tryParse(header?.trim() ?? '');
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }
}
