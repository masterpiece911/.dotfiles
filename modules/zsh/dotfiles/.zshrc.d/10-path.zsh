# PATH setup (deduplicated)
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/bin" $path)
export PATH
