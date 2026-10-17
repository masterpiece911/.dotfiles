-- LSP / null-ls pieces from the LunarVim overlay.

local prefs = require("user.preferences")

local M = {}

function M.none_ls_sources()
  local null_ls = require("null-ls")
  local resolve_node_command = require("null-ls.helpers.command_resolver").from_node_modules()
  local function available_node_command(params, done)
    resolve_node_command(params, function(command)
      done(command and vim.fn.executable(command) == 1 and command or nil)
    end)
  end
  local sources = {
    null_ls.builtins.formatting.prettier.with({
      extra_args = prefs.prettier_args,
      dynamic_command = available_node_command,
    }),
  }

  local eslint_diag_ok, eslint_diag = pcall(require, "none-ls.diagnostics.eslint")
  if eslint_diag_ok then
    table.insert(sources, eslint_diag.with({ dynamic_command = available_node_command }))
  end

  local eslint_ca_ok, eslint_ca = pcall(require, "none-ls.code_actions.eslint")
  if eslint_ca_ok then
    table.insert(sources, eslint_ca.with({ dynamic_command = available_node_command }))
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
