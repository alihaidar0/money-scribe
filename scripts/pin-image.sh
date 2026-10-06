#!/usr/bin/env bash
# Freezes the toolchain of THIS project to the versions you are running now.
#
# The template follows the newest flutter-devcontainer image (`:latest`). A
# project created from it should not change under you, so run this once after
# `flutter create`:
#   1. docker-compose.yml: the `image:` line becomes <repo>:<tag>@sha256:<digest>,
#      so Docker pulls exactly that build until you run the script again (or
#      merge a Dependabot pull request, once its docker-compose block is enabled).
#   2. pubspec.yaml (when it exists): `environment: flutter:` is set to the
#      Flutter version of this container, which CI then installs; `flutter pub
#      get` refreshes pubspec.lock to match.
#
# Usage: scripts/pin-image.sh [tag]
#   tag  defaults to the newest flutter-X.Y.Z.R published for the Flutter in this
#        container (X.Y.Z = Flutter release, R = image revision; a tag is never
#        changed or deleted). When that Flutter has no tag, the newest
#        flutter-X.Y.Z.R overall is used, and `latest` as the last resort.
set -euo pipefail

repo="alihaidar199527/flutter-devcontainer"
compose="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.yml"

# Newest flutter-X.Y.Z.R tag whose name contains $1 (empty when none exists).
newest_tag() {
  curl -fsSL "https://hub.docker.com/v2/repositories/${repo}/tags?page_size=100&name=$1" 2>/dev/null \
    | grep -oE '"name"[[:space:]]*:[[:space:]]*"flutter-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' \
    | sed -E 's/.*"(flutter-[^"]+)"$/\1/' | sort -V | tail -1 || true
}

tag="${1:-}"
flutter_version=""
if command -v flutter >/dev/null 2>&1; then
  flutter_version="$(flutter --version --machine 2>/dev/null \
    | sed -nE 's/.*"frameworkVersion"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -1 || true)"
fi
if [[ -z "$tag" ]]; then
  [[ -n "$flutter_version" ]] && tag="$(newest_tag "flutter-${flutter_version}.")"
  [[ -z "$tag" ]] && tag="$(newest_tag "flutter-")"
  [[ -z "$tag" ]] && tag="latest"
  echo "Selected image tag: ${tag}"
fi

# The image decides which Flutter the project runs. Only write the Flutter pin
# to pubspec.yaml when the chosen tag is the Flutter of this container; for any
# other tag (a newer release, `latest`) pubspec.yaml must wait until the
# container has been rebuilt from the pinned image and this script runs again.
pin_flutter=1
if [[ -n "$flutter_version" && "$tag" != "flutter-${flutter_version}."* ]]; then
  pin_flutter=0
  echo "Warning: ${tag} is not a flutter-${flutter_version}.R tag, so pubspec.yaml is left unchanged." >&2
  echo "         Rebuild the container, then run scripts/pin-image.sh again to pin the new Flutter." >&2
fi

# ── Resolve the tag to its immutable digest (anonymous Docker Hub pull token) ──
token="$(curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
  | sed -nE 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
digest="$(
  curl -fsSI \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json" \
    "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" \
    | awk 'tolower($1) == "docker-content-digest:" { print $2 }' | tr -d '\r'
)" || digest=""
if [[ ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "Could not resolve ${repo}:${tag} on Docker Hub (is the tag published?)." >&2
  echo "Pass an existing tag explicitly (see the tags page on Docker Hub), for example:" >&2
  echo "  scripts/pin-image.sh flutter-X.Y.Z.R   or   scripts/pin-image.sh latest" >&2
  exit 1
fi

pinned="${repo}:${tag}@${digest}"
sed -i -E "s#^([[:space:]]*image:[[:space:]]*)${repo}[^[:space:]]*#\1${pinned}#" "$compose"
if ! grep -qF "image: ${pinned}" "$compose"; then
  echo "docker-compose.yml has no 'image: ${repo}…' line to pin." >&2
  exit 1
fi

echo "Pinned the dev image:"
echo "  image: ${pinned}"

# ── Pin Flutter in pubspec.yaml so CI installs the same version ──────────────
pubspec="$(dirname "$compose")/pubspec.yaml"
pinned_pubspec=0
if [[ "$pin_flutter" -eq 1 && -n "$flutter_version" && -f "$pubspec" ]] && grep -q '^environment:' "$pubspec"; then
  tmp="$(mktemp)"
  # Put `flutter:` first under `environment:` and drop any previous value.
  awk -v v="$flutter_version" '
    /^environment:/ { print; print "  flutter: " v; in_env = 1; next }
    in_env && /^[[:space:]]+flutter:/ { next }
    in_env && /^[^[:space:]#]/ { in_env = 0 }
    { print }
  ' "$pubspec" > "$tmp"
  cat "$tmp" > "$pubspec"
  rm -f "$tmp"
  pinned_pubspec=1
  echo "Pinned Flutter for CI:"
  echo "  pubspec.yaml  environment: flutter: ${flutter_version}"
  # Refresh pubspec.lock so its SDK section matches (CI uses --enforce-lockfile).
  flutter pub get >/dev/null || echo "flutter pub get failed — run it yourself to refresh pubspec.lock." >&2
fi

echo ""
echo "Next steps:"
if [[ "$pinned_pubspec" -eq 1 ]]; then
  echo "  - Commit docker-compose.yml, pubspec.yaml and pubspec.lock."
else
  echo "  - Commit docker-compose.yml. After 'flutter create', run this script again to pin Flutter"
  echo "    in pubspec.yaml too (CI installs the version pinned there)."
fi
echo "  - Rebuild the container (Dev Containers: Rebuild Container) to use the pinned image."
echo "  - Uncomment the pub and docker-compose blocks in .github/dependabot.yml so updates"
echo "    arrive as reviewed pull requests."
