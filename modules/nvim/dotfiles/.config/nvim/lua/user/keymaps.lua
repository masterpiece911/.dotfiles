-- Personal keymaps from the LunarVim overlay.

local map = vim.keymap.set

-- Paste without yanking the replaced text
map("x", "p", '"_dP', { noremap = true, silent = true })
