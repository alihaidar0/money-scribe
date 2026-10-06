#!/usr/bin/env bash
# Compares this template with the contract of the flutter-devcontainer image,
# using the image repository's published sources (no image pull needed).
#
# Checked: the pnpm version Corepack must not download at start-up, the Node
# major, the image the compose file pulls, and that every shell alias the
# README documents exists in the image.
set -euo pipefail

base="${IMAGE_REPO_RAW:-https://raw.githubusercontent.com/alihaidar0/flutter-devcontainer/main}"
readme="README.md"
status=0
fail() { echo "::error::$*"; status=1; }

dockerfile="$(curl -fsSL --retry 3 "${base}/docker/Dockerfile.dev")"
aliases_script="$(curl -fsSL --retry 3 "${base}/scripts/shell_setup.sh")"

# ── pnpm ─────────────────────────────────────────────────────
image_pnpm="$(grep -oE 'PNPM_VERSION=[0-9][0-9.]*' <<< "${dockerfile}" | head -1 | cut -d= -f2)"
template_pnpm="$(jq -r '.packageManager // ""' package.json | sed -n 's/^pnpm@//p')"
[ -n "${image_pnpm}" ] || fail "Could not read PNPM_VERSION from the image's Dockerfile.dev."
if [ "${template_pnpm}" != "${image_pnpm}" ]; then
  fail "package.json packageManager is pnpm@${template_pnpm:-<none>} but the image caches pnpm ${image_pnpm}; Corepack would download it on first use."
fi

# ── Node ─────────────────────────────────────────────────────
image_node="$(grep -oE '^ARG NODE_VERSION=[0-9]+' <<< "${dockerfile}" | head -1 | cut -d= -f2)"
template_node="$(jq -r '.engines.node // ""' package.json | grep -oE '[0-9]+' | head -1 || true)"
[ -n "${image_node}" ] || fail "Could not read NODE_VERSION from the image's Dockerfile.dev."
if [ "${template_node}" != "${image_node}" ]; then
  fail "package.json engines.node starts at ${template_node:-<none>} but the image runs Node ${image_node}."
fi

# ── Image reference ──────────────────────────────────────────
# The compose file pulls alihaidar199527/flutter-devcontainer:<tag>, optionally
# followed by @sha256:<digest> once a project has run scripts/pin-image.sh.
grep -E '^[[:space:]]*image:' docker-compose.yml | grep -q 'alihaidar199527.*/flutter-devcontainer' \
  || fail "docker-compose.yml does not pull alihaidar199527/flutter-devcontainer."

# ── Aliases documented in the README must exist in the image ─
image_aliases="$(grep -oE '^alias [A-Za-z0-9_]+' <<< "${aliases_script}" | cut -d' ' -f2 | sort -u)"
readme_aliases="$(
  awk '
    /^#+ Shell Aliases/ { in_section = 1; next }
    /^#+ /              { in_section = 0 }
    in_section && /^\| `/ {
      split($0, cols, "|")
      gsub(/[ `]/, "", cols[2])
      print cols[2]
    }
  ' "${readme}" | sort -u
)"
[ -n "${readme_aliases}" ] || fail "No aliases found in the README 'Shell Aliases' table."
while IFS= read -r name; do
  [ -z "${name}" ] && continue
  grep -qxF -- "${name}" <<< "${image_aliases}" \
    || fail "Alias '${name}' is documented in the README but not defined by the image."
done <<< "${readme_aliases}"

if [ "${status}" -eq 0 ]; then
  echo "Template matches the flutter-devcontainer image contract (pnpm ${image_pnpm}, Node ${image_node})."
fi
exit "${status}"
