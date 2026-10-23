-- The compositor sends media-key events; this panel never captures keyboard input.
local keys = {
  { glyph = "volume-off", label = "Mute" },
  { glyph = "volume-2", label = "Volume down" },
  { glyph = "volume", label = "Volume up" },
  { glyph = "player-skip-back", label = "Previous track" },
  { glyph = "player-play", label = "Play / pause" },
  { glyph = "player-skip-forward", label = "Next track" },
  { glyph = "brightness-down", label = "Brightness down" },
  { glyph = "brightness-up", label = "Brightness up" },
  { glyph = "device-desktop", label = "Display / project" },
  { glyph = "plane", label = "Airplane mode" },
  { glyph = "screenshot", label = "Screenshot chooser" },
  { glyph = "crop", label = "Region screenshot" },
}

local opened = false
local selected, deadline = nil, 0
-- Panel update() ticks are whole-second; frame callbacks give a precise hide delay
-- and are automatically suspended while the panel is closed.
panel.setNeedsFrameTick(true)

local function render()
  if not opened then return end
  local cells = {}
  for index, key in ipairs(keys) do
    local active = index == selected
    local foreground = active and "on_primary" or "on_surface_variant"
    table.insert(cells, ui.row({
      key = "f" .. index,
      flexGrow = 1, height = 48, gap = 8,
      align = "center", justify = "center", radius = 24,
      fill = active and "primary" or "surface_variant/0.5",
    }, {
      ui.label({ text = "F" .. index, fontSize = 11, color = foreground }),
      ui.glyph({ name = key.glyph, size = 24, color = foreground }),
    }))
  end

  panel.render(ui.row({ gap = 8, align = "center", flexGrow = 1 }, cells))
end

local function refreshDeadline()
  deadline = noctalia.nowMs() + noctalia.getConfig("duration_ms")
end

noctalia.state.watch("press", function(press)
  if type(press) ~= "table" or not keys[press.index] then return end
  selected = press.index
  refreshDeadline()
  render()
end)

function onOpen(context)
  opened = true
  noctalia.state.set("visible", true)
  local press = noctalia.state.get("press")
  if type(press) == "table" and keys[press.index] then selected = press.index end
  local index = tonumber(context)
  if index and index % 1 == 0 and keys[index] then selected = index end
  refreshDeadline()
  render()
end

function onClose()
  opened = false
  noctalia.state.set("visible", false)
  selected = nil
end

function onFrameTick(_deltaMs)
  if opened and noctalia.nowMs() >= deadline then panel.close() end
end
