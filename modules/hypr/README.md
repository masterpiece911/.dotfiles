# Hyprland

The current Hyprland 0.53.3 (hyprlang) configuration, lid/backlight helpers,
focus/display utilities, and legacy Waybar configuration. No compositor packages
are installed by this module. Monitor names, scaling and keyboard layouts are
machine-specific and intentionally preserved.

Use together with the `noctalia` and `kitty` modules:

```sh
./install.sh hypr noctalia kitty
# After initial setup, refresh just the managed configs:
./install.sh --config-only hypr noctalia kitty
hyprctl reload config-only
```

`noctalia` supplies the sourced `~/.config/hypr/noctalia-bindings.conf`, media-key
guide, and desktop menu utilities. The lid helper also uses Noctalia for locking.
Legacy `waybar.*` files are preserved but are not started by this configuration.
Old `.bak*` files are not imported.

## Floating terminals

- **Super+Shift+F** / **Super+Shift+Space** toggle tiled/floating.
- **Super+Ctrl+Shift+F3** always floats and centers the active window.
- Kitty is sized to **100 columns × 30 rows** when entering floating mode.
- Other apps keep their usual floating size. Toggling back restores tiling.

The helper asks the running Kitty instance for font metrics, margins, padding
and tab-bar space, then converts physical pixels to the monitor's logical scale.
Hyprland performs the resize because Wayland client resize requests are ignored
by this compositor. A split Kitty window gets a 100×30 overall terminal area;
individual panes share that space.

This requires the Kitty module's socket-only remote control configuration
(`listen_on unix:/tmp/kitty-$USER`). Restart older Kitty instances if their remote
control socket is unavailable. Change `COLUMNS` / `ROWS` in `float-window.py` and
the Kitty module's `initial_window_width` / `initial_window_height` together.

Tests:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s modules/hypr/tests
```
