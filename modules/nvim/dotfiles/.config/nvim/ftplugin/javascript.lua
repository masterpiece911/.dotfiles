local group = vim.api.nvim_create_augroup("format_js", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.js",
  command = "silent! !npx prettier --write %",
})
