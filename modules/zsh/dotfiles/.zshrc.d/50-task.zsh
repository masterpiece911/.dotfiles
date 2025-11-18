if (( $+commands[task] )); then
  eval "$(task --completion zsh)"
fi
