#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

ERL=${ERL:-erl}

usage() {
    echo "Usage: $0 <user_name> [<room_id>]"
    echo
    echo "Start a chat user."
    echo
    echo "Arguments:"
    echo "  user_name    Name of the user"
    echo "  room_id      Optional room ID to join"
    echo
    echo "Options:"
    echo "  -h, --help   Show this help message"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
fi

USER_NAME=$1
NODE_NAME="${USER_NAME}@$(hostname -f)"

if ! command -v "$ERL" >/dev/null 2>&1; then
    echo "Error: erl is not installed or not on PATH." >&2
    exit 1
fi

echo "Starting chat user: $USER_NAME"
EVAL="chat_user_sup:start_link(\"$USER_NAME\")."
exec "$ERL" -name "$NODE_NAME" -pa ebin \
    -eval "$EVAL"
