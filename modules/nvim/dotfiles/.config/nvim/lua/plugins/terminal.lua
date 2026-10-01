return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { [[<c-\>]], desc = "Toggle terminal" },
      { "<M-1>", desc = "Horizontal terminal" },
      { "<M-2>", desc = "Vertical terminal" },
      { "<M-3>", desc = "Float terminal" },
    },
    cmd = { "ToggleTerm", "TermExec", "ToggleTermToggleAll" },
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = false,
        direction = "float",
        close_on_exit = true,
        auto_scroll = true,
        -- Follow Neovim cwd (set when opening `nvim <dir>`) on next toggle
        autochdir = true,
        float_opts = {
          border = "curved",
          winblend = 0,
        },
      })

      local Terminal = require("toggleterm.terminal").Terminal

      local function set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = set_terminal_keymaps,
      })

      local horizontal = Terminal:new({ direction = "horizontal", size = function()
        return math.floor(vim.o.lines * 0.3)
      end })
      local vertical = Terminal:new({ direction = "vertical", size = function()
        return math.floor(vim.o.columns * 0.4)
      end })
      local float = Terminal:new({ direction = "float" })

      vim.keymap.set({ "n", "t" }, "<M-1>", function()
        horizontal:toggle()
      end, { desc = "Horizontal Terminal" })
      vim.keymap.set({ "n", "t" }, "<M-2>", function()
        vertical:toggle()
      end, { desc = "Vertical Terminal" })
      vim.keymap.set({ "n", "t" }, "<M-3>", function()
        float:toggle()
      end, { desc = "Float Terminal" })
    end,
  },
}
