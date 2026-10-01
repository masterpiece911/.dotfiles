#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[lvim-install] %s\n' "$*" >&2
}

main() {
  log "DEPRECATED: the lvim module is no longer maintained."
  log "Use the nvim module instead: install.sh nvim"
  log "Skipping LunarVim installation."
}

main "$@"
