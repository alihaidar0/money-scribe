#!/usr/bin/env bash
# Pins the backend's API contract in this project and regenerates the client.
#
# The backend publishes its API as one OpenAPI file. Every backend release
# (vX.Y.Z) carries it as the release asset `openapi.yaml`, and a release never
# changes afterwards, so a tag is a safe thing to pin. This script:
#   1. downloads that asset with the GitHub CLI into api/openapi.yaml,
#   2. checks it against the release attestation when the backend uses
#      immutable releases (`gh release verify-asset`),
#   3. records what you pinned in api/BACKEND_VERSION,
#   4. runs scripts/generate-api.sh to regenerate lib/core/api.
# Nothing is written until the download succeeds, so a failed run never leaves
# the contract and its version note out of step. Review and commit api/ and
# lib/core/api in one pull request. A token is never printed or stored.
#
# Usage:
#   scripts/sync-api.sh vX.Y.Z [options]
#   scripts/sync-api.sh --commit <sha> [options]   (before the backend's first release)
#
# Options:
#   --commit <sha>      pin openapi/schema.yaml as it is at that backend commit
#   --no-generate       pin the contract only; skip the client generation
#   --require-verified  fail unless the release attestation verifies (default:
#                       warn, because only immutable releases carry one)
#   -h, --help          show this help
#
# Setup: api/BACKEND_REPO holds one line, OWNER/REPO, of the backend repository.
# A private backend needs `gh auth login` (or GH_TOKEN in the environment) with
# read access to it.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  sed -n '/^# Usage:/,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d;s/^# \{0,1\}//'
}

# ── Arguments ───────────────────────────────────────────────────────────────
tag=""
commit=""
generate=1
require_verified=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      [[ $# -ge 2 ]] || fail "--commit needs a commit SHA."
      commit="$2"
      shift
      ;;
    --no-generate) generate=0 ;;
    --require-verified) require_verified=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) fail "Unknown option: $1 (see --help)." ;;
    *)
      [[ -z "$tag" ]] || fail "Only one release tag is allowed (got '$tag' and '$1')."
      tag="$1"
      ;;
  esac
  shift
done

if [[ -n "$tag" && -n "$commit" ]]; then
  fail "Give either a release tag or --commit, not both."
fi
if [[ -z "$tag" && -z "$commit" ]]; then
  usage >&2
  exit 2
fi
if [[ -n "$tag" && ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  fail "'$tag' is not a release tag such as v1.4.0."
fi
if [[ -n "$commit" && ! "$commit" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
  fail "'$commit' is not a commit SHA (7 to 40 hex characters)."
fi

# ── Backend repository and GitHub CLI ───────────────────────────────────────
[[ -f api/BACKEND_REPO ]] \
  || fail "api/BACKEND_REPO not found. Create it with one line, OWNER/REPO of the backend:
  mkdir -p api && echo 'your-account/your-backend' > api/BACKEND_REPO"

# First line that is neither empty nor a comment.
repo="$(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' api/BACKEND_REPO | head -n 1 | tr -d '[:space:]')"
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] \
  || fail "api/BACKEND_REPO must contain one line, OWNER/REPO (found '${repo:-nothing}')."

command -v gh >/dev/null 2>&1 \
  || fail "The GitHub CLI (gh) is not installed. It is part of the dev container."
gh auth status --hostname github.com >/dev/null 2>&1 \
  || fail "gh is not signed in to github.com. Run 'gh auth login' (required for a private
backend repository), or provide GH_TOKEN in the environment."

# ── Download into a scratch directory ───────────────────────────────────────
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
contract="$scratch/openapi.yaml"

if [[ -n "$tag" ]]; then
  version="$tag"
  echo "Downloading openapi.yaml of $repo $tag ..."
  gh release download "$tag" --repo "$repo" --pattern openapi.yaml --dir "$scratch" --clobber \
    || fail "Could not download openapi.yaml from release $tag of $repo.
Check the tag, that the release has an openapi.yaml asset, and that your account can read $repo."

  # Immutable releases carry a signed attestation, which proves the file is the
  # one the release was published with. Older gh versions and releases that are
  # not immutable cannot be verified; that is reported, not hidden.
  verified=0
  if gh release verify-asset --help >/dev/null 2>&1; then
    if gh release verify-asset "$tag" "$contract" --repo "$repo" >/dev/null 2>&1; then
      verified=1
      echo "Verified: openapi.yaml matches the attestation of release $tag."
    fi
  fi
  if [[ "$verified" -eq 0 ]]; then
    if [[ "$require_verified" -eq 1 ]]; then
      fail "Could not verify openapi.yaml against the attestation of release $tag.
Immutable releases must be enabled in the backend repository, and gh must be recent (2.81 or newer)."
    fi
    echo "Warning: openapi.yaml was not verified against a release attestation (the release is" >&2
    echo "         not immutable, or gh is older than 2.81). Use --require-verified to make this an error." >&2
  fi
else
  # A short SHA is resolved first, so api/BACKEND_VERSION always holds the full one.
  version="$(gh api "repos/$repo/commits/$commit" --jq .sha)" \
    || fail "Could not resolve commit $commit in $repo. Check the SHA and your access."
  echo "Downloading openapi/schema.yaml of $repo at ${version:0:12} ..."
  gh api -H "Accept: application/vnd.github.raw+json" \
    "repos/$repo/contents/openapi/schema.yaml?ref=$version" >"$contract" \
    || fail "Could not read openapi/schema.yaml at commit $version of $repo."
fi

# A login page, an error body or an empty file must never become the contract.
[[ -s "$contract" ]] || fail "The downloaded contract is empty."
grep -Eq '^openapi:[[:space:]]*["'"'"']?3\.' "$contract" \
  || fail "The downloaded file is not an OpenAPI 3 document (no top-level 'openapi: 3.x')."

# ── Pin ─────────────────────────────────────────────────────────────────────
mkdir -p api
cp "$contract" api/openapi.yaml
printf '%s\n' "$version" >api/BACKEND_VERSION
echo "Pinned $repo $version in api/openapi.yaml (api/BACKEND_VERSION updated)."

# ── Generate ────────────────────────────────────────────────────────────────
if [[ "$generate" -eq 0 ]]; then
  echo "Skipped the client generation (--no-generate). Run scripts/generate-api.sh when ready."
else
  bash scripts/generate-api.sh
fi

echo ""
echo "Next: review the diff of api/ and lib/core/api, then commit them in one pull request."
