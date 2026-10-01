#!/usr/bin/env bash
set -euo pipefail

NVIM_VERSION="0.12.5"
NVIM_SHA256="d429822f6994770e3bb10330e0baf21e72b0afe66e0507cb3c631c1c65f4bf41"

NVIM_APPDIR="${HOME}/Applications"
NVIM_APPIMAGE="${NVIM_APPDIR}/nvim-${NVIM_VERSION}.AppImage"

LOCAL_BIN="${HOME}/.local/bin"
NVIM_SYMLINK="${LOCAL_BIN}/nvim"

NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.appimage"

log() {
  printf '[nvim-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

ensure_nvim_appimage() {
  mkdir -p "${NVIM_APPDIR}"

  if [ -f "${NVIM_APPIMAGE}" ]; then
    log "Neovim AppImage already present: ${NVIM_APPIMAGE}"
    return
  fi

  require_cmd curl
  log "Downloading Neovim ${NVIM_VERSION} AppImage to ${NVIM_APPIMAGE}"

  local tmpfile
  tmpfile="$(mktemp)"

  if ! curl -fsSL "${NVIM_DOWNLOAD_URL}" -o "${tmpfile}"; then
    log "Failed to download Neovim from ${NVIM_DOWNLOAD_URL}"
    rm -f "${tmpfile}"
    exit 1
  fi

  log "Verifying SHA256 checksum..."
  local actual
  actual="$(sha256sum "${tmpfile}" | awk '{print $1}')"

  if [ "${actual}" != "${NVIM_SHA256}" ]; then
    log "Checksum mismatch!"
    log "Expected: ${NVIM_SHA256}"
    log "Actual:   ${actual}"
    rm -f "${tmpfile}"
    exit 1
  fi

  mv "${tmpfile}" "${NVIM_APPIMAGE}"
  chmod +x "${NVIM_APPIMAGE}"

  log "Neovim AppImage installed: ${NVIM_APPIMAGE}"
}

ensure_nvim_symlink() {
  mkdir -p "${LOCAL_BIN}"

  if [ -e "${NVIM_SYMLINK}" ] || [ -L "${NVIM_SYMLINK}" ]; then
    log "Removing existing nvim at ${NVIM_SYMLINK}"
    rm -f "${NVIM_SYMLINK}"
  fi

  ln -s "${NVIM_APPIMAGE}" "${NVIM_SYMLINK}"
  log "Symlink created: ${NVIM_SYMLINK} -> ${NVIM_APPIMAGE}"
}

main() {
  ensure_nvim_appimage
  ensure_nvim_symlink
}

main "$@"
