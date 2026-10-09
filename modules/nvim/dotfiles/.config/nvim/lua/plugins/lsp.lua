-- LSP for Neovim 0.11+/0.12: vim.lsp.config + mason-lspconfig automatic_enable.
-- Keymaps attach via LspAttach (not the removed mason-lspconfig setup_handlers).

local function on_lsp_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if not client then
    return
  end

  local bufnr = ev.buf
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
      desc = desc,
    })
  end

  -- LunarVim-style buffer maps (nowait so `gr` does not wait for Neovim's gr*)
  map("n", "K", vim.lsp.buf.hover, "Show hover")
  map("n", "gd", vim.lsp.buf.definition, "Goto definition")
  map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
  map("n", "gr", vim.lsp.buf.references, "Goto references")
  map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
  map("n", "gs", vim.lsp.buf.signature_help, "Show signature help")
  map("n", "gl", function()
    local float = vim.diagnostic.config().float
    local config = type(float) == "table" and vim.deepcopy(float) or {}
    config.scope = "line"
    vim.diagnostic.open_float(config)
  end, "Show line diagnostics")

  -- Prefer our LunarVim maps over Neovim 0.11+ defaults (grn/grr/gra/…)
  for _, lhs in ipairs({ "grn", "grr", "gra", "gri", "gO" }) do
    pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })
  end

  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr(#{timeout_ms:500})"

  local supports_codelens = false
  if client.supports_method then
    -- Neovim 0.11+ prefers method-call form; fall back for older clients
    local ok, result = pcall(function()
      return client:supports_method("textDocument/codeLens", bufnr)
    end)
    supports_codelens = ok and result or false
  end
  if supports_codelens and vim.lsp.codelens.enable then
    vim.lsp.codelens.enable(true, { bufnr = bufnr })
  elseif supports_codelens then
    pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      buffer = bufnr,
      callback = function()
        pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
      end,
    })
  end
end

return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded" },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/schemastore.nvim",
      "folke/lazydev.nvim",
    },
    config = function()
      require("mason").setup({
        ui = { border = "rounded" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = on_lsp_attach,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Shared defaults for every server enabled via mason-lspconfig / vim.lsp.enable
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      })

      -- Same set you had under LunarVim's Mason install root
      require("mason-lspconfig").setup({
        automatic_enable = true,
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "jsonls",
          "yamlls",
          "html",
          "cssls",
          "tailwindcss",
          "pyright",
          "bashls",
          "dockerls",
          "vimls",
          "hls",
          "clangd",
          "lemminx",
          "texlab",
        },
      })

      -- Custom cucumber binary from the old LunarVim overlay
      local cucumber_cmd = vim.fn.expand("~/.local/bin/cucumber-language-server-18")
      if vim.fn.executable(cucumber_cmd) == 1 then
        vim.lsp.config("cucumber_language_server", {
          cmd = { cucumber_cmd, "--stdio" },
          capabilities = capabilities,
          settings = {
            cucumber = {
              features = { "**/features/**/*.feature" },
              glue = { "**/step-definitions/**/*.ts" },
            },
          },
        })
        vim.lsp.enable("cucumber_language_server")
      end

      -- Rounded floats (replaces deprecated vim.lsp.with handlers on 0.12)
      vim.o.winborder = "rounded"
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      require("null-ls").setup({
        border = "rounded",
        sources = require("user.lsp").none_ls_sources(),
      })
    end,
  },
}
