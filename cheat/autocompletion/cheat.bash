function _cheat_autocomplete {
    local sheets

    sheets=$(cheat -l | awk '{print $1}')
    COMPREPLY=()
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$sheets" -- "${COMP_WORDS[1]}"))
    fi
}

complete -F _cheat_autocomplete cheat
