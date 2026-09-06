#!/usr/bin/env bash

# Utility functions for cheat.

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

warn() {
    printf '%s\n' "$*" >&2
}

editor() {
    if [[ -n "${CHEAT_EDITOR:-}" ]]; then
        printf '%s\n' "$CHEAT_EDITOR"
    elif [[ -n "${VISUAL:-}" ]]; then
        printf '%s\n' "$VISUAL"
    elif [[ -n "${EDITOR:-}" ]]; then
        printf '%s\n' "$EDITOR"
    else
        die \
            'You must set a CHEAT_EDITOR, VISUAL, or EDITOR environment ' \
            'variable in order to create/edit a cheatsheet.'
    fi
}

open_with_editor() {
    local filepath="$1"
    local editor_cmd

    editor_cmd="$(editor)"

    # Use bash's word splitting intentionally, matching the old Python
    # implementation's editor().split() behavior.
    read -r -a editor_args <<< "$editor_cmd"

    if ! "${editor_args[@]}" "$filepath"; then
        die "Could not launch $editor_cmd"
    fi
}

colorize() {
    local content="$1"

    # CHEATCOLORS is simply presence-based in the original implementation.
    if [[ -z "${CHEATCOLORS+x}" ]]; then
        printf '%s\n' "$content"
        return
    fi

    # Pygments is optional in the original implementation. If it isn't
    # installed, simply return the uncolored content.
    if ! command -v pygmentize >/dev/null 2>&1; then
        printf '%s\n' "$content"
        return
    fi

    local first_line
    first_line="$(printf '%s\n' "$content" | head -n 1)"

    local lexer="bash"
    local input="$content"

    # Original Python implementation:
    #
    # if first_line.startswith('```'):
    #     sheet_content = '\n'.join(sheet_content.split('\n')[1:-2])
    #     lexer = get_lexer_by_name(first_line[3:])
    #
    # Preserve that behavior.
    if [[ "$first_line" == '```'* ]]; then
        lexer="${first_line:3}"

        # Remove first and last two lines.
        input="$(printf '%s\n' "$content" | sed '1d' | sed '$d' | sed '$d')"

        # pygmentize uses lexer aliases accepted by Pygments.
        if ! pygmentize -l "$lexer" -f terminal <<< "$input" 2>/dev/null; then
            # Unknown lexer: original code falls back to the default
            # bash lexer.
            printf '%s\n' "$input" |
                pygmentize -l bash -f terminal 2>/dev/null ||
                printf '%s\n' "$input"
        fi
        return
    fi

    printf '%s\n' "$input" |
        pygmentize -l "$lexer" -f terminal 2>/dev/null ||
        printf '%s\n' "$input"
}
