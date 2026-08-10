#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
module="${repo_root}/modules/worktrunk"
skill="${module}/dotfiles/.cursor/skills/worktrunk-worktrees/SKILL.md"
config_dir="${module}/dotfiles/.config/worktrunk"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

test -x "${module}/install.sh"
bash -n "${module}/install.sh"

wt --config "${config_dir}/config.toml" config show >/dev/null
grep -Fq 'worktree-path = "~/projects/worktrees/{{ repo }}/{{ branch | sanitize }}"' \
  "${config_dir}/config.toml"
grep -Fq 'copy = "wt step copy-ignored"' "${config_dir}/config.toml"

PYTHONPYCACHEPREFIX="${tmpdir}/pycache" \
  python3 -m py_compile \
  "${config_dir}/strip-lockfile-prompt.py" \
  "${config_dir}/plain-commit-message.py"

test -f "${skill}"
grep -Fq "wt switch --create" "${skill}"
grep -Fq "move_agent_to_root" "${skill}"
grep -Fq "~/projects/worktrees" "${skill}"

# Local Cursor plugins are not loaded on this setup (userLocal=false).
test ! -e "${module}/dotfiles/.cursor/plugins"

dry_run_output="$("${repo_root}/install.sh" --dry-run worktrunk 2>&1)"
grep -Fq "Would run installer for worktrunk" <<<"${dry_run_output}"
grep -Fq "Would stow config for worktrunk" <<<"${dry_run_output}"

fixture_repo="${tmpdir}/dotfiles"
fixture_home="${tmpdir}/home"
mkdir -p "${fixture_repo}/modules/worktrunk" "${fixture_home}"
cp "${repo_root}/install.sh" "${fixture_repo}/install.sh"
cp -R "${module}/dotfiles" "${fixture_repo}/modules/worktrunk/dotfiles"

HOME="${fixture_home}" "${fixture_repo}/install.sh" --no-installers worktrunk >/dev/null
HOME="${fixture_home}" "${fixture_repo}/install.sh" --no-installers worktrunk >/dev/null
test -f "${fixture_repo}/modules/worktrunk/dotfiles/.config/worktrunk/config.toml"
test "$(readlink -f "${fixture_home}/.config/worktrunk/config.toml")" = \
  "${fixture_repo}/modules/worktrunk/dotfiles/.config/worktrunk/config.toml"
test "$(readlink -f "${fixture_home}/.cursor/skills/worktrunk-worktrees/SKILL.md")" = \
  "${fixture_repo}/modules/worktrunk/dotfiles/.cursor/skills/worktrunk-worktrees/SKILL.md"

printf 'worktrunk module validation passed\n'
