#!/usr/bin/env bash

set -u

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cheat-tests.XXXXXX")" || exit 1

cleanup() {
    rm -rf "$TEST_TMP"
}

trap cleanup EXIT

source "$TEST_ROOT/lib/utils.sh"
source "$TEST_ROOT/lib/sheets.sh"
source "$TEST_ROOT/lib/sheet.sh"

failures=0

assert_equal() {
    local expected="$1"
    local actual="$2"
    local description="$3"

    if [[ "$expected" != "$actual" ]]; then
        printf 'FAIL: %s\nexpected: %s\nactual: %s\n' \
            "$description" "$expected" "$actual" >&2
        failures=$((failures + 1))
    fi
}

default_dir="$TEST_TMP/default"
bundled_dir="$TEST_TMP/bundled"
community_dir="$TEST_TMP/community"
work_dir="$TEST_TMP/work"

mkdir -p "$default_dir" "$bundled_dir" "$community_dir" "$work_dir/docker"
printf 'default\n' > "$default_dir/duplicate"
printf 'bundled\n' > "$bundled_dir/duplicate"
printf 'community\n' > "$community_dir/duplicate"
printf 'network\n' > "$work_dir/docker/network"
printf 'ssh user@example.com\n' > "$default_dir/ssh"

export DEFAULT_CHEAT_DIR="$default_dir"
export CHEAT_BUNDLED_DIR="$bundled_dir"
export CHEATPATH="$community_dir:$work_dir"

assert_equal "$community_dir/duplicate" "$(sheets_path duplicate)" \
    'last CHEATPATH entry wins over earlier paths'
assert_equal "$work_dir/docker/network" "$(sheets_path docker/network)" \
    'nested sheets are discovered'
assert_equal 'network' "$(sheet_read docker/network)" \
    'nested sheets can be read'
assert_equal "$default_dir/ssh" "$(sheets_path ssh)" \
    'default sheets are available when not overridden'

if ! sheets_list | grep -q '^docker/network'; then
    printf 'FAIL: nested sheets must appear in listings\n' >&2
    failures=$((failures + 1))
fi

if ! sheets_search ssh | grep -q '^ssh:'; then
    printf 'FAIL: matching sheets must appear in search results\n' >&2
    failures=$((failures + 1))
fi

copy_target="$default_dir/copied/duplicate"
sheet_copy "$community_dir/duplicate" "$copy_target"
assert_equal 'community' "$(cat "$copy_target")" \
    'a secondary-path sheet can be copied to the default directory'

if (sheet_validate_name ../outside) 2>/dev/null; then
    printf 'FAIL: traversal names must be rejected\n' >&2
    failures=$((failures + 1))
fi

if (( failures > 0 )); then
    printf '%d test(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'All tests passed\n'