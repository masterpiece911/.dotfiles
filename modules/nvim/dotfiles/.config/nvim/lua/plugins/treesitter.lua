return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Default branch is now `main` (Nvim 0.12+ rewrite without configs module).
    -- Pin `master` for LunarVim-era API + current AppImage (0.9.x / 0.10 / 0.11).
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "comment", "markdown_inline", "regex", "lua", "vim", "vimdoc", "query" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          disable = function(lang, buf)
            if vim.tbl_contains({ "latex" }, lang) then
              return true
            end
            local ok, big = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
            return ok and big
          end,
        },
        indent = { enable = true, disable = { "yaml", "python" } },
      })

      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
      vim.g.skip_ts_context_commentstring_module = true
    end,
  },
}
