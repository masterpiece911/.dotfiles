-- Keymaps / which-key overlays

lvim.builtin.which_key.mappings["f"] = {
  name = "Find",
  f = { "<cmd>Telescope find_files<CR>", "Files" },
  g = { "<cmd>Telescope live_grep<CR>", "Grep" },
  b = { "<cmd>Telescope buffers<CR>", "Buffers" },
  h = { "<cmd>Telescope help_tags<CR>", "Help" },
}

vim.keymap.set("x", "p", '"_dP', { noremap = true, silent = true })
