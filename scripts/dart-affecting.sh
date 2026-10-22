#!/usr/bin/env bash
# Says whether a change can affect the Dart checks (format, analyze, tests, the
# generated API client, the dependency audit).
#
# Reads file paths from standard input, one per line (for example the output of
# `git diff --name-only`). Exits 0 when at least one of them can affect the
# Dart checks, 1 when none can (documentation, other workflows, scripts, the
# platform folders). The first file that decides is printed to standard error.
#
# One list for everything that cares: the pre-commit and pre-push hooks and the
# "Detect what changed" step of ci.yml. Keep it in step with what the tests
# read from disk (test/architecture_test.dart scans lib/, the theme tests read
# docs/DESIGN.md and pubspec.yaml, the font tests read assets/).
#
# Usage: git diff --name-only | bash scripts/dart-affecting.sh
set -euo pipefail

# `|| [[ -n $file ]]` also reads a last line that has no trailing newline.
while IFS= read -r file || [[ -n "$file" ]]; do
  [[ -n "$file" ]] || continue
  case "$file" in
    # Source and tests (including support code and the tools in tool/).
    lib/* | test/* | tool/* | *.dart) ;;
    # Strings and assets: they change what the app shows and what tests read.
    *.arb | assets/*) ;;
    # Project configuration that every Dart check reads.
    pubspec.yaml | pubspec.lock | analysis_options.yaml | l10n.yaml | dart_test.yaml) ;;
    # The API contract and its generator settings (the client check).
    api/* | swagger_parser.yaml | scripts/generate-api.sh | scripts/sync-api.sh) ;;
    # A document the theme tests read.
    docs/DESIGN.md) ;;
    # This file and the pipeline that uses it: a change must be tried for real.
    scripts/dart-affecting.sh | .github/workflows/ci.yml | .github/actions/setup-flutter/*) ;;
    *) continue ;;
  esac
  echo "dart-affecting: $file" >&2
  exit 0
done

exit 1
