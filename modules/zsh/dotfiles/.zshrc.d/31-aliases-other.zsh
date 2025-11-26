# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias clipboard='xclip -sel clip -rmlastnl'

alias ua='~/projects/tools/ua-expert/uaexpert-bin-linux-x86_64-1.6.3-448.AppImage'

