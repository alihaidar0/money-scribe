#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=/workspace

# Auto-create .env from .env.example on first run
if [ ! -f "$WORKSPACE/.env" ] && [ -f "$WORKSPACE/.env.example" ]; then
  cp "$WORKSPACE/.env.example" "$WORKSPACE/.env"
fi

# ── SSH host alias and key ──────────────────────────────────────────────────
# Keys come from your host's ssh-agent (forwarded by VS Code) and ~/.ssh is not
# mounted. A host-only alias in the remote URL (for example
# git@github.com-work:owner/repo.git, defined in the host's ~/.ssh/config) would
# not resolve here, and with several accounts' keys in the agent GitHub would
# accept whichever key comes first. pin-ssh-key.sh maps the alias to github.com
# and pins this repository's key (public key + IdentitiesOnly).
# Non-fatal: it is a convenience and must never block container start.
bash "$WORKSPACE/scripts/pin-ssh-key.sh" || true

# ── Git hooks ───────────────────────────────────────────────────────────────
# postCreateCommand (`pnpm install`) registers the Husky hooks. Repeat it here
# when they are missing (an interrupted first start, a recreated node_modules
# volume), so the very first commit and push of a new project are already
# checked. Non-fatal: it must never block container start.
hooks_path="$(git -C "$WORKSPACE" config core.hooksPath 2>/dev/null || true)"
if [[ "$hooks_path" != ".husky/_" || ! -x "$WORKSPACE/node_modules/.bin/commitlint" ]]; then
  echo "  🪝  Installing the git hooks (pnpm install)..."
  (cd "$WORKSPACE" && pnpm install --frozen-lockfile >/dev/null 2>&1) \
    || echo "  ⚠️  Could not install the git hooks — run: pnpm install"
fi

# ── Auto-connect to host emulator ───────────────────────────────────────────
# If an emulator is already running on the host, connect to it now so
# `adb devices` / `flutter run` work without a manual step. The VS Code launch
# configurations run the same script again before every start, so an emulator
# started later is picked up too. Silent and non-fatal: it is a convenience and
# must never block container start.
ADB_PORTS=5555 bash "$WORKSPACE/scripts/connect-emulator.sh" --quiet || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🐦  flutter-template — dev container ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$WORKSPACE/pubspec.yaml" ] && [ -f "$WORKSPACE/pubspec.lock" ]; then
  # ── Tier 3: full project ────────────────────────────────────────────────────
  APP_NAME=$(grep '^name:' "$WORKSPACE/pubspec.yaml" | awk '{print $2}')
  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  echo ""
  echo "  ✅  Flutter project detected: ${APP_NAME}"
  echo "  🔧  Flutter ${FLUTTER_VER} · Dart · Android SDK · Web"
  echo ""
  echo "  ❯ F5            \"Flutter (Emulator + Browser)\" — host emulator and host browser"
  echo "  ❯ frunw         flutter run -d web-server (port 8080)"
  echo "  ❯ ftest         flutter test"
  echo "  ❯ fanalyze      flutter analyze"
  echo "  ❯ fdoctor       flutter doctor -v"
  echo ""
  echo "  ❯ Git aliases:  gs · ga · gc · gp · gl"
  echo "  📖  https://github.com/alihaidar0/flutter-template"

elif [ -f "$WORKSPACE/pubspec.yaml" ]; then
  # ── Tier 2: initialised but no lockfile ─────────────────────────────────────
  echo ""
  echo "  ✅  pubspec.yaml found — run flutter pub get to resolve dependencies"
  echo ""
  echo "  ┌─ Next step ──────────────────────────────────────────────────────┐"
  echo "  │  flutter pub get                                                 │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ❯ Git aliases:  gs · ga · gc · gp · gl"
  echo "  📖  https://github.com/alihaidar0/flutter-template"

else
  # ── Tier 1: fresh template ──────────────────────────────────────────────────
  echo ""
  echo "  👋  Fresh template — Flutter not yet initialised"
  echo ""
  echo "  ┌─ Step 1: Initialise Flutter project ─────────────────────────────┐"
  echo "  │  flutter create --org com.example .                              │"
  echo "  │  (replaces '.' with your own org and app name as needed)         │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ┌─ Step 2: Freeze the toolchain for this project ──────────────────┐"
  echo "  │  scripts/pin-image.sh                                            │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ┌─ Step 3: Write this app's README ────────────────────────────────┐"
  echo "  │  scripts/init-readme.sh --description \"What it does\"             │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  ┌─ Step 4: Start developing ───────────────────────────────────────┐"
  echo "  │  F5      → \"Flutter (Emulator + Browser)\" on your host           │"
  echo "  │  frunw   → run on web (port 8080)                                │"
  echo "  │  fdoctor → check environment                                     │"
  echo "  └──────────────────────────────────────────────────────────────────┘"
  echo ""
  echo "  📖  https://github.com/alihaidar0/flutter-template"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
