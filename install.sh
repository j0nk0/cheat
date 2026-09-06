#!/usr/bin/env bash

set -eu

PREFIX="${PREFIX:-/usr/local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -d \
    "$PREFIX/bin" \
    "$PREFIX/lib/cheat" \
    "$PREFIX/share/cheat/cheatsheets" \
    "$PREFIX/share/doc/cheat"

install -m 755 \
    "$SCRIPT_DIR/bin/cheat" \
    "$PREFIX/bin/cheat"

install -m 755 \
    "$SCRIPT_DIR/bin/cheat.sh" \
    "$PREFIX/lib/cheat/cheat.sh"

install -m 644 \
    "$SCRIPT_DIR/lib/utils.sh" \
    "$SCRIPT_DIR/lib/sheets.sh" \
    "$SCRIPT_DIR/lib/sheet.sh" \
    "$PREFIX/lib/cheat/"

install -m 644 \
    "$SCRIPT_DIR/LICENSE" \
    "$SCRIPT_DIR/licenses/mit.txt" \
    "$SCRIPT_DIR/licenses/gpl-3.txt" \
    "$PREFIX/share/doc/cheat/"

cp -R "$SCRIPT_DIR/cheat/cheatsheets/." \
    "$PREFIX/share/cheat/cheatsheets/"

printf 'Installed cheat to %s/bin/cheat\n' "$PREFIX"