#!/bin/zsh

# Replace ls globally
alias ls='eza --group-directories-first --icons --git'

# Long list, all files
alias ll='eza -al --group-directories-first --icons --git'

# Almost all files (hidden but no . or ..)
alias la='eza -a --group-directories-first --icons --git'

# Simple list with classification
alias l='eza -F --group-directories-first --icons --git'

