#!/bin/bash

r() {
	(cd ~/projects/race && poetry run race "$@")
}

alias ru='r up dev'
alias rd='r down'
alias rcli='r cli'
alias rupdate='(cd ~/projects/race && ./syncDevWithMc7.sh)'

