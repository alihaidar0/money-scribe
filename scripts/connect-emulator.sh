#!/usr/bin/env bash
# Connects the container's adb to an Android emulator running on the host.
#
# The container runs its OWN adb server and connects OUT to the emulator (see
# docker-compose.yml for why), so Flutter's VM Service forward stays inside the
# container and hot reload works. The emulator listens on 5555 (first one),
# 5557 (second) and so on.
#
# Used by welcome.sh (once, quietly, at container start) and by the VS Code
# task "Connect host emulator", which every Android launch configuration runs
# first, so pressing F5 works even when the emulator was started later.
#
# Usage: scripts/connect-emulator.sh [--quiet] [--wait SECONDS]
#   --quiet         print nothing and always exit 0 (container start must never fail)
#   --wait SECONDS  keep retrying for that long while the emulator boots
# Environment: ADB_HOST (default host.docker.internal), ADB_PORTS (default "5555 5557 5559")
set -euo pipefail

host="${ADB_HOST:-host.docker.internal}"
ports="${ADB_PORTS:-5555 5557 5559}"
quiet=0
wait_seconds=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) quiet=1 ;;
    --wait)
      wait_seconds="${2:-0}"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

say() { [[ "$quiet" -eq 1 ]] || echo "$@"; }

if ! command -v adb >/dev/null 2>&1; then
  say "adb is not installed in this environment."
  [[ "$quiet" -eq 1 ]] && exit 0
  exit 1
fi

# True when `adb devices` lists the target in the "device" (ready) state.
is_ready() {
  adb devices | awk -v target="$1" '$1 == target && $2 == "device" { found = 1 } END { exit !found }'
}

# One pass over every port; prints the targets that are ready.
connect_once() {
  local port target
  for port in $ports; do
    target="${host}:${port}"
    # `adb connect` can hang on an unreachable host, so bound it.
    timeout 3 adb connect "$target" >/dev/null 2>&1 || true
    if ! is_ready "$target"; then
      # A stale "offline" entry survives emulator restarts: reset it once.
      adb disconnect "$target" >/dev/null 2>&1 || true
      timeout 3 adb connect "$target" >/dev/null 2>&1 || true
    fi
    if is_ready "$target"; then
      echo "$target"
    fi
  done
}

deadline=$((SECONDS + wait_seconds))
while true; do
  ready="$(connect_once)"
  if [[ -n "$ready" ]]; then
    say "Connected to the host emulator: $(echo "$ready" | tr '\n' ' ')"
    exit 0
  fi
  if [[ "$SECONDS" -ge "$deadline" ]]; then
    break
  fi
  sleep 2
done

say "No host emulator found on ${host} (ports: ${ports})."
say "Start an emulator on the host (Android Studio → Device Manager, or 'emulator -avd <name>')."
say "If it is running, allow its adb port through the host firewall (README, section 8: Run on your host)."
[[ "$quiet" -eq 1 ]] && exit 0
exit 1
