#!/bin/sh
# Starts the Piper open-voice worker detached (survives the terminal).
# Caches WAVs under the server's ignored .serverpod dir (never committed).
# Usage: sh scripts/piper_tts.sh  —  then restart `serverpod start`.
set -e
cd "$(dirname "$0")/.."
CACHE_DIR="$PWD/.serverpod/tts-cache"
mkdir -p "$CACHE_DIR"
if command -v lsof >/dev/null 2>&1 && lsof -ti :8131 >/dev/null 2>&1; then
  echo "Piper worker already running on :8131"
  exit 0
fi
NOhup_LOG="$CACHE_DIR/worker.log"
TTS_CACHE_DIR="$CACHE_DIR" \
  "$HOME/.talkloom/piper-env/bin/python" \
  scripts/piper_tts_worker.py >"$NOhup_LOG" 2>&1 &
echo "Piper worker started (log: $NOhup_LOG)"
