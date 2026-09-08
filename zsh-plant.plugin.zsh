# zsh-plant — plant a new git worktree at $ROOT/$ZSH_PLANT_PATH/<name>.
#
# Creates a worktree under a configurable subdirectory of the repo root
# (default `.worktrees`) and cd's into it. The worktree branch defaults to
# <name> — created from HEAD if it doesn't exist, or checked out as-is when
# it does. Logging goes through `gum log` (Charm's level-styled structured
# logger from the CLI) when gum is installed; otherwise it falls back to
# plain stderr, so the plugin still works on machines without gum.
#
# plant_list is the inverse companion to zsh-worktree's `wtree`: wtree jumps
# between all of a repo's worktrees, plant_list lists just the ones planted
# here.
#
# Configure before loading:
#   ZSH_PLANT_PATH   subdirectory under the repo root where worktrees grow
#                    (default .worktrees)
#
# Usage:
#   plant [--no-cd] <name> [<branch>]
#   plant -b <branch> <name>     flag-style alias of the above
#   plant [--no-cd]              name = minute-grained timestamp, branch = name

: ${ZSH_PLANT_PATH=.worktrees}

# Emit a log line: `gum log` when available, plain stderr otherwise.
# $1: level (debug|info|warn|error); $2: message.
_plant_log() {
  local level="$1" msg="$2"
  if (( $+commands[gum] )); then
    command gum log --level "$level" --time="" "$msg"
  else
    print -u2 "[${(U)level}] $msg"
  fi
}

# Print the names of this repo's planted worktrees, one per line. Returns
# failure outside a git repository.
plant_list() {
  command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  local root base
  root=$(command git rev-parse --show-toplevel) || return 1
  base="${ZSH_PLANT_PATH#/}"
  command git worktree list --porcelain 2>/dev/null | awk -v pre="$root/$base/" '
    /^worktree / {
      p = substr($0, 10)
      if (index(p, pre) == 1) print substr(p, length(pre) + 1)
    }
  '
}

plant() {
  local no_cd=0 name branch
  local -a pos
  pos=()
  while (( $# )); do
    case "$1" in
      --no-cd) no_cd=1 ;;
      -b|--branch)
        shift
        if (( $# == 0 )); then
          _plant_log error "plant: -b/--branch requires a branch name"
          return 2
        fi
        branch=$1
        ;;
      -h|--help)
        print -r -- \
          "plant: plant a git worktree at <root>/${ZSH_PLANT_PATH#/}/<name>" \
          "Usage: plant [--no-cd] <name> [<branch>]" \
          "       plant -b <branch> <name>" \
          "  --no-cd   create the worktree without cd-ing into it" \
          "  <name>    worktree name; defaults to a minute timestamp" \
          "  <branch>  branch to check out; defaults to <name>. Created from" \
          "            HEAD if missing, checked out as-is if it exists." \
          "Set ZSH_PLANT_PATH (default .worktrees) before loading to move the base dir."
        return 0
        ;;
      --)
        shift
        while (( $# )); do pos+=("$1"); shift; done
        ;;
      -*)
        _plant_log error "plant: unknown option: $1"
        return 2
        ;;
      *)
        pos+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#pos} > 0 )); then
    name=$pos[1]
    (( ${#pos} > 1 )) && branch=$pos[2]
    if (( ${#pos} > 2 )); then
      _plant_log error "plant: unexpected argument: $pos[3]"
      return 2
    fi
  fi

  root=$(command git rev-parse --show-toplevel 2>/dev/null) || {
    _plant_log error "plant: not inside a git repository"
    return 1
  }

  if [[ -z "$name" ]]; then
    name=$(command date +%Y%m%d-%H%M)
    _plant_log debug "no name given; using timestamp '$name'"
  fi
  : ${branch:=$name}

  target="$root/${ZSH_PLANT_PATH#/}/$name"
  if [[ -e "$target" ]]; then
    _plant_log error "plant: path already exists: $target"
    return 1
  fi

  _plant_log info "planting '$name' at $target"

  # Existing branch → check it out as-is; otherwise create a fresh one from
  # HEAD. -q keeps git's "Preparing worktree" chatter out of the output.
  if command git rev-parse --verify "refs/heads/$branch" >/dev/null 2>&1; then
    command git worktree add -q -- "$target" "$branch"
  else
    command git worktree add -q -b "$branch" -- "$target"
  fi || {
    _plant_log error "plant: could not create worktree '$name'"
    return 1
  }

  _plant_log info "planted '$name' in $target"
  (( no_cd )) || {
    builtin cd -- "$target" || {
      _plant_log error "plant: could not cd into $target"
      return 1
    }
  }
}
