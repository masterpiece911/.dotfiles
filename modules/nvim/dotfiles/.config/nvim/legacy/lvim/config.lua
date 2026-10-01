-- Cleaned LunarVim entrypoint (legacy / deprecated — prefer modules/nvim).
-- Historical drop-in only; do not use for new setups.
--   cp -r legacy/lvim/* ~/.config/lvim/
--
-- Load order: options → plugins → lsp → keymaps

require("user.options")
require("user.plugins")
require("user.lsp")
require("user.keymaps")
