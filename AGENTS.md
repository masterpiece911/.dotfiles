# AGENTS.md

This repository contains a modular dotfiles system with three primary entry points and a well-defined module structure. Automated agents should follow these rules when interacting with it.

---

## 1. Repository Structure

```
.dotfiles/
    AGENTS.md
    bootstrap.sh
    install.sh
    update.sh # Optional, wrapper around install.sh
    modules/
        <module>/
            install.sh # optional; must be executable if present
            dotfiles/ # mirrored into $HOME via stow
```

Each module is self-contained.

---

## 2. Scripts

### bootstrap.sh
- Ensures the repository exists at `~/.dotfiles`
- Clones or updates it
- Calls `install.sh` unless `--no-install` is given
- Supports passing arguments to `install.sh` using `--`

Intended for new machine setup.

### install.sh
- Main provisioning script
- Supports:
  - `--all`
  - Module selection
  - `--installers-only`
  - `--no-installers`
  - `--config-only`
  - `--no-config`
  - `--dry-run`
- Runs module installers unless disabled
- Stows configs unless disabled
- Does not stop on first error; summarizes failures at the end

Intended for initial provisioning and module-level updates.

### update.sh
- Runs `install.sh --config-only --all`
- No installers run

Intended for daily syncing of dotfiles.

---

## 3. Module Rules

### Installer (`modules/<name>/install.sh`)
- Optional
- **If the file exists, it must be executable**
- Run only when installers are enabled
- If installer fails:
  - The module is marked as failed
  - Its config is **not** stowed
- Installers must be idempotent or at least safe to re-run

### Dotfiles (`modules/<name>/dotfiles/`)
- Stowed into `$HOME` via GNU Stow
- Must mirror the exact target directory structure
- Backups go to:
  `~/.dotfiles_backup/<relative-path>`
  with directory structure preserved

---

## 4. Execution Rules

### Agents should:
- Use `bootstrap.sh` for initial setup
- Use `install.sh` for provisioning modules
- Use `update.sh` for configuration updates
- Pass module lists and flags only to `install.sh`
- Check installer executability before running

### Agents should not:
- Edit files directly in `$HOME`
- Run module installers outside `install.sh`
- Assume every module has both installer and dotfiles
- Overwrite `~/.dotfiles` if it exists and is not a git repo

---

## 5. Error Handling

- `install.sh` processes all modules even if some fail
- Installer failures prevent stow for that module
- All failures are summarized at the end
- A non-zero exit code indicates at least one failure

---

## 6. Dry-Run Mode

`install.sh --dry-run` guarantees:
- No filesystem changes
- No installers run
- No downloads or symlinks created
- A full preview of intended operations

Useful for planning and validation.

---

## 7. Environment Expectations

- Repository lives at `~/.dotfiles`
- Bash available at `/usr/bin/env bash`
- Git and curl available for bootstrap
- `$HOME/.local/bin` and `$HOME/.dotfiles_backup` may be created as needed

