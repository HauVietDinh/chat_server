#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

./bin/release.sh

erlc -o ebin -I include test/*.erl

erl -sname test -pa ebin -eval 'eunit:test([chat_room_tests, chat_user_tests], [verbose]), init:stop().'
