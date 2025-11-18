[[ $- != *i* ]] && return
[[ -n "$_OMZ_LOADED" ]] && return
typeset -g _OMZ_LOADED=1

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
ZSH_THEME=""
plugins=(nvm git)
source "$ZSH/oh-my-zsh.sh"
