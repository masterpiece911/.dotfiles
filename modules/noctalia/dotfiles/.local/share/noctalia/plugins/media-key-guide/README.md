# Media Key Guide

A native Noctalia panel showing the Framework Laptop 13 media row. The most
recent key is highlighted for 2.1 seconds; repeated volume/brightness presses
refresh the timer. The panel never takes keyboard focus, remains above fullscreen
windows, and does not replace other open Noctalia panels.

The icons follow the hardware layout, except F11/F12 reflect this machine's
existing screenshot-chooser / region-screenshot bindings. F9 opens the Project
chooser (Laptop only / Duplicate / Extend / External only). F10 has no new radio
action assigned. Fn/Fn-lock are handled by the
keyboard firmware and cannot themselves trigger this guide.

## Appearance

A single uninterrupted row of wide, 48 px-high pills, with no header. The panel
is 1280 × 80 logical pixels: 80 px from either edge of this laptop's 1440 px-wide
logical display. The outer panel uses Noctalia's standard corner style; its
plugin API does not expose a per-panel outer corner radius.

## Test without performing a media action

```sh
noctalia msg plugin noyan/media-key-guide:events all show 3
```

Change the hide delay in Noctalia Settings → Plugins → Media Key Guide.

## Integration

`~/.config/hypr/media-key-guide.conf` adds passive, non-consuming companion
bindings, leaving the original media actions intact. The guide bindings do not
run on the lock screen. Ordinary F1–F12 events (when Fn-lock is on) are untouched.

## Disable / remove

Remove the `source = ~/.config/hypr/media-key-guide.conf` line from
`~/.config/hypr/hyprland.conf`, then run `hyprctl reload` and:

```sh
noctalia msg plugins disable noyan/media-key-guide
```
