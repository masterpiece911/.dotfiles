r() {
	(cd ~/projects/race && poetry run race "$@")
}

rupdate() {
  (cd ~/projects/race && ./syncDevWithMc7.sh "$@")
}

alias ru='r up dev'
alias rd='r down'
alias rcli='r cli'

