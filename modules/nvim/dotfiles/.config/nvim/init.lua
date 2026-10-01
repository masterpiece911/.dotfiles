-- LunarVim-inspired vanilla Neovim config

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("user")
require("config.lazy")
