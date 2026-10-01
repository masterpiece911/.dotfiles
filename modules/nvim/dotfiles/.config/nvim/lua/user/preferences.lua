-- Personal preferences ported from ~/.config/lvim/config.lua.
-- Keep LunarVim-like defaults elsewhere; put your taste here.

local M = {}

M.colorscheme = "nordic"

M.format_on_save = true

-- prettier (none-ls) — was lvim.lsp.null-ls.formatters
M.prettier_args = { "--no-semi", "--single-quote", "--jsx-single-quote" }

-- cucumber LSP — was lvim.lsp.manager.setup(...)
M.cucumber = {
  cmd = { vim.fn.expand("~/.local/bin/cucumber-language-server-18"), "--stdio" },
  settings = {
    cucumber = {
      features = { "**/features/**/*.feature" },
      glue = { "**/step-definitions/**/*.ts" },
    },
  },
}

-- telescope — was dropdown → center + wide horizontal
M.telescope = {
  layout_strategy = "horizontal",
  layout_config = {
    width = 0.90,
    height = 0.85,
    preview_cutoff = 40,
    prompt_position = "bottom",
  },
}

-- project.nvim — monorepo-friendly (git roots only)
M.project_patterns = { ".git" }

-- which-key Find group (replaces LunarVim's default <leader>f = find file)
M.find_mappings = {
  { "<leader>f", group = "Find" },
  { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Files" },
  { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
  { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
  { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
}

return M
