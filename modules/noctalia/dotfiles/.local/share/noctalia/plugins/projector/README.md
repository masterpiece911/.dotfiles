# Project

F9 (Framework's display key, which sends Super+P) opens a native Noctalia chooser:

1. Laptop only
2. Duplicate — mirror the laptop onto all connected external screens
3. Extend — enable external screens to the right of the laptop
4. External only — enable external screens, then switch off the laptop screen

Nothing changes until a mode is selected. External-only modes are unavailable
without an external screen. Choose with the mouse or 1–4; Escape closes.

Changes require confirmation within 15 seconds. A separate Python watchdog
restores the previous resolution, refresh rate, position, scale, rotation,
mirroring, and enabled state, even if the chooser or Noctalia closes. If the old
external screen has disconnected, rollback keeps the laptop screen enabled.

Modes are session-only: no monitor configuration is written to disk. A Hyprland
config reload restores the saved compositor configuration. Hyprland's native
mirroring may stretch content when displays have different aspect ratios.

```sh
noctalia msg panel-toggle noyan/projector:chooser
python3 ~/.local/share/noctalia/plugins/projector/projector.py --status
python3 -m unittest discover -s ~/.local/share/noctalia/plugins/projector -p 'test_*.py'
```
