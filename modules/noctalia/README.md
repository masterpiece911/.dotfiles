# Noctalia

Migrated from the working Noctalia v5.2.1 desktop. This module contains:

- `~/.config/noctalia/config.toml` and `desktop.toml`: shell preferences, bar,
  lock-screen layout, idle behavior, enabled plugins and theme selections.
- Hyprland shell bindings, the passive Framework media-key guide bindings,
  and screenshot/browser/shortcut-menu utilities.
- Custom **Display Mover**, **Media Key Guide**, **Project**, and **Hyprland Layouts**
  plugins under `~/.local/share/noctalia/plugins/`, including helper tests.
- The active OpenCode, Zen Browser, Neovim and Lazygit community templates,
  including the customized apply hooks, at their existing state-directory paths.

Install Noctalia and its desktop dependencies separately. The configuration uses
`hyprctl`, Python 3, Kitty, `playerctl`, `grim`, `slurp`, `wl-copy`, `notify-send`,
`xdg-settings`, `gtk-launch` and Nautilus. Legacy window-picker code uses Wofi.
The official `noctalia/wallpaper_depth` plugin remains enabled; install it through
Noctalia's plugin manager on a new machine rather than vendoring its cache here.

```sh
./install.sh noctalia hypr kitty
# For subsequent config-only updates:
./install.sh --config-only noctalia hypr kitty
hyprctl reload config-only
noctalia msg config-reload
```

The module installer only seeds Nord fallback files for Hyprland and Kitty if
they are missing. It never overwrites existing generated colors or downloads
software. Run installers on initial setup before using config-only updates.

## Hyprland layout chooser

**Super+T** opens a visual chooser for **Dwindle** and five **Master** presets
(left, right, top, bottom, centered), with
miniature window diagrams and a current-layout indicator. Click a card, use
arrows, press **1–6**, or repeat **Super+T** to switch layouts live while the
chooser stays open. Enter or Esc dismisses it, keeping the chosen layout. Only available
built-in layouts can be selected. Changes are session-wide and runtime-only;
Hyprland config reload restores configured defaults. Master presets override
workspace orientations for the session; centered Master needs at least three
tiled windows by default. No Hyprland upgrade or extra plugins are required.

On an existing desktop, after stowing, enable it once with
`noctalia msg plugins enable noyan/layout-picker` (runtime settings override the
tracked plugin list).

## Settings and privacy

Noctalia loads the config-directory TOML files first, then applies
`~/.local/state/noctalia/settings.toml` as higher-priority Settings UI overrides.
`desktop.toml` is a sanitized snapshot of the migrated preferences, not a symlink
to mutable state. Existing Settings UI choices and calendar accounts are left
untouched. To sync a later preference, update the corresponding tracked default;
the current machine's runtime override continues to take precedence.

Calendar account identities/credentials, avatar photographs, clipboard and
notification histories, recently used items, screen-time data, downloaded plugin
repositories, compiled Python files, template cache metadata and generated theme
output are not imported. Wallpapers, avatar images, browser profiles and their
private content stay local. Some wallpaper/output paths and widget positions are
machine-specific; adjust them when installing elsewhere.

The generated `~/.config/hypr/noctalia.conf` and
`~/.config/kitty/themes/noctalia.conf` remain ordinary local files. Noctalia may
also regenerate the existing Neovim/other application theme outputs; those
applications' config ownership is unchanged. Community-template updates may
replace files at the managed state-directory paths: review/resync custom hooks
before accepting upstream updates, and re-stow this module if needed.

Validation:

```sh
noctalia config validate
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s modules/noctalia/dotfiles/.local/share/noctalia/plugins/projector -p 'test_*.py'
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s modules/noctalia/dotfiles/.local/share/noctalia/plugins/layout-picker -p 'test_*.py'
```
