if not require("user.preferences").format_on_save then
  return
end

local group = vim.api.nvim_create_augroup("format_haskell", { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  buffer = 0,
  callback = function(args)
    if vim.fn.executable("fourmolu") ~= 1 then
      return
    end
    local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
    local formatted = vim.fn.systemlist({ "fourmolu", "--stdin-input-file", vim.api.nvim_buf_get_name(args.buf) }, lines)
    if vim.v.shell_error ~= 0 then
      vim.notify("Fourmolu: " .. table.concat(formatted, "\n"), vim.log.levels.WARN)
      return
    end
    if not vim.deep_equal(lines, formatted) then
      vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, formatted)
    end
  end,
})
