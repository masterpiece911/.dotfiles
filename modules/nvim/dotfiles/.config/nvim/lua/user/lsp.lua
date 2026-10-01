-- LSP / null-ls pieces from the LunarVim overlay.

local prefs = require("user.preferences")

local M = {}

function M.none_ls_sources()
  local null_ls = require("null-ls")
  local sources = {
    null_ls.builtins.formatting.prettier.with({
      extra_args = prefs.prettier_args,
    }),
  }

  local eslint_diag_ok, eslint_diag = pcall(require, "none-ls.diagnostics.eslint")
  if eslint_diag_ok then
    table.insert(sources, eslint_diag)
  end

  local eslint_ca_ok, eslint_ca = pcall(require, "none-ls.code_actions.eslint")
  if eslint_ca_ok then
    table.insert(sources, eslint_ca)
  end

  return sources
end

function M.setup_cucumber(setup_server)
  local cmd = prefs.cucumber.cmd
  if vim.fn.executable(cmd[1]) ~= 1 then
    return
  end
  setup_server("cucumber_language_server", {
    cmd = cmd,
    settings = prefs.cucumber.settings,
  })
end

return M
