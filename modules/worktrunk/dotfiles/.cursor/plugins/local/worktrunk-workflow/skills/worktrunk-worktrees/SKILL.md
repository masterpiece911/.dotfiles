---
name: worktrunk-worktrees
description: Creates or selects Worktrunk-managed git worktrees before feature, bugfix, refactor, or other branch implementation. Use before editing files for branch-scoped work, when starting work on a branch, or when the user asks for an isolated worktree.
---

# Worktrunk Worktrees

Perform branch implementation only in a Worktrunk-managed linked worktree.
Read-only investigation and planning may happen before isolation.

## 1. Detect existing isolation

From the repository root, inspect Git without changing files:

```bash
git_dir="$(cd "$(git rev-parse --git-dir)" && pwd -P)"
git_common="$(cd "$(git rev-parse --git-common-dir)" && pwd -P)"
superproject="$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)"
branch="$(git branch --show-current)"
```

If `git_dir` differs from `git_common` and `superproject` is empty, the current
checkout is already a linked worktree. Do not create a nested worktree. Confirm
the current path and branch, then continue there.

A submodule is not a linked worktree. Continue to the next section when
`superproject` is non-empty.

## 2. Choose the branch

- Use a branch name the user supplied.
- Otherwise, ask the user to confirm a concise branch name before creating it.
- Use the user-specified base when provided; otherwise let Worktrunk use the
  repository's default branch.
- Require `wt` on `PATH`. If it is missing, stop and explain that the dotfiles
  `worktrunk` module must be installed.

## 3. Create or select with Worktrunk

If the branch already exists locally or remotely, select it:

```bash
wt switch "$branch" --format json --no-cd
```

For a new branch, create it:

```bash
wt switch --create "$branch" --format json --no-cd
```

When a base was explicitly requested, append `--base "$base"` to the create
command. Read the absolute `path` from Worktrunk's JSON response.

Do not use `git worktree add`, Cursor-native worktree creation, or any other
worktree-creation mechanism. Worktrunk owns creation and selection.

## 4. Move Cursor before editing

Immediately call the `cursor-app-control` MCP tool `move_agent_to_root` with
the absolute Worktrunk `path`. This relocation is mandatory because changing a
shell's directory does not move Cursor's workspace.

If `move_agent_to_root` is unavailable or fails, stop without editing the
primary checkout. Report the worktree path so the user can reopen it.

After moving, verify:

```bash
git rev-parse --show-toplevel
git branch --show-current
```

Only then install project dependencies, run the repository's baseline checks,
and begin implementation.
