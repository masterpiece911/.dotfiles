#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MODULES_DIR="${DOTFILES_DIR}/modules"
TARGET_DIR="${HOME}"

# ===================================================
# Logging & helpers
# ===================================================

log() {
  printf '[dotfiles-install] %s\n' "$*" >&2
}

drylog() {
  printf '[dotfiles-install][dry-run] %s\n' "$*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [OPTIONS] [module1 module2 ...]

Options:
  --all             Use all modules under ${MODULES_DIR}
  --installers-only Run module installers only (no config/stow)
  --no-installers   Do not run module installers
  --config-only     Stow configs only (alias for --no-installers)
  --no-config       Do not stow configs
  --dry-run         Show what would happen, but do nothing
  -h, --help        Show this help

Examples:
  $(basename "$0")                    # installers + stow for all modules
  $(basename "$0") lvim zsh           # only these modules
  $(basename "$0") --installers-only lvim
  $(basename "$0") --dry-run --all
EOF
}

# ===================================================
# Arg parsing
# ===================================================

run_installers=true
run_config=true
all_flag=false
dry_run=false
declare -a requested_modules=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --installers-only)
      run_installers=true
      run_config=false
      ;;
    --no-installers|--config-only)
      run_installers=false
      ;;
    --no-config)
      run_config=false
      ;;
    --all)
      all_flag=true
      ;;
    --dry-run)
      dry_run=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      requested_modules+=("$1")
      ;;
  esac
  shift
done

if ! $run_installers && ! $run_config && ! $dry_run; then
  log "Nothing to do: installers and config both disabled."
  exit 0
fi

if $all_flag && ((${#requested_modules[@]} > 0)); then
  log "Cannot use --all and explicit module names together."
  exit 1
fi

# ===================================================
# Module resolution
# ===================================================

collect_all_modules() {
  local dir="$1"
  if [ ! -d "$dir" ]; then return 0; fi
  find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

declare -a effective_modules=()

if ((${#requested_modules[@]} > 0)); then
  effective_modules=("${requested_modules[@]}")
else
  mapfile -t effective_modules < <(collect_all_modules "$MODULES_DIR")
fi

if ((${#effective_modules[@]} == 0)); then
  log "No modules found under ${MODULES_DIR}."
  exit 0
fi

# ======================================
# Failure tracking
# ======================================

declare -a failed_installers=()
declare -a failed_configs=()

# ===================================================
# Backup + stow helpers
# ===================================================

backup_if_needed() {
  local path="$1"
  local backup_root="${HOME}/.dotfiles_backup"

  # Only back up real files/dirs, not symlinks
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    # A Stow-managed directory can itself be a symlink while files beneath it
    # appear regular. Never follow that directory back into this repository.
    local resolved
    resolved="$(readlink -f -- "$path")"
    if [[ "$resolved" == "$DOTFILES_DIR/"* ]]; then
      return
    fi

    # Derive a relative path under TARGET_DIR, if possible
    local rel="$path"
    if [[ "$rel" == "$TARGET_DIR/"* ]]; then
      rel="${rel#$TARGET_DIR/}"
    else
      # Fallback: strip leading slash so we don't create absolute paths under backup_root
      rel="${rel#/}"
    fi

    local dest="${backup_root}/${rel}"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    if $dry_run; then
      drylog "Would back up ${path} -> ${dest}"
      return
    fi

    mkdir -p "$dest_dir"
    log "Backing up ${path} -> ${dest}"
    if ! mv "$path" "$dest"; then
      log "Backup failed for ${path}"
      # keep going; this will likely cause stow to fail and be recorded there
      return 1
    fi
  fi
}

stow_module_config() {
  local module="$1"
  local dot_dir="${MODULES_DIR}/${module}/dotfiles"

  [ -d "$dot_dir" ] || return 0

  require_cmd stow

  log "Stowing config for module: ${module}"

  (
    cd "$dot_dir"
    find . -type f -print0
  ) | while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    backup_if_needed "${TARGET_DIR}/${rel}"
  done

  if $dry_run; then
    drylog "Would stow config for ${module}"
    return
  fi

  (
    cd "$dot_dir"
    if ! stow -R --target="${TARGET_DIR}" .; then
      log "stow failed for module '${module}'"
      failed_configs+=("$module")
      return 1
    fi
  )
}

run_module_installer() {
  local module="$1"
  local installer="${MODULES_DIR}/${module}/install.sh"

  if [ ! -f "$installer" ]; then
    # no installer for this module
    return 0
  fi

  # Installer exists but is not executable → hard error
  if [ ! -x "$installer" ]; then
    log "Installer for module '${module}' exists but is not executable: ${installer}"
    failed_installers+=("${module} (not executable)")
    return 1
  fi

  if $dry_run; then
    drylog "Would run installer for ${module}"
    return
  fi

  log "Running installer for module: ${module}"
  if ! "$installer"; then
    log "Installer failed for module '${module}'"
    failed_installers+=("$module")
    return 1
  fi
}

# ===================================================
# Main logic
# ===================================================

main() {
  if $dry_run; then
    drylog "Dry-run mode enabled: no changes will be made."
  fi

  log "Modules to process: ${effective_modules[*]}"

  for module in "${effective_modules[@]}"; do
    local module_path="${MODULES_DIR}/${module}"
    if [ ! -d "$module_path" ]; then
      log "Skipping unknown module '${module}'"
      continue
    fi

    # Track installer success for this module
    local installer_ok=true

    if $run_installers; then
      if ! run_module_installer "$module"; then
        installer_ok=false
        # module is already recorded as failed inside run_module_installer
      fi
    fi

    # If installer failed → do not stow for this module
    if $run_config; then
      if $installer_ok; then
        stow_module_config "$module" || true
      else
        log "Skipping stow for '${module}' due to installer failure."
      fi
    fi
  done

  if $dry_run; then
    drylog "Dry-run finished. No operations were performed."
    exit 0
  fi

  # Summary
  if ((${#failed_installers[@]} == 0)) && ((${#failed_configs[@]} == 0)); then
    log "All modules processed successfully."
    exit 0
  fi

  log "Some modules had issues:"

  if ((${#failed_installers[@]} > 0)); then
    log "  Installers failed for:"
    for m in "${failed_installers[@]}"; do
      log "    - $m"
    done
  fi

  if ((${#failed_configs[@]} > 0)); then
    log "  Config/stow failed for:"
    for m in "${failed_configs[@]}"; do
      log "    - $m"
    done
  fi

  exit 1
}

main "$@"

