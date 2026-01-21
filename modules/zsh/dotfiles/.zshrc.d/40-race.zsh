r() {
	(cd ~/projects/race && poetry run race "$@")
}

rupdate() {
  (cd ~/projects/race && ./syncDevWithMc7.sh "$@")
}

rshell() {
  local orig_dir="$PWD"
  local venv_path=$(cd ~/projects/race && poetry env info --path)
  source "$venv_path/bin/activate"
  cd "$orig_dir"
}

alias ru='r up dev'
alias rd='r down'
alias rcli='r cli'

