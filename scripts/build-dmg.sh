#!/bin/bash
# build-dmg.sh — builds a custom, styled DMG for Graveyard Slide.
#
# Uses dmgbuild's Python library interface (dmgbuild.build_dmg) rather
# than its CLI, since the CLI was confirmed to silently fail to apply
# the background image even though it copied the file correctly.
#
# dmgbuild requires Python >=3.10 for the bug-fixed releases (>=1.6.6);
# Python 3.9 caps it at 1.6.5, which has a confirmed bug where the
# background image doesn't get linked into the Finder window correctly.
#
# Python interpreter resolution, in order of preference:
#   1. $PYTHON_BIN if explicitly set (e.g. by CI)
#   2. Homebrew's python3.12, if present (local Mac dev)
#   3. plain `python3` on PATH (CI runners, which ship modern Python)
#
# On a local Mac, Homebrew's Python is "externally managed" (PEP 668)
# and refuses bare `pip install`, so we use a dedicated venv there. CI
# runners' python3 is not externally managed this way, so we install
# directly without a venv when running there (detected via $CI).
#
# Usage: run this AFTER `npm run tauri build -- --bundles app`
# (i.e. Tauri builds only the .app bundle; this script wraps it in a DMG)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$PROJECT_ROOT/src-tauri/target/release/bundle/macos/Graveyard Slide.app"
BACKGROUND_PATH="$PROJECT_ROOT/src-tauri/dmg-images/background.png"
MAKE_DMG_SCRIPT="$PROJECT_ROOT/src-tauri/dmg-images/make_dmg.py"
VENV_DIR="$PROJECT_ROOT/.dmg-venv"

# Pull version from tauri.conf.json so the output filename matches Tauri's convention
VERSION=$(grep '"version"' "$PROJECT_ROOT/src-tauri/tauri.conf.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')
ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/arm64/aarch64/')

OUTPUT_DIR="$PROJECT_ROOT/src-tauri/target/release/bundle/dmg"
OUTPUT_DMG="$OUTPUT_DIR/Graveyard Slide_${VERSION}_${ARCH}.dmg"

mkdir -p "$OUTPUT_DIR"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: app bundle not found at: $APP_PATH"
  echo "Run 'npm run tauri build -- --bundles app' first."
  exit 1
fi

if [ ! -f "$BACKGROUND_PATH" ]; then
  echo "Error: background image not found at: $BACKGROUND_PATH"
  exit 1
fi

if [ -n "${CI:-}" ]; then
  # Running in CI (e.g. GitHub Actions): use python3 directly, no venv.
  # The workflow is expected to have already run `python3 -m pip install dmgbuild`.
  RUN_PYTHON="python3"
else
  # Running locally on a Mac: use Homebrew's Python 3.12 in a dedicated venv.
  SYSTEM_PYTHON="/opt/homebrew/opt/python@3.12/bin/python3.12"

  if [ ! -x "$SYSTEM_PYTHON" ]; then
    echo "Error: Python 3.12 not found at $SYSTEM_PYTHON"
    echo "Install it with: brew install python@3.12"
    exit 1
  fi

  if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment for dmgbuild..."
    "$SYSTEM_PYTHON" -m venv "$VENV_DIR"
  fi

  RUN_PYTHON="$VENV_DIR/bin/python3"

  # Ensure dmgbuild is installed inside the venv (no-op if already present)
  "$RUN_PYTHON" -m pip show dmgbuild >/dev/null 2>&1 || "$RUN_PYTHON" -m pip install --quiet dmgbuild
fi

echo "Building styled DMG with dmgbuild..."
"$RUN_PYTHON" "$MAKE_DMG_SCRIPT" "$APP_PATH" "$OUTPUT_DMG"

echo "Done. DMG created at:"
echo "$OUTPUT_DMG"
