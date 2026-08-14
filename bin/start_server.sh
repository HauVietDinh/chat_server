#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

ERL=${ERL:-erl}
NAME=${NAME:-server}
NODE_NAME="${NAME}@$(hostname -f)"
NODE_FILE="server.node"

if ! command -v "$ERL" >/dev/null 2>&1; then
  echo "Error: erl is not installed or not on PATH." >&2
  exit 1
fi

# Start the server node in detached mode and write the node name into server.node
cat > "$NODE_FILE" <<EOF
$NODE_NAME
EOF

echo "Starting chat server on node $NODE_NAME"

exec "$ERL" -name "$NODE_NAME" -pa ebin -eval 'application:start(chat_server).'
