if [[ "$XDG_SESSION_TYPE" != wayland && -z "$WAYLAND_DISPLAY" && -n "$DISPLAY" ]] && (( $+commands[setxkbmap] )); then
  setxkbmap -layout us,de,tr -option grp:alt_shift_toggle
fi
