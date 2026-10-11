import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the layering described in `docs/architecture.md` true: dependencies
/// only point inward, so a layer never imports one that sits above it.
///
/// Each rule says what a group of files must not import.
class _Rule {
  const new(this.name, this.appliesTo, this.forbidden);

  final String name;

  /// Matches the path of a file under `lib/`, such as `features/a/bloc/b.dart`.
  final RegExp appliesTo;

  /// Matches an import: a `package:money_scribe/...` path without the
  /// package name, or the whole `package:` or `dart:` URI of another package.
  final RegExp forbidden;
}

final _rules = [
  _Rule(
    'core does not depend on the app or on features',
    RegExp('^core/'),
    RegExp('^(app|features)/'),
  ),
  _Rule(
    'features do not depend on the app',
    RegExp('^features/'),
    RegExp('^app/'),
  ),
  _Rule(
    'domain is plain Dart: no Flutter, no state management, no other layer',
    RegExp('^features/[^/]+/domain/'),
    RegExp(
      '^(package:flutter|package:flutter_bloc|package:go_router)'
      '|^features/[^/]+/(data|bloc|presentation)/',
    ),
  ),
  _Rule(
    'data does not depend on state management or screens',
    RegExp('^features/[^/]+/data/'),
    RegExp(
      '^(package:flutter_bloc|package:go_router)'
      '|^features/[^/]+/(bloc|presentation)/',
    ),
  ),
  _Rule(
    'a Bloc is free of Flutter and does not reach data or screens',
    RegExp('^features/[^/]+/bloc/'),
    RegExp(
      '^(package:flutter/|package:flutter_bloc|package:go_router)'
      '|^features/[^/]+/(data|presentation)/',
    ),
  ),
];

final _packageImport = RegExp(
  r'''^(?:import|export)\s+'(package:[^']+|dart:[^']+)';''',
  multiLine: true,
);

/// The feature a path belongs to, or `null` outside `features/`.
String? _featureOf(String path) {
  final match = RegExp('^features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('generated'))
      .toList();

  test('there are source files to check', () {
    expect(files, isNotEmpty);
  });

  for (final rule in _rules) {
    test(rule.name, () {
      final violations = <String>[];
      for (final file in files) {
        final path = file.path.substring('lib/'.length);
        if (!rule.appliesTo.hasMatch(path)) continue;
        for (final match in _packageImport.allMatches(
          file.readAsStringSync(),
        )) {
          final uri = match.group(1)!;
          final target = uri.startsWith('package:money_scribe/')
              ? uri.substring('package:money_scribe/'.length)
              : uri;
          if (rule.forbidden.hasMatch(target)) {
            violations.add('$path imports $uri');
          }
        }
      }

      expect(violations, isEmpty);
    });
  }

  test('a feature reaches another only through its screens', () {
    final violations = <String>[];
    for (final file in files) {
      final path = file.path.substring('lib/'.length);
      final feature = _featureOf(path);
      if (feature == null) continue;
      for (final match in _packageImport.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        if (!uri.startsWith('package:money_scribe/features/')) continue;
        final target = uri.substring('package:money_scribe/'.length);
        final targetFeature = _featureOf(target);
        if (targetFeature != feature && !target.contains('/presentation/')) {
          violations.add('$path imports $uri');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
