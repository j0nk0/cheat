#!/usr/bin/env bash

# Individual cheatsheet operations.

sheet_path() {
    local sheet="$1"

    sheet_validate_name "$sheet"

    sheets_path "$sheet" ||
        die "No cheatsheet found for $sheet"
}

sheet_validate_name() {
    local sheet="$1"

    case "$sheet" in
        ""|.|..|/*|*/|./*|*/./*|*/.|../*|*/../*|*//*)
            die "Invalid cheatsheet name: $sheet"
            ;;
    esac
}

sheet_exists() {
    sheets_exists "$1"
}

sheet_exists_in_default() {
    sheets_exists_in_default "$1"
}

sheet_is_writable() {
    local path

    path="$(sheet_path "$1")" || return 1

    [[ -w "$path" ]]
}

sheet_read() {
    local sheet="$1"
    local path

    path="$(sheet_path "$sheet")" ||
        die "No cheatsheet found for $sheet"

    cat "$path"
}

sheet_copy() {
    local current="$1"
    local destination="$2"

    mkdir -p "$(dirname "$destination")" ||
        die "Could not create directory for cheatsheet."

    if ! cp "$current" "$destination"; then
        die "Could not copy cheatsheet for editing."
    fi
}

sheet_create() {
    local sheet="$1"
    local default
    local destination

    default="$(sheets_default_path)"
    destination="$default/$sheet"

    mkdir -p "$(dirname "$destination")" ||
        die "Could not create directory for cheatsheet."

    open_with_editor "$destination"
}

sheet_edit() {
    local sheet="$1"
    local path

    path="$(sheet_path "$sheet")"

    open_with_editor "$path"
}

sheet_create_or_edit() {
    local sheet="$1"

    sheet_validate_name "$sheet"

    # Existing sheet?
    if ! sheet_exists "$sheet"; then
        sheet_create "$sheet"
        return
    fi

    # Existing sheet, but not in DEFAULT_CHEAT_DIR?
    if ! sheet_exists_in_default "$sheet"; then
        local current
        local default
        local destination

        current="$(sheet_path "$sheet")"
        default="$(sheets_default_path)"
        destination="$default/$sheet"

        sheet_copy "$current" "$destination"
        open_with_editor "$destination"
        return
    fi

    # Existing sheet in default directory.
    sheet_edit "$sheet"
}
