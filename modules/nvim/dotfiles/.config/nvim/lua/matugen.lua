 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#fff8f7',
    base01 = '#ffe9eb',
    base02 = '#fde2e5',
    base03 = '#906e73',
    base04 = '#5c3f44',
    base05 = '#26181a',
    base06 = '#26181a',
    base07 = '#26181a',
    base08 = '#ba1a1a',
    base09 = '#8e4957',
    base0A = '#745086',
    base0B = '#7c4997',
    base0C = '#ffb2be',
    base0D = '#e7b4ff',
    base0E = '#e2b7f4',
    base0F = '#f6d9ff',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#26181a',          bg = '#fff8f7' })
  hi('TelescopeBorder',         { fg = '#906e73',             bg = '#fff8f7' })
  hi('TelescopePromptNormal',   { fg = '#26181a',          bg = '#fff8f7' })
  hi('TelescopePromptBorder',   { fg = '#906e73',             bg = '#fff8f7' })
  hi('TelescopePromptPrefix',   { fg = '#7c4997',             bg = '#fff8f7' })
  hi('TelescopePromptCounter',  { fg = '#5c3f44',  bg = '#fff8f7' })
  hi('TelescopePromptTitle',    { fg = '#fff8f7',             bg = '#7c4997' })
  hi('TelescopePreviewTitle',   { fg = '#fff8f7',             bg = '#745086' })
  hi('TelescopeResultsTitle',   { fg = '#fff8f7',             bg = '#8e4957' })
  hi('TelescopeSelection',      { fg = '#26181a',          bg = '#fde2e5' })
  hi('TelescopeSelectionCaret', { fg = '#7c4997',             bg = '#fde2e5' })
  hi('TelescopeMatching',       { fg = '#7c4997',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#26181a',          bg = '#fff8f7' })
  hi('MiniPickBorder',         { fg = '#906e73',             bg = '#fff8f7' })
  hi('MiniPickPrompt',   { fg = '#26181a',          bg = '#fff8f7' })
  hi('MiniPickPromptPrefix',   { fg = '#7c4997',             bg = '#fff8f7' })
  hi('MiniPickBorderText',    { fg = '#fff8f7',             bg = '#7c4997' })
  hi('MiniPickMatchCurrent',      { fg = '#26181a',          bg = '#fde2e5' })
  hi('MiniPickPromptCaret', { fg = '#7c4997',             bg = '#fde2e5' })
  hi('MiniPickMatchRanges',       { fg = '#7c4997',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
