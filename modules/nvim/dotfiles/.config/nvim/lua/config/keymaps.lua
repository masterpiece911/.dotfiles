local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better window movement
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
map("n", "<C-Up>", ":resize -2<CR>", opts)
map("n", "<C-Down>", ":resize +2<CR>", opts)
map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Move current line / block
map("n", "<A-j>", ":m .+1<CR>==", opts)
map("n", "<A-k>", ":m .-2<CR>==", opts)
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)
map("x", "<A-j>", ":m '>+1<CR>gv-gv", opts)
map("x", "<A-k>", ":m '<-2<CR>gv-gv", opts)

-- QuickFix
map("n", "]q", ":cnext<CR>", opts)
map("n", "[q", ":cprev<CR>", opts)
map("n", "<C-q>", function()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd("cclose")
      return
    end
  end
  vim.cmd("copen")
end, opts)

-- Terminal window navigation
map("t", "<C-h>", "<C-\\><C-N><C-w>h", { silent = true })
map("t", "<C-j>", "<C-\\><C-N><C-w>j", { silent = true })
map("t", "<C-k>", "<C-\\><C-N><C-w>k", { silent = true })
map("t", "<C-l>", "<C-\\><C-N><C-w>l", { silent = true })

-- Better indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Navigate cmdline completion
map("c", "<C-j>", 'pumvisible() ? "\\<C-n>" : "\\<C-j>"', { expr = true, noremap = true })
map("c", "<C-k>", 'pumvisible() ? "\\<C-p>" : "\\<C-k>"', { expr = true, noremap = true })

--- Close buffer without closing the window (LunarVim BufferKill)
vim.api.nvim_create_user_command("BufferKill", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufinfo = vim.fn.getbufinfo(bufnr)[1]
  if bufinfo == nil then
    return
  end

  if vim.bo[bufnr].modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(bufinfo.name), "&Yes\n&No\n&Cancel")
    if choice == 1 then
      vim.cmd("write")
    elseif choice == 0 or choice == 3 then
      return
    end
  end

  local alt = vim.fn.bufnr("#")
  if alt > 0 and vim.api.nvim_buf_is_loaded(alt) then
    vim.cmd("buffer #")
  else
    vim.cmd("bprevious")
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    pcall(vim.cmd, "bdelete! " .. bufnr)
  end
end, {})
