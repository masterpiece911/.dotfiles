local group = vim.api.nvim_create_augroup("format_haskell", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.hs",
  command = "silent! !fourmolu -i %"
})
