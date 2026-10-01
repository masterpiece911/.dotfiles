local opt = vim.opt
local cache = vim.fn.stdpath("cache")
local undodir = cache .. "/undo"

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

opt.backup = false
opt.clipboard = "unnamedplus"
opt.cmdheight = 1
opt.completeopt = { "menuone", "noselect" }
opt.conceallevel = 0
opt.fileencoding = "utf-8"
opt.foldmethod = "manual"
opt.foldexpr = ""
opt.hidden = true
opt.hlsearch = true
opt.ignorecase = true
opt.mouse = "a"
opt.pumheight = 10
opt.showmode = false
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.termguicolors = true
opt.timeoutlen = 1000
opt.title = true
opt.undodir = undodir
opt.undofile = true
opt.updatetime = 100
opt.writebackup = false
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.cursorline = true
opt.number = true
opt.numberwidth = 4
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.showcmd = false
opt.ruler = false
opt.laststatus = 3

opt.spelllang:append("cjk")
opt.shortmess:append("c")
opt.shortmess:append("I")
opt.whichwrap:append("<,>,[,],h,l")

vim.filetype.add({
  extension = {
    tex = "tex",
    zir = "zir",
    cr = "crystal",
  },
  pattern = {
    ["[jt]sconfig.*.json"] = "jsonc",
  },
})

local diagnostic_config = {
  virtual_text = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

if vim.fn.has("nvim-0.10") == 1 then
  diagnostic_config.signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  }
else
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = sign.name })
  end
  diagnostic_config.signs = { active = true }
end

vim.diagnostic.config(diagnostic_config)
