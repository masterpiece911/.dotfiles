#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Noctalia's color generator owns these files. Seed safe defaults for a fresh
# machine, but never replace an existing palette or stow generated output.
seed_theme() {
  local source="$1" target="$2"
  if [[ -e "$target" || -L "$target" ]]; then
    return
  fi
  mkdir -p "$(dirname "$target")"
  install -m 644 "$source" "$target"
}

seed_theme "$MODULE_DIR/theme-fallbacks/hyprland.conf" "$HOME/.config/hypr/noctalia.conf"
seed_theme "$MODULE_DIR/theme-fallbacks/kitty.conf" "$HOME/.config/kitty/themes/noctalia.conf"
