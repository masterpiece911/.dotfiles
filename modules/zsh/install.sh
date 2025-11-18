#!/usr/bin/env bash
set -euo pipefail

OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
OH_MY_POSH_VERSION="26.25.0"
LAZYGIT_VERSION="0.54.2"
LAZYDOCKER_VERSION="0.24.1"

LOCAL_BIN="${HOME}/.local/bin"

log() {
  printf '[zsh-install] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

# ==============================
# 1) Install Zsh
# ==============================

install_zsh() {
  if command -v zsh >/dev/null 2>&1; then
    log "Zsh already installed"
    return
  fi

  log "Installing zsh via apt-get..."
  require_cmd sudo
  
  sudo apt-get update
  sudo apt-get install -y zsh
  
  log "Zsh installation completed"
}

# ==============================
# 2) Install Oh My Zsh
# ==============================

install_oh_my_zsh() {
  if [ -d "${HOME}/.oh-my-zsh" ]; then
    log "Oh My Zsh already installed"
    return
  fi

  require_cmd curl
  require_cmd zsh
  
  log "Installing Oh My Zsh..."
  log "Fetching installer from ${OH_MY_ZSH_URL}"
  
  # Use unattended installation to avoid interactive prompts
  sh -c "$(curl -fsSL ${OH_MY_ZSH_URL})" --unattended
  
  log "Oh My Zsh installation completed"
}

# ==============================
# 3) Install Oh My Posh
# ==============================

install_oh_my_posh() {
  if command -v oh-my-posh >/dev/null 2>&1; then
    log "Oh My Posh already installed"
    return
  fi

  require_cmd curl
  require_cmd bash
  
  log "Installing Oh My Posh ${OH_MY_POSH_VERSION}..."
  
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -v ${OH_MY_POSH_VERSION}
  
  log "Oh My Posh installation completed"
}

# ==============================
# 4) Install Eza
# ==============================

install_eza() {
  if command -v eza >/dev/null 2>&1; then
    log "Eza already installed"
    return
  fi

  require_cmd cargo
  
  log "Installing Eza via cargo..."
  
  cargo install eza
  
  log "Eza installation completed"
}

# ==============================
# 5) Install Lazygit
# ==============================

install_lazygit() {
  mkdir -p "${LOCAL_BIN}"
  
  local lazygit_bin="${LOCAL_BIN}/lazygit"
  
  if [ -f "${lazygit_bin}" ]; then
    log "Lazygit already installed at ${lazygit_bin}"
    return
  fi

  require_cmd curl
  require_cmd tar
  
  log "Installing Lazygit ${LAZYGIT_VERSION}..."
  
  local tmpdir
  tmpdir="$(mktemp -d)"
  local tarball="${tmpdir}/lazygit.tar.gz"
  local url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  
  if ! curl -fsSL "${url}" -o "${tarball}"; then
    log "Failed to download Lazygit from ${url}"
    rm -rf "${tmpdir}"
    exit 1
  fi
  
  tar -xzf "${tarball}" -C "${tmpdir}"
  mv "${tmpdir}/lazygit" "${lazygit_bin}"
  chmod +x "${lazygit_bin}"
  
  rm -rf "${tmpdir}"
  log "Lazygit installed: ${lazygit_bin}"
}

# ==============================
# 6) Install Lazydocker
# ==============================

install_lazydocker() {
  mkdir -p "${LOCAL_BIN}"
  
  local lazydocker_bin="${LOCAL_BIN}/lazydocker"
  
  if [ -f "${lazydocker_bin}" ]; then
    log "Lazydocker already installed at ${lazydocker_bin}"
    return
  fi

  require_cmd curl
  require_cmd tar
  
  log "Installing Lazydocker ${LAZYDOCKER_VERSION}..."
  
  local tmpdir
  tmpdir="$(mktemp -d)"
  local tarball="${tmpdir}/lazydocker.tar.gz"
  local url="https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
  
  if ! curl -fsSL "${url}" -o "${tarball}"; then
    log "Failed to download Lazydocker from ${url}"
    rm -rf "${tmpdir}"
    exit 1
  fi
  
  tar -xzf "${tarball}" -C "${tmpdir}"
  mv "${tmpdir}/lazydocker" "${lazydocker_bin}"
  chmod +x "${lazydocker_bin}"
  
  rm -rf "${tmpdir}"
  log "Lazydocker installed: ${lazydocker_bin}"
}

# ==============================
# Main
# ==============================

main() {
  install_zsh
  install_oh_my_zsh
  install_oh_my_posh
  install_eza
  install_lazygit
  install_lazydocker
}

main "$@"
