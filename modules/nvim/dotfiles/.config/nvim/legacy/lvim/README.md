# Cleaned LunarVim config (legacy / not active)

**Deprecated.** Prefer the active Neovim config under `~/.config/nvim`
(`modules/nvim`). This tree is kept only as a historical drop-in for LunarVim.

This is a modular rewrite of the old monolithic `~/.config/lvim/config.lua`.
It is **not** active until you copy it over (not recommended).

## Apply to live LunarVim (legacy only)

```bash
# Backup first
cp -a ~/.config/lvim ~/.config/lvim.bak.$(date +%Y%m%d)

# Copy entry + lua/user modules (keeps your existing ftplugin/luasnippets/lsp-settings)
cp ~/.config/nvim/legacy/lvim/config.lua ~/.config/lvim/config.lua
cp -r ~/.config/nvim/legacy/lvim/lua ~/.config/lvim/
```

Or, if you prefer the deprecated dotfiles module:

```bash
# into modules/lvim/dotfiles/.config/lvim/ — then re-stow
```

## Layout

| File | Responsibility |
|------|----------------|
| `config.lua` | Thin require list |
| `lua/user/options.lua` | colorscheme, format-on-save, telescope, project |
| `lua/user/plugins.lua` | extra plugins only |
| `lua/user/lsp.lua` | prettier / eslint / cucumber |
| `lua/user/keymaps.lua` | Find group + paste-without-yank |

Removed: stock LunarVim comment boilerplate, dead path comment, large commented-out Copilot block (re-add in `plugins.lua` if needed), hardcoded `/home/sahi_no/...` (uses `~` expand).
