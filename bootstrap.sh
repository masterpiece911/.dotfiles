#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${HOME}/.dotfiles"

# Set your actual repo here (or via env)
REPO_URL="${DOTFILES_REPO_URL:-git@https://bitbucket.fe.lan/users/sahi_no/repos/dotfiles/browse/bootstrap.sh}"

log() {
  printf '[dotfiles-bootstrap] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [OPTIONS] [-- INSTALL_ARGS...]

Bootstrap dotfiles into ${DOTFILES_DIR} and run install.sh.

Options (for bootstrap itself):
  --no-install      Clone / update repo only, do not run install.sh
  --branch <name>  Clone using this branch (ignored if repo already exists)
  -h, --help       Show this help

Everything after '--' is passed directly to install.sh.

Examples:
  $(basename "$0")
      Clone/update repo and run: install.sh --all

  $(basename "$0") --no-install
      Only clone/update repo

  $(basename "$0") -- --config-only --all
      Clone/update repo, then: install.sh --config-only --all

  $(basename "$0") --branch main
      Clone repo on branch 'main' (first run only), then install.sh --all
EOF
}

# -----------------------------
# Parse bootstrap args
# -----------------------------

no_install=false
branch=""
install_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-install)
    no_install=true
    shift
    ;;
  --branch)
    if [[ $# -lt 2 ]]; then
      log "--branch requires a value"
      exit 1
    fi
    branch="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    # everything else is for install.sh
    install_args=("$@")
    break
    ;;
  *)
    log "Unknown option for bootstrap: $1"
    usage
    exit 1
    ;;
  esac
done

main() {
  require_cmd git

  if [[ ! -d "$DOTFILES_DIR" ]]; then
    # First-time clone
    log "Dotfiles directory not found, cloning into ${DOTFILES_DIR}"

    if [[ -z "$REPO_URL" ]]; then
      log "REPO_URL is empty. Set DOTFILES_REPO_URL or edit bootstrap.sh."
      exit 1
    fi

    clone_cmd=(git clone)
    if [[ -n "$branch" ]]; then
      clone_cmd+=(--branch "$branch")
    fi
    clone_cmd+=("$REPO_URL" "$DOTFILES_DIR")

    log "Running: ${clone_cmd[*]}"
    "${clone_cmd[@]}"

  else
    # Existing directory: must be a git repo
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
      log "${DOTFILES_DIR} exists but is not a git repository."
      log "Please move or remove it and rerun bootstrap."
      exit 1
    fi

    if [[ -n "$branch" ]]; then
      log "Note: --branch ignored, repo already exists at ${DOTFILES_DIR}."
    fi

    log "Updating dotfiles repo in ${DOTFILES_DIR}..."
    git -C "$DOTFILES_DIR" pull --ff-only
  fi

  if $no_install; then
    log "--no-install given, skipping install.sh."
    exit 0
  fi

  # Run install.sh
  local install_script="${DOTFILES_DIR}/install.sh"

  if [[ ! -x "$install_script" ]]; then
    log "install.sh not found or not executable at ${install_script}"
    exit 1
  fi

  # Default behavior: if no explicit install args, use --all
  if ((${#install_args[@]} == 0)); then
    install_args=(--all)
  fi

  log "Running install.sh with args: ${install_args[*]}"
  exec "$install_script" "${install_args[@]}"
}

main "$@"
