local function on_attach(client, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
  end

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

  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr(#{timeout_ms:500})"

  if client.supports_method("textDocument/codeLens") then
    vim.lsp.codelens.refresh({ bufnr = bufnr })
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      buffer = bufnr,
      callback = function()
        vim.lsp.codelens.refresh({ bufnr = bufnr })
      end,
    })
  end
end

local function server_opts(extra)
  local capabilities = require("cmp_nvim_lsp").default_capabilities()
  return vim.tbl_deep_extend("force", {
    on_attach = on_attach,
    capabilities = capabilities,
  }, extra or {})
end

local function setup_lspconfig_server(name, extra)
  local lspconfig = require("lspconfig")
  if lspconfig[name] then
    lspconfig[name].setup(server_opts(extra))
  end
end

return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
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
      "folke/neodev.nvim",
    },
    config = function()
      pcall(require("neodev").setup, {})

      require("mason").setup({ ui = { border = "rounded" } })

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        automatic_installation = false,
        ensure_installed = {},
      })

      local custom = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
      }

      if mason_lspconfig.setup_handlers then
        mason_lspconfig.setup_handlers({
          function(server_name)
            setup_lspconfig_server(server_name, custom[server_name])
          end,
        })
      else
        local installed = {}
        if mason_lspconfig.get_installed_servers then
          installed = mason_lspconfig.get_installed_servers()
        end
        for _, server_name in ipairs(installed) do
          setup_lspconfig_server(server_name, custom[server_name])
        end
      end

      require("user.lsp").setup_cucumber(setup_lspconfig_server)

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
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
