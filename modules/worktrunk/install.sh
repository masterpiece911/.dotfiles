#!/usr/bin/env bash
set -euo pipefail

WORKTRUNK_VERSION="0.72.0"

log() {
  printf '[worktrunk-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

main() {
  require_cmd rustup
  require_cmd cargo

  log "Updating the stable Rust toolchain"
  rustup update stable

  local installed_version=""
  if command -v wt >/dev/null 2>&1; then
    installed_version="$(wt --version 2>/dev/null || true)"
  fi

  if [[ "${installed_version}" == "wt ${WORKTRUNK_VERSION}" ]]; then
    log "Worktrunk ${WORKTRUNK_VERSION} is already installed"
    return
  fi

  log "Installing Worktrunk ${WORKTRUNK_VERSION} via Cargo"
  cargo +stable install worktrunk \
    --version "${WORKTRUNK_VERSION}" \
    --locked \
    --force
}

main "$@"
