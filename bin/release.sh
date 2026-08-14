#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

ERLC=${ERLC:-erlc}
ERL=${ERL:-erl}

if ! command -v "$ERLC" >/dev/null 2>&1; then
  echo "Error: erlc is not installed or not on PATH." >&2
  exit 1
fi

if ! command -v "$ERL" >/dev/null 2>&1; then
  echo "Error: erl is not installed or not on PATH." >&2
  exit 1
fi

BUILD_DIR=ebin

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Compiling Erlang modules..."
$ERLC -o "$BUILD_DIR" -I include src/*.erl

echo "Copying app resource file..."
cp src/chat_server.app.src "$BUILD_DIR/chat_server.app"

echo "Build artifacts are in $BUILD_DIR"
