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

-- Terminal window navigation is set per-buffer in plugins/terminal.lua
-- (skipped for lazygit and other TUIs that need those keys).

-- Better indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Navigate cmdline completion
map("c", "<C-j>", 'pumvisible() ? "\\<C-n>" : "\\<C-j>"', { expr = true, noremap = true })
map("c", "<C-k>", 'pumvisible() ? "\\<C-p>" : "\\<C-k>"', { expr = true, noremap = true })

--- Close buffer without closing the window (LunarVim BufferKill)
vim.api.nvim_create_user_command("BufferKill", function(args)
  local bufnr = tonumber(args.args) or vim.api.nvim_get_current_buf()
  local bufinfo = vim.fn.getbufinfo(bufnr)[1]
  if bufinfo == nil then
    return
  end

  if vim.bo[bufnr].modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(bufinfo.name), "&Yes\n&No\n&Cancel")
    if choice == 1 then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("write")
      end)
    elseif choice == 0 or choice == 3 then
      return
    end
  end

  local replacement = vim.fn.bufnr("#")
  if replacement == bufnr or not vim.api.nvim_buf_is_valid(replacement) or not vim.bo[replacement].buflisted then
    replacement = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= bufnr and vim.bo[buf].buflisted then
        replacement = buf
        break
      end
    end
  end

  -- Replace the buffer in every window so deleting it preserves the layout.
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    replacement = replacement or vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win, replacement)
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end, { nargs = "?" })
