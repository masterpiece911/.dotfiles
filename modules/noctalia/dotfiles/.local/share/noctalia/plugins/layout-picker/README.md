# Hyprland Layouts

Press **Super+T** to open the tiling-layout chooser. Press it again while open
to cycle layouts live (wrapping around and skipping unavailable layouts).
Click a preview, press **1–6**, or use arrows to switch immediately. The chooser
stays open, and the current-layout marker follows each successful change.
**Enter**, **Esc**, or clicking outside closes it, keeping the chosen layout;
there is no separate Apply step. Merely hovering does not change your layout.

The six choices are **Dwindle**, **Master left**, **Master right**, **Master top**,
**Master bottom**, and **Master centered**. Each has its own window diagram.
Actual geometry follows your Hyprland layout settings, including master count
and size ratio. Centered Master normally needs at least three tiled windows;
with fewer it uses `master:center_master_fallback` (left by default).
Only built-in layouts reported by the running compositor are selectable.

Changes apply session-wide using `hyprctl keyword`, without editing files.
Master presets set `master:orientation` and an in-memory workspace rule with
an empty (all-workspaces) selector and `layoutopt:orientation`. This overrides
0.53's cached workspace orientations, including on existing workspaces, without
changing focus or other workspace-rule properties. Presets override custom
workspace orientations until config reload; Dwindle leaves Master options alone.
A Hyprland configuration reload clears the rule and restores configured defaults.
This plugin does not change keyboard layouts, floating state, or window groups.

Open/advance manually: `noctalia msg plugin noyan/layout-picker:events all advance`.

Tests (no live desktop changes):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s modules/noctalia/dotfiles/.local/share/noctalia/plugins/layout-picker -p 'test_*.py'
```
