#!/usr/bin/env bash
# Replaces the template's README.md (the template guide) with a README for THIS
# app: its name, description, badges, platforms and the toolchain versions it
# really uses. Run it once, after `flutter create` and `scripts/pin-image.sh`.
#
# Usage: scripts/init-readme.sh [--description "text"] [--name "App Name"]
#                               [--repo OWNER/REPO] [--template-release vYYYY.MM.DD[.n]]
#                               [--force]
#   --description  what the app does, one or two sentences (default: a TODO line)
#   --name         the title (default: the repository name, "money-scribe" -> "Money Scribe")
#   --repo         for the badges (default: read from the `origin` remote)
#   --template-release
#                  the template release the app started from (default: the newest
#                  release on GitHub; pass the one you started from if you run this later)
#   --force        overwrite a README that is no longer the template guide
#
# Everything is read from the project: Flutter and Dart from the container (the
# `environment: flutter:` pin wins), the dev image from docker-compose.yml, Node,
# pnpm, Husky and commitlint from package.json, the platforms from the folders
# `flutter create` made, the copyright line from LICENSE. Nothing private is written.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readme="$root/README.md"
template_repo="alihaidar0/flutter-template"

usage() {
  sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed -e '$d' -e 's/^# \{0,1\}//'
}

die() {
  echo "$1" >&2
  exit 1
}

# ── Arguments ────────────────────────────────────────────────────────────────
name="" description="" repo="" template_release="" force=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) name="${2:?--name needs a value}"; shift 2 ;;
    --description) description="${2:?--description needs a value}"; shift 2 ;;
    --repo) repo="${2:?--repo needs OWNER/REPO}"; shift 2 ;;
    --template-release) template_release="${2:?--template-release needs a tag}"; shift 2 ;;
    --force) force=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown argument: $1" ;;
  esac
done

# ── Preconditions ────────────────────────────────────────────────────────────
[[ -f "$root/pubspec.yaml" ]] \
  || die "No pubspec.yaml yet: run 'flutter create --org com.yourcompany .' first, then this script."

# The template guide starts with this heading. Anything else is already your README.
if [[ "$force" -ne 1 && -f "$readme" && "$(head -n 1 "$readme")" != "# flutter-template" ]]; then
  die "README.md is no longer the template guide, so it was left alone. Use --force to overwrite it."
fi

# ── Repository (for the badges) ─────────────────────────────────────────────
if [[ -z "$repo" ]]; then
  url="$(git -C "$root" remote get-url origin 2>/dev/null || true)"
  repo="$(sed -nE 's#^.*[:/]([^/:]+/[^/]+)$#\1#p' <<<"$url")"
  repo="${repo%.git}"
fi
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] \
  || die "Could not read OWNER/REPO from the origin remote. Pass it: --repo OWNER/REPO"

# ── Name and description ─────────────────────────────────────────────────────
if [[ -z "$name" ]]; then
  # "money-scribe" / "money_scribe" -> "Money Scribe"
  name="$(tr '_-' '  ' <<<"${repo#*/}" \
    | awk '{ for (i = 1; i <= NF; i++) $i = toupper(substr($i, 1, 1)) substr($i, 2) } 1')"
fi
todo=0
if [[ -z "$description" ]]; then
  description="TODO: describe what the app does in one or two sentences."
  todo=1
fi
description="$(fold -s -w 80 <<<"$description" | sed 's/[[:space:]]*$//')"

# ── Platforms: the folders flutter create made ──────────────────────────────
platforms=()
for entry in android:Android ios:iOS web:web linux:Linux macos:macOS windows:Windows; do
  if [[ -d "$root/${entry%%:*}" ]]; then
    platforms+=("${entry#*:}")
  fi
done
case ${#platforms[@]} in
  0) platforms_text="Not decided yet." ;;
  1) platforms_text="${platforms[0]}." ;;
  *)
    head_text="$(printf '%s, ' "${platforms[@]:0:${#platforms[@]}-1}")"
    platforms_text="${head_text%, } and ${platforms[${#platforms[@]}-1]}."
    ;;
esac

# ── Versions ─────────────────────────────────────────────────────────────────
flutter_json=""
if command -v flutter >/dev/null 2>&1; then
  flutter_json="$(flutter --version --machine 2>/dev/null || true)"
fi
json_field() {
  sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/p" <<<"$flutter_json" | head -n 1
}
pkg_version() {
  sed -nE "s#.*\"$1\"[[:space:]]*:[[:space:]]*\"[^0-9\"]*([0-9][^\"]*)\".*#\1#p" "$root/package.json" | head -n 1
}

# The pin in pubspec.yaml is what CI installs, so it wins over the running Flutter.
flutter_version="$(sed -nE 's/^[[:space:]]+flutter:[[:space:]]*([0-9][^[:space:]#]*).*/\1/p' "$root/pubspec.yaml" | head -n 1)"
[[ -n "$flutter_version" ]] || flutter_version="$(json_field frameworkVersion)"
dart_version="$(json_field dartSdkVersion)"
dart_version="${dart_version%% *}"
image="$(sed -nE 's/^[[:space:]]*image:[[:space:]]*([^[:space:]@]+).*/\1/p' "$root/docker-compose.yml" | head -n 1)"
node_major="$(sed -nE 's#.*"node"[[:space:]]*:[[:space:]]*"[^0-9"]*([0-9]+).*#\1#p' "$root/package.json" | head -n 1)"
pnpm_version="$(sed -nE 's#.*"packageManager"[[:space:]]*:[[:space:]]*"pnpm@([^"+]+).*#\1#p' "$root/package.json" | head -n 1)"
husky_version="$(pkg_version husky)"
commitlint_version="$(pkg_version @commitlint/cli)"

flutter_text="${flutter_version:+${flutter_version} (stable)}"
dart_text="${dart_version:-—}"
image_text="${image:+\`${image}\`}"
[[ "$image" == *:latest ]] && echo "Note: the dev image is not pinned yet; run scripts/pin-image.sh and re-run this script." >&2
[[ -n "$flutter_text" ]] || echo "Note: Flutter was not found; run this inside the dev container." >&2

# ── Template release ─────────────────────────────────────────────────────────
if [[ -z "$template_release" ]]; then
  template_release="$(curl -fsSL --max-time 10 "https://api.github.com/repos/${template_repo}/releases/latest" 2>/dev/null \
    | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1 || true)"
fi
if [[ -n "$template_release" ]]; then
  template_text="Created from [\`${template_repo}\`](https://github.com/${template_repo})
release [\`${template_release}\`](https://github.com/${template_repo}/releases/tag/${template_release})."
else
  template_text="Created from [\`${template_repo}\`](https://github.com/${template_repo}).
Note the template release it started from here
(see its [Releases](https://github.com/${template_repo}/releases) page)."
  echo "Note: could not read the template's newest release; fill in the Template section yourself." >&2
fi

# ── License ──────────────────────────────────────────────────────────────────
license_badge=""
license_text="See [LICENSE](LICENSE)."
if [[ -f "$root/LICENSE" ]]; then
  if head -n 1 "$root/LICENSE" | grep -qi '^MIT License'; then
    license_badge="[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)"
    license_text="[MIT](LICENSE)"
  fi
  copyright="$(sed -nE 's/^Copyright \(c\) (.+)$/\1/p' "$root/LICENSE" | head -n 1)"
  if [[ -n "$copyright" ]]; then
    license_text="${license_text%.} © ${copyright}"
  fi
fi

# ── Write ────────────────────────────────────────────────────────────────────
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
{
  printf '# %s\n\n%s\n\n' "$name" "$description"
  printf '[![CI](https://github.com/%s/actions/workflows/ci.yml/badge.svg)](https://github.com/%s/actions/workflows/ci.yml)\n' "$repo" "$repo"
  printf '[![Build](https://github.com/%s/actions/workflows/build.yml/badge.svg)](https://github.com/%s/actions/workflows/build.yml)\n' "$repo" "$repo"
  [[ -z "$license_badge" ]] || printf '%s\n' "$license_badge"
  printf '\n> **Status:** in development.\n\n'
  printf '## Platforms\n\n%s\n\n' "$platforms_text"
  printf '## Stack\n\n| Component | Version |\n| --- | --- |\n'
  printf '| Flutter | %s |\n' "${flutter_text:-—}"
  printf '| Dart | %s |\n' "$dart_text"
  printf '| Dev container image | %s |\n' "${image_text:-—}"
  printf '| Node.js (git tooling) | %s |\n' "${node_major:-—}"
  printf '| pnpm | %s |\n' "${pnpm_version:-—}"
  printf '| Husky | %s |\n' "${husky_version:-—}"
  printf '| commitlint | %s |\n\n' "${commitlint_version:-—}"
  # shellcheck disable=SC2016 # the backticks are Markdown, not command substitution
  printf 'Application libraries and their exact versions are pinned in `pubspec.yaml` and\n`pubspec.lock`.\n\n'
  printf '## Template\n\n%s\n\n' "$template_text"
  printf '## License\n\n%s\n' "$license_text"
} >"$tmp"
cat "$tmp" >"$readme"

echo "Wrote README.md for ${name} (${repo})."
echo ""
echo "Next steps:"
if [[ "$todo" -eq 1 ]]; then
  echo "  - Replace the TODO description in README.md (or re-run with --description \"…\" --force)."
fi
echo "  - Add what the app is for (features, how to run it) as it grows; the Stack table is yours to extend."
echo "  - Commit README.md."
