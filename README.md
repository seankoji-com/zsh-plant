# zsh-plant

Create a git worktree at `<repo-root>/.worktrees/<name>` and `cd` into it.

Companion to [zsh-worktree](https://github.com/seankoji-com/zsh-worktree), which navigates between existing worktrees. `plant` is the creation side: one command to add the worktree (creating the branch if needed) and land you in it.

## Installation

### Manual

```zsh
git clone https://github.com/seankoji-com/zsh-plant ~/.zsh/zsh-plant
echo 'source ~/.zsh/zsh-plant/zsh-plant.plugin.zsh' >> ~/.zshrc
```

### zinit

```zsh
zinit light seankoji-com/zsh-plant
```

### oh-my-zsh

Clone into your custom plugins directory:

```zsh
git clone https://github.com/seankoji-com/zsh-plant \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-plant
```

Then add `zsh-plant` to the `plugins` array in your `.zshrc`.

## Usage

From inside a git repository:

```zsh
# Create .worktrees/my-feature, branching from HEAD as "my-feature", then cd in:
plant my-feature

# Create .worktrees/wt, checking out existing branch "feat/thing":
plant wt feat/thing

# Flag style — equivalent to the above:
plant -b feat/thing wt
```

The worktree is always created at `<repo-root>/.worktrees/<name>`. If the branch already exists it is checked out; otherwise it is created from `HEAD`.

After planting, use `wtree` (from `zsh-worktree`) to jump back or to any other worktree.

## Errors

| Situation | Message |
|---|---|
| Not inside a git repo | `plant: not inside a git repository` |
| Destination already exists | `plant: path already exists: …` |
| `git worktree add` fails | git's own error message |

## License

MIT — see [LICENSE](LICENSE).
