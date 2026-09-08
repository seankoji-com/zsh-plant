# zsh-plant

Plant a new git worktree at `<root>/<default-path>/<name>` and step into it.

`plant` creates a worktree one level below the repo root — in a configurable
base directory (`.worktrees` by default) — then `cd`s into it. The branch
defaults to the worktree name (created from `HEAD` if missing; an existing
branch is checked out as-is). It is the *create* companion to
[zsh-worktree](https://github.com/seankoji-com/zsh-worktree)'s `wtree`, which
*jumps between* a repo's worktrees; `plant_list` lists what you've planted.

Logging goes through [`gum log`](https://github.com/charmbracelet/gum) (Charm's
level-styled structured logger from the CLI) when gum is installed, and falls
back to plain stderr otherwise.

## Installation

### Manual

Clone the repo and source the plugin from your `.zshrc`:

```
git clone https://github.com/seankoji-com/zsh-plant ~/.zsh/zsh-plant
echo 'source ~/.zsh/zsh-plant/zsh-plant.plugin.zsh' >> ~/.zshrc
```

### zinit

```
zinit light seankoji-com/zsh-plant
```

### oh-my-zsh

Clone into your custom plugins directory:

```
git clone https://github.com/seankoji-com/zsh-plant \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-plant
```

Then add it to the `plugins` array in your `.zshrc`:

```
plugins=(... zsh-plant)
```

[gum](https://github.com/charmbracelet/gum) is optional but recommended for the
styled log output.

## Usage

From inside a git repository:

```
plant myfeature
```

creates a worktree at `./.worktrees/myfeature` on a branch also named
`myfeature`, and `cd`s into it. `plant` with no name grows one whose name is a
minute-grained timestamp (`20260908-1410`), so rapid-fire scratch plants never
collide.

```
plant                          # .worktrees/20260908-1410 (timestamp name), then cd
plant --no-cd feat             # create without changing directory
plant feature backend          # worktree on existing branch 'backend'
plant -b backend feature       # flag-style equivalent
plant --no-cd -b main hotfix   # branch must exist; worktree named 'hotfix'
```

Existing branches are checked out as-is; a branch that doesn't exist yet is
created from `HEAD`. The command refuses to clobber an existing path.

`plant_list` is also exposed: it prints the names of this repo's planted
worktrees one per line, so you can reuse it in your own scripts.

## Configuration

Set before loading the plugin:

| Variable | Default | Description |
| --- | --- | --- |
| `ZSH_PLANT_PATH` | `.worktrees` | Base directory under the repo root where worktrees grow. Leading `/` is stripped, so `/scratch` and `scratch` are equivalent. |

## License

MIT — see [LICENSE](/LICENSE).
