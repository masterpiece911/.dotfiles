# Dotfiles

This repository contains a modular, stow-based dotfiles system with explicit installers per module, structured backups, safe dry-runs, and a flexible provisioning workflow.

It is designed for reproducibility, clarity, and safe re-runs on any machine.

---

## Features

* **Module-based structure** under `modules/<name>/`
* **Per-module installers** (optional, must be executable)
* **GNU Stow** for file placement under `$HOME`
* **Structured backups** to `~/.dotfiles_backup/<relative-path>`
* **Dry-run support** (`--dry-run`) for safe audits
* **Selective installs** (subset of modules or `--all`)
* **Separate bootstrap / install / update flows**
* **Fail-soft behavior** (summarizes failures, does not stop early)

---

## Repository Layout

```
.dotfiles/
  README.md
  AGENTS.md
  bootstrap.sh
  install.sh
  modules/
    <module>/
      install.sh       # optional, must be executable if present
      dotfiles/        # stowed into $HOME
```

---

## Usage

### 1. Bootstrap (first-time setup)

Clone or update the repo into `~/.dotfiles` and run `install.sh`:

```
~/.dotfiles/bootstrap.sh
```

Supports:

```
--no-install        # clone/update only
--branch <name>     # use a specific branch on first clone
-- <args>           # forward arguments to install.sh
```

Examples:

```
bootstrap.sh
bootstrap.sh --no-install
bootstrap.sh -- --dry-run --all
bootstrap.sh -- --installers-only lvim
```

---

## 2. Install (full provisioning)

The main provisioning script:

```
~/.dotfiles/install.sh
```

Options:

* `--all`
* Module names (e.g. `lvim zsh`)
* `--installers-only`
* `--no-installers`
* `--config-only`
* `--no-config`
* `--dry-run`

Examples:

```
install.sh --all
install.sh lvim zsh
install.sh --installers-only lvim
install.sh --dry-run --all
```

Behavior:

* Runs installers (unless disabled)
* Stows dotfiles (unless disabled)
* Skips stow if the installer failed
* Never stops early; prints a summary of failures
* Returns non-zero if any module failed

---

## Modules

Each module resides in `modules/<name>/` and may contain:

* `install.sh` — first-time setup logic
  Must be executable if present
* `dotfiles/` — file tree to be stowed into `$HOME`

Example:

```
modules/
  lvim/
    install.sh
    dotfiles/
      .config/lvim/...
```

Modules are independent; adding/removing modules is safe and incremental.

---

## Backups

Any real file (not a symlink) overwritten during stowing is moved to:

```
~/.dotfiles_backup/<relative-path>
```

Directory hierarchy is preserved.
Dry-run mode logs intended backups without touching disk.

---

## Dry-Run Mode

```
install.sh --dry-run [modules...]
```

* No installers run
* No stow
* No backups
* No filesystem changes
* Shows exactly what would happen

---

## Requirements

* Bash (`/usr/bin/env bash`)
* Git
* Curl
* GNU Stow
* A POSIX-like environment

---

## See Also

* [`AGENTS.md`](./AGENTS.md): automation-oriented rules and expectations for interacting with this repo.

