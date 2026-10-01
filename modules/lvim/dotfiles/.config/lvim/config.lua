-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

lvim.plugins = {
  {
    'AlexvZyl/nordic.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('nordic').load()
    end
  },
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end
  },
  {
    "preservim/vim-pencil",
    config = function()
      vim.g["pencil#wrapModeDefault"] = "soft"
    end
  },
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   event = "InsertEnter",
  --   dependencies = { "zbirenbaum/copilot.lua" },
  --   config = function()
  --     local node_path = "/home/sahi_no/.nvm/versions/node/v22.18.0/bin/node"

  --     vim.defer_fn(function()
  --       require("copilot").setup({
  --         copilot_node_command = node_path
  --       })                             -- https://github.com/zbirenbaum/copilot.lua/blob/master/README.md#setup-and-configuration
  --       require("copilot_cmp").setup() -- https://github.com/zbirenbaum/copilot-cmp/blob/master/README.md#configuration
  --     end, 100)
  --   end,
  -- },
  {
    'nvim-zh/colorful-winsep.nvim',
    config = function()
      require('colorful-winsep').setup {
        border = "bold",
        animate = {
          enabled = "shift"
        },
        indicator_for_2wins = {
          position = "center",
        }
      }
    end,
    event = { "WinLeave" },
  }
}

lvim.colorscheme = "nordic"

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    name = "prettier",
    args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
  }
}
local diagnostics = require "lvim.lsp.null-ls.linters"
diagnostics.setup {
  {
    name = "eslint",
  }
}
local code_actions = require "lvim.lsp.null-ls.code_actions"
code_actions.setup {
  {
    name = "eslint",
  }
}

require("lvim.lsp.manager").setup("cucumber_language_server", {
  cmd = { "/home/sahi_no/.local/bin/cucumber-language-server-18", "--stdio" },
})

lvim.builtin.which_key.mappings["f"] = {
  name = " Find",
  f = { "<cmd>Telescope find_files<CR>", "Files" },
  g = { "<cmd>Telescope live_grep<CR>", "Grep" },
  b = { "<cmd>Telescope buffers<CR>", "Buffers" },
  h = { "<cmd>Telescope help_tags<CR>", "Help" },
}

vim.keymap.set("x", "p", '"_dP', { noremap = true, silent = true })

-- ~/.config/lvim/config.lua

-- 1) disable the dropdown theme
lvim.builtin.telescope.theme = "center"

-- 2) force a wide, side‑by‑side layout everywhere
lvim.builtin.telescope.defaults.layout_strategy = "horizontal"
lvim.builtin.telescope.defaults.layout_config = {
  width           = 0.90,
  height          = 0.85,
  preview_cutoff  = 40,
  prompt_position = "bottom",
}

-- Format on save
lvim.format_on_save.enabled = true

-- lvim uses https://github.com/ahmedkhalf/project.nvim
-- which aggressively cds when it detects a package.json
-- this is not nice when in monorepos, so we tell it to
-- only detect git directories as projects
lvim.builtin.project.patterns = { ".git" }
