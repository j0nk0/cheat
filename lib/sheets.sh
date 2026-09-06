#!/usr/bin/env bash

# Sheet/path management for cheat.

# Return the default cheatsheet directory.
#
# Original behavior:
#   DEFAULT_CHEAT_DIR
#   otherwise ~/.cheat
#
sheets_default_path() {
    local path="${DEFAULT_CHEAT_DIR:-$HOME/.cheat}"

    # Expand leading ~.
    if [[ "$path" == "~" ]]; then
        path="$HOME"
    elif [[ "$path" == "~/"* ]]; then
        path="$HOME/${path:2}"
    fi

    if [[ ! -d "$path" ]]; then
        if ! mkdir -p "$path"; then
            die "Could not create DEFAULT_CHEAT_DIR"
        fi
    fi

    [[ -r "$path" ]] ||
        die "The DEFAULT_CHEAT_DIR ($path) is not readable."

    [[ -w "$path" ]] ||
        die "The DEFAULT_CHEAT_DIR ($path) is not writable."

    printf '%s\n' "$path"
}

# Locate the bundled cheatsheets.
#
# If the installation looks like:
#
#   /usr/local/lib/cheat/cheatsheets
#
# use that directory.
#
# CHEAT_BUNDLED_DIR can override it.
sheets_bundled_path() {
    if [[ -n "${CHEAT_BUNDLED_DIR:-}" ]]; then
        printf '%s\n' "$CHEAT_BUNDLED_DIR"
        return
    fi

    # Resolve bundled sheets from both the repository and a conventional
    # installed layout.
    local lib_dir
    lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local candidate
    for candidate in \
        "$lib_dir/../cheat/cheatsheets" \
        "$lib_dir/../cheatsheets" \
        "$lib_dir/../../share/cheat/cheatsheets"; do
        if [[ -d "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done

    # No bundled sheets.
    printf '%s\n' ''
}

# Print all configured cheat directories.
#
# This preserves the original order:
#
#   default
#   bundled
#   CHEATPATH entries
#
sheets_paths() {
    local default
    default="$(sheets_default_path)"
    printf '%s\n' "$default"

    local bundled
    bundled="$(sheets_bundled_path)"

    if [[ -n "$bundled" && -d "$bundled" ]]; then
        printf '%s\n' "$bundled"
    fi

    if [[ -n "${CHEATPATH:-}" ]]; then
        local old_ifs="$IFS"
        IFS=':'

        local path
        for path in $CHEATPATH; do
            [[ -d "$path" ]] || continue
            printf '%s\n' "$path"
        done

        IFS="$old_ifs"
    fi
}

# Find all sheets under one cheatpath.
#
# Unlike the original Python 2.2.3 implementation, this recursively
# discovers nested sheets:
#
#   ~/.cheat/git
#   ~/.cheat/docker/network
#   ~/.cheat/kubernetes/pods
#
# The output is:
#
#   relative-name<TAB>absolute-path
#
sheets_find_in_path() {
    local base="$1"

    [[ -d "$base" ]] || return 0

    find "$base" \
        -type d \( \
            -name .git -o \
            -name .svn -o \
            -name __pycache__ \
        \) -prune -o \
        -type f \
        ! -name '.*' \
        -print0 |
    while IFS= read -r -d '' file; do
        local relative="${file#"$base"/}"

        # Preserve the old behavior of ignoring names beginning with
        # "__" at the top level, while allowing nested directories.
        case "$relative" in
            __*|*/__*)
                continue
                ;;
        esac

        printf '%s\t%s\n' "$relative" "$file"
    done
}

# Produce the effective sheet map.
#
# Later paths override earlier paths.
#
# This mirrors:
#
#   for cheat_dir in reversed(paths()):
#       cheats.update(...)
#
sheets_map() {
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/cheat-map.XXXXXX")" ||
        die "Could not create temporary file."

    trap 'rm -f "$tmp"' RETURN

    local path
    local relative
    local file
    local existing_name
    local already_mapped

    # Reverse path order so that the first path written wins.
    local -a path_array=()
    while IFS= read -r path; do
        path_array+=("$path")
    done < <(sheets_paths)

    local i
    for ((i=${#path_array[@]}-1; i>=0; i--)); do
        path="${path_array[$i]}"

        while IFS=$'\t' read -r relative file; do
            [[ -n "$relative" ]] || continue

            # Only write if not already present. Since we walk in reverse,
            # this makes later CHEATPATH entries take precedence.
            already_mapped=0
            while IFS=$'\t' read -r existing_name _; do
                if [[ "$existing_name" == "$relative" ]]; then
                    already_mapped=1
                    break
                fi
            done < "$tmp"

            if (( already_mapped == 0 )); then
                printf '%s\t%s\t%s\n' \
                    "$relative" \
                    "$file" \
                    "$path" >> "$tmp"
            fi
        done < <(sheets_find_in_path "$path")
    done

    cat "$tmp"
}

# Find a sheet by name.
#
# Prints its path.
sheets_path() {
    local wanted="$1"

    local name
    local file
    local path

    while IFS=$'\t' read -r name file path; do
        if [[ "$name" == "$wanted" ]]; then
            printf '%s\n' "$file"
            return 0
        fi
    done < <(sheets_map)

    return 1
}

# Return true if a sheet exists.
sheets_exists() {
    local sheet="$1"
    local path

    path="$(sheets_path "$sheet")" || return 1

    [[ -r "$path" ]]
}

# Return true if a sheet exists in the default path.
sheets_exists_in_default() {
    local sheet="$1"
    local default
    local file

    default="$(sheets_default_path)"
    file="$default/$sheet"

    [[ -r "$file" ]]
}

# List sheets in the same format as the original implementation:
#
#   name    /path/to/file
#
sheets_list() {
    local rows=()
    local name
    local file
    local path

    while IFS=$'\t' read -r name file path; do
        rows+=("$name"$'\t'"$file")
    done < <(sheets_map)

    if (( ${#rows[@]} == 0 )); then
        return 0
    fi

    local max=0
    local row
    local n

    for row in "${rows[@]}"; do
        name="${row%%$'\t'*}"
        n=${#name}

        (( n > max )) && max=$n
    done

    local padding=$((max + 4))

    printf '%s\n' "${rows[@]}" |
    while IFS=$'\t' read -r name file; do
        printf "%-${padding}s%s\n" "$name" "$file"
    done |
    sort
}

# Search all sheets.
#
# Original behavior is a literal substring search, not regex matching.
# Each matching line receives two spaces of indentation.
sheets_search() {
    local term="$1"

    local name
    local file
    local path

    while IFS=$'\t' read -r name file path; do
        local matches=""

        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *"$term"* ]]; then
                matches+="  $line"$'\n'
            fi
        done < "$file"

        if [[ -n "$matches" ]]; then
            printf '%s:\n' "$name"
            printf '%s\n' "$matches"
        fi
    done < <(
        sheets_map |
            sort -t $'\t' -k1,1
    )
}
