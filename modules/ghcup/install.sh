#!/usr/bin/env bash
set -euo pipefail

GHCUP_BOOTSTRAP_URL="https://get-ghcup.haskell.org"
GHCUP_BIN="${HOME}/.ghcup/bin/ghcup"

GHC_VERSION="9.4.8"
CABAL_VERSION="3.10.2.0"
HLS_VERSION="2.7.0.0"
STACK_VERSION="3.11.1"

log() {
  printf '[ghcup-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

# ==============================
# 1) Install GHCup
# ==============================

install_ghcup() {
  if [ -x "${GHCUP_BIN}" ]; then
    log "GHCup already installed at ${GHCUP_BIN}"
    return
  fi

  require_cmd curl

  log "Installing GHCup via ${GHCUP_BOOTSTRAP_URL}"

  # Any non-empty BOOTSTRAP_HASKELL_ADJUST_BASHRC (even "no") makes the
  # bootstrap edit ~/.zshrc; leaving it unset in non-interactive mode skips it.
  # PATH is set up by the zsh module's .zshrc.d/50-ghcup.zsh instead.
  curl --proto '=https' --tlsv1.2 -sSf "${GHCUP_BOOTSTRAP_URL}" |
    env -u BOOTSTRAP_HASKELL_ADJUST_BASHRC \
      BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
      BOOTSTRAP_HASKELL_MINIMAL=1 \
      sh

  log "GHCup installation completed"
}

# ==============================
# 2) Install and set default tools
# ==============================

install_tool() {
  local tool="$1"
  local version="$2"

  if "${GHCUP_BIN}" whereis "${tool}" "${version}" >/dev/null 2>&1; then
    log "${tool} ${version} already installed"
  else
    log "Installing ${tool} ${version}..."
    "${GHCUP_BIN}" install "${tool}" "${version}"
  fi

  "${GHCUP_BIN}" set "${tool}" "${version}"
}

# ==============================
# Main
# ==============================

main() {
  install_ghcup
  install_tool ghc "${GHC_VERSION}"
  install_tool cabal "${CABAL_VERSION}"
  install_tool hls "${HLS_VERSION}"
  install_tool stack "${STACK_VERSION}"
}

main "$@"
