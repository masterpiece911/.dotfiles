-- Formatters, linters, and language servers

local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
  {
    name = "prettier",
    args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
  },
})

local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
  { name = "eslint" },
})

local code_actions = require("lvim.lsp.null-ls.code_actions")
code_actions.setup({
  { name = "eslint" },
})

require("lvim.lsp.manager").setup("cucumber_language_server", {
  cmd = { vim.fn.expand("~/.local/bin/cucumber-language-server-18"), "--stdio" },
})
