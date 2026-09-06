#!/usr/bin/env bash

set -u

CHEAT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$CHEAT_SCRIPT_DIR/utils.sh" ]]; then
  CHEAT_LIB_DIR="$CHEAT_SCRIPT_DIR"
else
  CHEAT_LIB_DIR="$(cd "$CHEAT_SCRIPT_DIR/../lib" && pwd)"
fi

# shellcheck source=/dev/null
source "$CHEAT_LIB_DIR/utils.sh"
source "$CHEAT_LIB_DIR/sheets.sh"
source "$CHEAT_LIB_DIR/sheet.sh"

VERSION="3.0.0"

usage() {
    cat <<'EOF'
cheat

Create and view cheatsheets on the command line.

Usage:
  cheat <cheatsheet>
  cheat -e <cheatsheet>
  cheat -s <keyword>
  cheat -l
  cheat -d
  cheat -v

Options:
  -d --directories  List directories on CHEATPATH
  -e --edit         Edit cheatsheet
  -l --list         List cheatsheets
  -s --search       Search cheatsheets for <keyword>
  -v --version      Print the version number
  -h --help         Show this help

Examples:

  To view the `tar` cheatsheet:
    cheat tar

  To edit (or create) the `foo` cheatsheet:
    cheat -e foo

  To list all available cheatsheets:
    cheat -l

  To search for "ssh" among all cheatsheets:
    cheat -s ssh
EOF
}

main() {
    case "${1:-}" in
        -d|--directories)
            [[ $# -eq 1 ]] || die "cheat: -d does not accept arguments"
            sheets_paths
            ;;

        -e|--edit)
            [[ $# -eq 2 ]] || die "cheat: -e requires exactly one cheatsheet"
            sheet_create_or_edit "$2"
            ;;

        -l|--list)
            [[ $# -eq 1 ]] || die "cheat: -l does not accept arguments"
            sheets_list
            ;;

        -s|--search)
            [[ $# -eq 2 ]] || die "cheat: -s requires exactly one keyword"
            colorize "$(sheets_search "$2")"
            ;;

        -v|--version)
            [[ $# -eq 1 ]] || die "cheat: -v does not accept arguments"
            printf 'cheat %s\n' "$VERSION"
            ;;

        -h|--help)
            [[ $# -eq 1 ]] || die "cheat: -h does not accept arguments"
            usage
            ;;

        "")
            usage >&2
            exit 2
            ;;

        -*)
            die "cheat: unknown option: $1"
            ;;

        *)
            [[ $# -eq 1 ]] || die "cheat: expected one cheatsheet"
            colorize "$(sheet_read "$1")"
            ;;
    esac
}

main "$@"
