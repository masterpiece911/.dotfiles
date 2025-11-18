# ~/.zshrc executed by zsh for non-interactive shells.

# Interactive only
[[ $- != *i* ]] && return

if [ -d ~/.zshrc.d ]; then
  for rc in ~/.zshrc.d/*.zsh(Nn); do
    . "$rc"
  done
fi
unset rc
