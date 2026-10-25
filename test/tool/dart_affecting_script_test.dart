import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs scripts/dart-affecting.sh with [files] on its standard input.
Future<int> _run(List<String> files) async {
  final process = await Process.start('bash', ['scripts/dart-affecting.sh']);
  process.stdin.write(files.join('\n'));
  await process.stdin.close();
  // Drain the output so the process can finish.
  await process.stdout.transform(utf8.decoder).join();
  await process.stderr.transform(utf8.decoder).join();
  return await process.exitCode;
}

void main() {
  group('affects the Dart checks', () {
    for (final file in [
      'lib/main.dart',
      'lib/core/l10n/arb/app_en.arb',
      'test/app/app_test.dart',
      'tool/changed_scope.dart',
      'pubspec.yaml',
      'pubspec.lock',
      'analysis_options.yaml',
      'l10n.yaml',
      'dart_test.yaml',
      'assets/fonts/Inter-Regular.ttf',
      'api/openapi.yaml',
      'swagger_parser.yaml',
      'docs/DESIGN.md',
      '.github/workflows/ci.yml',
      '.github/actions/setup-flutter/action.yml',
      'scripts/dart-affecting.sh',
    ]) {
      test(file, () async => expect(await _run([file]), 0));
    }
  });

  group('does not affect them', () {
    for (final file in [
      'docs/steps.md',
      'docs/architecture.md',
      'README.md',
      'CONTRIBUTING.md',
      '.github/workflows/build.yml',
      '.github/workflows/labels.yml',
      '.github/PULL_REQUEST_TEMPLATE.md',
      'scripts/welcome.sh',
      '.husky/pre-commit',
      '.vscode/launch.json',
      'android/app/build.gradle.kts',
      'ios/Runner/Info.plist',
      '.env.example',
      'cspell.json',
    ]) {
      test(file, () async => expect(await _run([file]), 1));
    }
  });

  test('one affecting file among documents is enough', () async {
    expect(await _run(['docs/steps.md', 'lib/main.dart', 'README.md']), 0);
  });

  test('an empty change affects nothing', () async {
    expect(await _run([]), 1);
    expect(await _run(['', '']), 1);
  });
}
