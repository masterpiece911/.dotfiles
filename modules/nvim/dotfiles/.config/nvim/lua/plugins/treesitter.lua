return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- `main` is the Nvim 0.12+ rewrite; it does not support lazy-loading.
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      local ts = require("nvim-treesitter")
      ts.install({ "comment", "markdown", "markdown_inline", "regex", "lua", "vim", "vimdoc", "query" })

      local highlight_disabled = { latex = true }
      local indent_disabled = { yaml = true, python = true }

      local function attach(buf, lang)
        if highlight_disabled[lang] or vim.b[buf].bigfile_disable_treesitter then
          return
        end
        if not pcall(vim.treesitter.start, buf, lang) then
          return
        end
        if not indent_disabled[lang] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then
            return
          end
          if vim.list_contains(ts.get_installed(), lang) then
            attach(buf, lang)
          elseif vim.list_contains(ts.get_available(), lang) then
            ts.install(lang):await(function()
              if vim.api.nvim_buf_is_valid(buf) then
                attach(buf, lang)
              end
            end)
          end
        end,
      })

      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })
      vim.g.skip_ts_context_commentstring_module = true
    end,
  },
}
