-- Editor / LunarVim builtin toggles

lvim.colorscheme = "nordic"
lvim.format_on_save.enabled = true

-- project.nvim aggressively cds on package.json; git-only is safer in monorepos
lvim.builtin.project.patterns = { ".git" }

-- Wide horizontal Telescope (not the default dropdown)
lvim.builtin.telescope.theme = "center"
lvim.builtin.telescope.defaults.layout_strategy = "horizontal"
lvim.builtin.telescope.defaults.layout_config = {
  width = 0.90,
  height = 0.85,
  preview_cutoff = 40,
  prompt_position = "bottom",
}
