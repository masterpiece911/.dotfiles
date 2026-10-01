# Neovim config

Vanilla Neovim configuration ported from LunarVim 1.4 plus former
`~/.config/lvim` overlays. Managed by the `nvim` dotfiles module and stowed
to `~/.config/nvim`.

The `lvim` module is deprecated; use this config via `nvim`.

## Requirements

- **Neovim 0.10+** (0.12.x via the module installer)
- `git`, `make` (for telescope-fzf-native), `rg` (ripgrep), a Nerd Font
- Optional: `lazygit`, `prettier` / `eslint`, `fourmolu`, cucumber language server

## Launch

```bash
nvim
```

Plugins install via lazy.nvim on first launch. Run `:Mason` for LSPs.

## What was ported

### LunarVim core (behavioral)

| Area | Status |
|------|--------|
| Space leader + which-key menus | Yes (`b/d/g/l/p/s/T`, save/quit/explorer/…) |
| Telescope, Treesitter, nvim-cmp, LuaSnip | Yes |
| Mason + lspconfig + none-ls | Yes |
| NvimTree, bufferline, lualine, alpha | Yes |
| Gitsigns, project.nvim, Comment, autopairs | Yes |
| ToggleTerm (`Ctrl-\`, `Alt-1/2/3`), lazygit | Yes |
| DAP + dap-ui | Yes |
| Illuminate, indent-blankline, bigfile | Yes |
| Format on save | Yes (enabled, like your overlay) |
| Window / line move / indent keymaps | Yes |
| LunarVim `L` menu / Lvim* commands | Intentionally omitted |

### Your overlays

- nordic colorscheme
- nvim-surround, vim-pencil, colorful-winsep
- Prettier (`--no-semi --single-quote --jsx-single-quote`) + ESLint via none-ls
- Cucumber LSP (`~/.local/bin/cucumber-language-server-18`)
- Telescope horizontal / wide layout
- `<leader>f` Find group (files/grep/buffers/help)
- Paste without yank (`x` mode `p`)
- project.nvim patterns = `{ ".git" }` only
- ftplugin formatters (fourmolu / prettier) and `useStyles` luasnip

## Layout

```
nvim/
  init.lua
  lua/config/       LunarVim-like core (options, keymaps, autocmds, lazy)
  lua/plugins/      Core plugin specs
  lua/user/         YOUR overlays (edit here)
    preferences.lua   single source of truth for personal knobs
    keymaps.lua
    plugins.lua
    lsp.lua
  ftplugin/         format-on-write helpers
  luasnippets/
  lsp-settings/
  legacy/lvim/      cleaned modular LunarVim config (drop-in, not active)
```

Personal taste (colorscheme, prettier args, cucumber, telescope layout, Find
maps, project patterns, format-on-save) lives in `lua/user/preferences.lua`.

## Notes

- which-key uses the modern `wk.add()` API (not LunarVim’s old `register`).
- indent-blankline uses the `ibl` (v3) API.
- ESLint null-ls builtins live in `none-ls-extras`; prettier stays in none-ls.
- Copilot block from your old config is omitted until you want it.
- Old pre-migration `~/.config/nvim` was backed up as `~/.config/nvim.bak-*`.
