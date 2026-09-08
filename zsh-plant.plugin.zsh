# zsh-plant — create a git worktree at <root>/.worktrees/<name> and cd into it.
#
# Companion to zsh-worktree (which navigates between existing worktrees).
# plant creates the worktree, optionally creating the branch, then lands you
# in it.
#
# Usage:
#   plant <name>            — new worktree at .worktrees/<name>, branch <name>
#                            (branch created from HEAD if it doesn't exist)
#   plant <name> <branch>   — same but tracks an existing branch by that name
#   plant -b <branch> <name> — alias for the two-arg form (flag style)
#
# The worktree is always placed at <repo-root>/.worktrees/<name>.

plant() {
  # ── option parsing ────────────────────────────────────────────────────────
  local name branch existing=0
  local -a git_args

  while (( $# )); do
    case $1 in
      -b|--branch)
        shift
        branch=$1
        shift
        ;;
      -h|--help)
        print "Usage: plant <name> [<branch>]"
        print "       plant -b <branch> <name>"
        print ""
        print "Creates a git worktree at <repo-root>/.worktrees/<name> and cd's into it."
        print "If <branch> is omitted the worktree branch defaults to <name>."
        print "An existing branch is checked out as-is; a new one is created from HEAD."
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        print -u2 "plant: unknown option: $1"
        return 1
        ;;
      *)
        if [[ -z $name ]]; then
          name=$1
        elif [[ -z $branch ]]; then
          branch=$1
        else
          print -u2 "plant: unexpected argument: $1"
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z $name ]]; then
    print -u2 "plant: a worktree name is required"
    print -u2 "Usage: plant <name> [<branch>]"
    return 1
  fi

  # Default branch to the name when not specified.
  : ${branch:=$name}

  # ── git context ──────────────────────────────────────────────────────────
  local root
  root=$(command git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 "plant: not inside a git repository"
    return 1
  }

  local dest="$root/.worktrees/$name"

  if [[ -e $dest ]]; then
    print -u2 "plant: path already exists: $dest"
    return 1
  fi

  # ── create worktree ───────────────────────────────────────────────────────
  # Redirect git's informational stdout ("HEAD is now at …") to stderr so it
  # doesn't pollute subshell captures. The "Preparing worktree" line already
  # goes to stderr on most git versions.
  if command git rev-parse --verify "refs/heads/$branch" >/dev/null 2>&1; then
    command git worktree add -- "$dest" "$branch" >&2
  else
    command git worktree add -b "$branch" -- "$dest" >&2
  fi || return

  builtin cd -- "$dest"
}
