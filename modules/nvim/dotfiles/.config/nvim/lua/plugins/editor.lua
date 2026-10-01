return {
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        padding = true,
        sticky = true,
        ignore = "^$",
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "lazy",
          "NvimTree",
          "Trouble",
          "text",
          "mason",
          "notify",
          "toggleterm",
        },
        buftypes = { "terminal", "nofile" },
      },
    },
  },
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        providers = { "lsp", "treesitter", "regex" },
        delay = 120,
        filetypes_denylist = {
          "dirvish",
          "fugitive",
          "alpha",
          "NvimTree",
          "lazy",
          "neogitstatus",
          "Trouble",
          "Outline",
          "spectre_panel",
          "toggleterm",
          "TelescopePrompt",
        },
        under_cursor = true,
      })
    end,
  },
  {
    "LunarVim/bigfile.nvim",
    event = { "FileReadPre", "BufReadPre" },
    opts = {
      filesize = 2,
      pattern = { "*" },
      features = {
        "indent_blankline",
        "illuminate",
        "lsp",
        "treesitter",
        "syntax",
        "matchparen",
        "vimopts",
        "filetype",
      },
    },
  },
}
