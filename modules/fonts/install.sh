#!/usr/bin/env bash
set -euo pipefail

CASCADIA_VERSION="2407.24"
CASCADIA_URL="https://github.com/microsoft/cascadia-code/releases/download/v${CASCADIA_VERSION}/CascadiaCode-${CASCADIA_VERSION}.zip"

FONTS_DIR="${HOME}/.local/share/fonts"
VERSION_MARKER="${FONTS_DIR}/.cascadia-code-pl.version"

log() {
  printf '[fonts-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

install_cascadia_code_pl() {
  mkdir -p "${FONTS_DIR}"

  if [ -f "${VERSION_MARKER}" ] && [ "$(cat "${VERSION_MARKER}")" = "${CASCADIA_VERSION}" ] \
    && [ -f "${FONTS_DIR}/CascadiaCodePL.ttf" ] && [ -f "${FONTS_DIR}/CascadiaCodePLItalic.ttf" ]; then
    log "Cascadia Code PL ${CASCADIA_VERSION} already installed"
    return
  fi

  require_cmd curl
  require_cmd unzip

  log "Installing Cascadia Code PL ${CASCADIA_VERSION}..."

  local tmpdir
  tmpdir="$(mktemp -d)"
  local zipfile="${tmpdir}/CascadiaCode.zip"

  if ! curl -fsSL "${CASCADIA_URL}" -o "${zipfile}"; then
    log "Failed to download Cascadia Code from ${CASCADIA_URL}"
    rm -rf "${tmpdir}"
    exit 1
  fi

  unzip -qo "${zipfile}" "ttf/CascadiaCodePL.ttf" "ttf/CascadiaCodePLItalic.ttf" -d "${tmpdir}"
  cp -f "${tmpdir}/ttf/CascadiaCodePL.ttf" "${FONTS_DIR}/CascadiaCodePL.ttf"
  cp -f "${tmpdir}/ttf/CascadiaCodePLItalic.ttf" "${FONTS_DIR}/CascadiaCodePLItalic.ttf"
  printf '%s\n' "${CASCADIA_VERSION}" > "${VERSION_MARKER}"

  rm -rf "${tmpdir}"

  if command -v fc-cache >/dev/null 2>&1; then
    log "Refreshing font cache..."
    fc-cache -f "${FONTS_DIR}" >/dev/null
  else
    log "fc-cache not found; skip font cache refresh"
  fi

  log "Cascadia Code PL installed: ${FONTS_DIR}/CascadiaCodePL.ttf"
}

main() {
  install_cascadia_code_pl
}

main "$@"
