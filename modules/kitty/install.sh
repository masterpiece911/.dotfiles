#!/usr/bin/env bash
set -euo pipefail

KITTY_VERSION="0.49.1"
INSTALLER_URL="https://sw.kovidgoyal.net/kitty/installer.sh"
KITTY_APP="${HOME}/.local/kitty.app"
LOCAL_BIN="${HOME}/.local/bin"
APPLICATIONS_DIR="${HOME}/.local/share/applications"

log() {
  printf '[kitty-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

installed_version() {
  if [[ -x "${KITTY_APP}/bin/kitty" ]]; then
    "${KITTY_APP}/bin/kitty" --version 2>/dev/null | awk '{print $2}'
  elif command -v kitty >/dev/null 2>&1; then
    kitty --version 2>/dev/null | awk '{print $2}'
  else
    printf ''
  fi
}

link_binaries() {
  mkdir -p "${LOCAL_BIN}"
  ln -sf "${KITTY_APP}/bin/kitty" "${LOCAL_BIN}/kitty"
  ln -sf "${KITTY_APP}/bin/kitten" "${LOCAL_BIN}/kitten"
}

install_desktop_entry() {
  local src="${KITTY_APP}/share/applications/kitty.desktop"
  local dest="${APPLICATIONS_DIR}/kitty.desktop"

  if [[ ! -f "${src}" ]]; then
    log "Desktop entry source missing; skip desktop integration"
    return
  fi

  mkdir -p "${APPLICATIONS_DIR}"
  cp -f "${src}" "${dest}"
  sed -i \
    -e "s|Icon=kitty|Icon=${KITTY_APP}/share/icons/hicolor/256x256/apps/kitty.png|g" \
    -e "s|Exec=kitty|Exec=${KITTY_APP}/bin/kitty|g" \
    "${dest}"
}

main() {
  require_cmd curl
  require_cmd sh

  local current
  current="$(installed_version)"

  if [[ "${current}" == "${KITTY_VERSION}" ]] && [[ -x "${LOCAL_BIN}/kitty" ]] && [[ -x "${LOCAL_BIN}/kitten" ]]; then
    log "Kitty ${KITTY_VERSION} already installed"
    return
  fi

  log "Installing Kitty ${KITTY_VERSION}..."
  curl -fsSL "${INSTALLER_URL}" | sh /dev/stdin \
    launch=n \
    "installer=version-${KITTY_VERSION}"

  link_binaries
  install_desktop_entry

  current="$(installed_version)"
  if [[ "${current}" != "${KITTY_VERSION}" ]]; then
    log "Kitty install finished but version is '${current:-unknown}', expected ${KITTY_VERSION}"
    exit 1
  fi

  log "Kitty ${KITTY_VERSION} installed: ${LOCAL_BIN}/kitty"
}

main "$@"
