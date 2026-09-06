#completion for cheat
complete -c cheat -s h -l help -f -x --description "Display help and exit"
complete -c cheat -l edit -f -x --description "Edit <cheatsheet>"
complete -c cheat -s e -f -x --description "Edit <cheatsheet>"
complete -c cheat -s l -l list -f -x --description "List all available cheatsheets"
complete -c cheat -s d -l directories -f -x --description "List all current cheat dirs"
complete -c cheat -s s -l search -f -x --description "Search cheatsheets"
complete -c cheat -s v -l version -f --description "Print the version number"
complete -c cheat --authoritative -f
for cheatsheet in (cheat -l | awk '{print $1}')
    complete -c cheat -a "$cheatsheet"
    complete -c cheat -o e -a "$cheatsheet" 
    complete -c cheat -o '-edit' -a "$cheatsheet"
end
