-- Extra plugins (nordic + quality-of-life)

lvim.plugins = {
  {
    "AlexvZyl/nordic.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nordic").load()
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  {
    "preservim/vim-pencil",
    config = function()
      vim.g["pencil#wrapModeDefault"] = "soft"
    end,
  },
  {
    "nvim-zh/colorful-winsep.nvim",
    event = { "WinLeave" },
    config = function()
      require("colorful-winsep").setup({
        border = "bold",
        animate = { enabled = "shift" },
        indicator_for_2wins = { position = "center" },
      })
    end,
  },
}
