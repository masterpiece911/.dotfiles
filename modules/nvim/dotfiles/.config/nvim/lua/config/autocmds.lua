local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local prefs = require("user.preferences")

autocmd("TextYankPost", {
  group = augroup("_general_settings", { clear = true }),
  pattern = "*",
  desc = "Highlight text on yank",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 100 })
  end,
})

autocmd("FileType", {
  group = augroup("_buffer_mappings", { clear = true }),
  pattern = {
    "qf",
    "help",
    "man",
    "lspinfo",
    "null-ls-info",
    "tsplayground",
    "checkhealth",
  },
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
    vim.opt_local.buflisted = false
  end,
})

autocmd("VimResized", {
  group = augroup("_auto_resize", { clear = true }),
  pattern = "*",
  command = "tabdo wincmd =",
})

autocmd("FileType", {
  group = augroup("_filetype_settings", { clear = true }),
  pattern = "alpha",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- `nvim <directory>`: cd there, open the file tree, keep terminals on that cwd
autocmd("VimEnter", {
  group = augroup("_open_directory", { clear = true }),
  callback = function()
    local arg = vim.fn.argv(0)
    if arg == nil or arg == "" then
      return
    end

    local path = vim.fn.fnamemodify(arg, ":p")
    if vim.fn.isdirectory(path) == 0 then
      return
    end

    vim.cmd.cd(path)

    vim.schedule(function()
      -- Lazy-loads nvim-tree via its command; rooted at cwd via sync_root_with_cwd
      pcall(vim.cmd.NvimTreeOpen)
      pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "DirOpened" })
    end)
  end,
})

if prefs.format_on_save then
  autocmd("BufWritePre", {
    group = augroup("lsp_format_on_save", { clear = true }),
    pattern = "*",
    callback = function(args)
      local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
      local clients = get_clients({ bufnr = args.buf })
      if #clients == 0 then
        return
      end
      vim.lsp.buf.format({
        bufnr = args.buf,
        timeout_ms = 1000,
        filter = function(client)
          return client.name ~= "tsserver"
            and client.name ~= "typescript-tools"
            and client.name ~= "ts_ls"
            and client.name ~= "lua_ls"
        end,
      })
    end,
  })
end
