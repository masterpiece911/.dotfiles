#!/usr/bin/env bash
set -euo pipefail

NVIM_VERSION="0.9.5"
NVIM_SHA256="0c82e5702af7a11fbb916a11b4a82e98928abf8266c74b2030ea740340437bf9"
LV_BRANCH='release-1.4/neovim-0.9'

NVIM_APPDIR="${HOME}/Applications"
NVIM_APPIMAGE="${NVIM_APPDIR}/nvim-${NVIM_VERSION}.AppImage"

LOCAL_BIN="${HOME}/.local/bin"
NVIM_SYMLINK="${LOCAL_BIN}/nvim"

LVIM_INSTALLER_URL="https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh"

log() {
  printf '[lvim-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

# ==============================
# 1) Ensure Neovim AppImage
# ==============================

ensure_nvim_appimage() {
  mkdir -p "${NVIM_APPDIR}"

  if [ -f "${NVIM_APPIMAGE}" ]; then
    log "Neovim AppImage already present: ${NVIM_APPIMAGE}"
    return
  fi

  require_cmd curl
  log "Downloading Neovim ${NVIM_VERSION} AppImage to ${NVIM_APPIMAGE}"

  # This URL pattern is the standard Neovim release AppImage URL; adjust if needed.
  local url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim.appimage"

  # Download to a temp file first, then move into place
  local tmpfile
  tmpfile="$(mktemp)"

  if ! curl -fsSL "${url}" -o "${tmpfile}"; then
    log "Failed to download Neovim from ${url}"
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

# ==============================
# 2) Ensure nvim symlink
# ==============================

ensure_nvim_symlink() {
  mkdir -p "${LOCAL_BIN}"

  if [ -e "${NVIM_SYMLINK}" ] || [ -L "${NVIM_SYMLINK}" ]; then
    log "Removing existing nvim at ${NVIM_SYMLINK}"
    rm -f "${NVIM_SYMLINK}"
  fi

  ln -s "${NVIM_APPIMAGE}" "${NVIM_SYMLINK}"
  log "Symlink created: ${NVIM_SYMLINK} -> ${NVIM_APPIMAGE}"
}

# ==============================
# 3) Install LunarVim
# ==============================

install_lvim() {
  # If lvim is already installed, don't run the installer again
  if command -v lvim >/dev/null 2>&1; then
    log "LunarVim already installed (lvim found in PATH). Skipping LV installer."
    return
  fi

  require_cmd curl
  require_cmd bash

  # Ensure our nvim is preferred during the LV installer run
  export PATH="${LOCAL_BIN}:${PATH}"

  log "Installing LunarVim using ${NVIM_SYMLINK}"
  log "Fetching installer from ${LVIM_INSTALLER_URL}"

  # You can add flags here if you want non-interactive behavior, etc.
  bash <(curl -fsSL "${LVIM_INSTALLER_URL}") --yes

  log "LunarVim installation completed."
}

# ==============================
# Main
# ==============================

main() {
  ensure_nvim_appimage
  ensure_nvim_symlink
  install_lvim
}

main "$@"
