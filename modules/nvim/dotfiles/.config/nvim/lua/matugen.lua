 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#181213',
    base01 = '#241e1f',
    base02 = '#2f2829',
    base03 = '#9f8c8e',
    base04 = '#d7c1c4',
    base05 = '#ecdfe0',
    base06 = '#ecdfe0',
    base07 = '#ecdfe0',
    base08 = '#ffb4ab',
    base09 = '#edbf73',
    base0A = '#e6bcc2',
    base0B = '#ffb2be',
    base0C = '#edbf73',
    base0D = '#ffb2be',
    base0E = '#e6bcc2',
    base0F = '#ffd9de',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#ecdfe0',          bg = '#181213' })
  hi('TelescopeBorder',         { fg = '#9f8c8e',             bg = '#181213' })
  hi('TelescopePromptNormal',   { fg = '#ecdfe0',          bg = '#181213' })
  hi('TelescopePromptBorder',   { fg = '#9f8c8e',             bg = '#181213' })
  hi('TelescopePromptPrefix',   { fg = '#ffb2be',             bg = '#181213' })
  hi('TelescopePromptCounter',  { fg = '#d7c1c4',  bg = '#181213' })
  hi('TelescopePromptTitle',    { fg = '#181213',             bg = '#ffb2be' })
  hi('TelescopePreviewTitle',   { fg = '#181213',             bg = '#e6bcc2' })
  hi('TelescopeResultsTitle',   { fg = '#181213',             bg = '#edbf73' })
  hi('TelescopeSelection',      { fg = '#ecdfe0',          bg = '#2f2829' })
  hi('TelescopeSelectionCaret', { fg = '#ffb2be',             bg = '#2f2829' })
  hi('TelescopeMatching',       { fg = '#ffb2be',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#ecdfe0',          bg = '#181213' })
  hi('MiniPickBorder',         { fg = '#9f8c8e',             bg = '#181213' })
  hi('MiniPickPrompt',   { fg = '#ecdfe0',          bg = '#181213' })
  hi('MiniPickPromptPrefix',   { fg = '#ffb2be',             bg = '#181213' })
  hi('MiniPickBorderText',    { fg = '#181213',             bg = '#ffb2be' })
  hi('MiniPickMatchCurrent',      { fg = '#ecdfe0',          bg = '#2f2829' })
  hi('MiniPickPromptCaret', { fg = '#ffb2be',             bg = '#2f2829' })
  hi('MiniPickMatchRanges',       { fg = '#ffb2be',             bold = true })
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
