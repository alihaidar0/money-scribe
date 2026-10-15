#!/usr/bin/env bash
# Generates the typed API client from the pinned contract (api/openapi.yaml).
#
# One home for the generation commands: scripts/sync-api.sh runs this after it
# pins a new contract, and the "API client is current" CI job runs it to prove
# that the committed client matches the contract. Run it by hand after editing
# swagger_parser.yaml or after upgrading swagger_parser, retrofit_generator or
# json_serializable.
#
#   1. swagger_parser   api/openapi.yaml  ->  lib/core/api (Retrofit clients, models)
#   2. build_runner     the *.g.dart files those clients and models need
#   3. dart format      so the output matches the formatter width of the project
#                       (analysis_options.yaml) and `dart format` in CI stays green
#
# The one-time setup (the packages) is described in docs/backend-api.md.
#
# Usage: scripts/generate-api.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Where the client is written. It must match `output_directory` in
# swagger_parser.yaml, the generated-code settings (.gitattributes,
# analysis_options.yaml, cspell.json) and the "API client is current" job.
api_dir="lib/core/api"

fail() {
  echo "Error: $*" >&2
  exit 1
}

# ── Preconditions ───────────────────────────────────────────────────────────
[[ -f api/openapi.yaml ]] \
  || fail "api/openapi.yaml not found. Pin a contract first: scripts/sync-api.sh vX.Y.Z"
[[ -f swagger_parser.yaml ]] \
  || fail "swagger_parser.yaml not found at the repository root."
[[ -f pubspec.yaml ]] \
  || fail "pubspec.yaml not found. Run this from the repository root."
command -v dart >/dev/null 2>&1 \
  || fail "dart is not on the PATH. Run this inside the dev container."

grep -Eq "^[[:space:]]+output_directory:[[:space:]]*${api_dir}[[:space:]]*(#.*)?$" swagger_parser.yaml \
  || fail "output_directory in swagger_parser.yaml must be ${api_dir} (it is set at the top of this script)."

if ! grep -Eq '^[[:space:]]+swagger_parser:' pubspec.yaml; then
  fail "swagger_parser is not a dev dependency of this project. Add the client packages first
(docs/backend-api.md, section 1)."
fi

# A Flutter project needs `flutter pub get` (not `dart pub get`) before `dart run`.
if [[ ! -f .dart_tool/package_config.json ]]; then
  command -v flutter >/dev/null 2>&1 || fail "flutter is not on the PATH. Run this inside the dev container."
  flutter pub get
fi

# ── Generate ────────────────────────────────────────────────────────────────
echo "Generating the API client from api/openapi.yaml into ${api_dir} ..."
dart run swagger_parser
dart run build_runner build --delete-conflicting-outputs
dart format "$api_dir"

echo "Done. Review and commit ${api_dir}."
