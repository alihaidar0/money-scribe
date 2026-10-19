// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'auth/auth_client.dart';

/// API `v0.1.0`.
///
/// The HTTP API of this project, generated from its code.
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  AuthClient? _auth;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);
}
