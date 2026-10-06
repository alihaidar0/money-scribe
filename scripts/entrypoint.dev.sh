#!/usr/bin/env bash
set -euo pipefail

# ── Helper: run a command as-is, fall back to non-interactive sudo, else warn ──
# Bind-mounted folders from a Windows host are frequently owned by root inside
# the container (Docker Desktop does not remap ownership for Windows binds). A
# plain `chmod` as the non-root `developer` user then fails with "Operation not
# permitted". Try the fix, escalate via `sudo -n` (no password prompt, so it
# cannot hang container start), and if even that fails, warn and continue
# rather than kill the container over a permissions cosmetic issue.
run_or_warn() {
  local description="$1"
  shift
  if "$@" 2>/dev/null; then
    return 0
  fi
  if sudo -n "$@" 2>/dev/null; then
    return 0
  fi
  echo "⚠️  Warning: could not fix $description (insufficient permissions, and no passwordless sudo available). Continuing anyway." >&2
  return 0
}

# ── node_modules volume ownership ─────────────────────────────────────────────
# Docker creates a new named volume's mount point owned by root, so `pnpm
# install` as `developer` would fail with EACCES. Only the (empty) mount point
# needs fixing, and only once.
NODE_MODULES="/workspace/node_modules"
if [[ -d "$NODE_MODULES" ]] && [[ "$(stat -c '%U' "$NODE_MODULES")" != "developer" ]]; then
  run_or_warn "ownership of $NODE_MODULES" chown developer:developer "$NODE_MODULES"
fi

# ── Husky hook permissions ────────────────────────────────────────────────────
# Windows NTFS strips the execute bit from shell scripts. Without it, git
# refuses to run the hook and silently skips commit-msg / pre-commit / pre-push
# enforcement.
HUSKY_DIR="/workspace/.husky"
if [[ -d "$HUSKY_DIR" ]]; then
  run_or_warn "Husky hook execute permissions" find "$HUSKY_DIR" -type f ! -name "*.md" -exec chmod +x {} +
fi

# ── Entrypoint dispatch ───────────────────────────────────────────────────────
# With arguments (e.g. from docker run), exec them directly. Without (Dev
# Containers mode), keep the container alive.
if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec sleep infinity
fi
