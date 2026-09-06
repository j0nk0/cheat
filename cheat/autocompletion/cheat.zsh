#compdef cheat

declare -a cheats
cheats=($(cheat -l | awk '{print $1}'))
_arguments "1:cheats:(${cheats})" && return 0
