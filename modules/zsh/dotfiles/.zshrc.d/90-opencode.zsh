# opencode
export PATH=/home/masterpiece/.opencode/bin:$PATH

# Match Neovim: remove Kitty padding while running, then restore the default.
opencode() {
  if [[ -z "$KITTY_WINDOW_ID" || -z "$KITTY_LISTEN_ON" ]] || ! (( $+commands[kitten] )); then
    command opencode "$@"
    return $?
  fi

  local exit_code=0
  kitten @ --to "$KITTY_LISTEN_ON" set-spacing --match "id:$KITTY_WINDOW_ID" padding=0 >/dev/null 2>&1
  {
    command opencode "$@" || exit_code=$?
  } always {
    kitten @ --to "$KITTY_LISTEN_ON" set-spacing --match "id:$KITTY_WINDOW_ID" padding=default >/dev/null 2>&1
  }
  return "$exit_code"
}
