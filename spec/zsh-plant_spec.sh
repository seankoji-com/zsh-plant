# shellcheck shell=bash disable=all
# plant uses zsh-only syntax (${(U)}, $+commands) and the ordinary `date`/`git`
# plumbing, so this suite runs under shellspec's zsh mode rather than bats.
Describe 'zsh-plant.plugin.zsh'
Include ./zsh-plant.plugin.zsh

# Restrict PATH to system bins so gum (often installed via Homebrew at
# /opt/homebrew/bin) cannot leak into a test: every assertion here exercises
# the plain-stderr logging fallback, and CI installs no gum.
BASE_PATH="/usr/bin:/bin"

# pwd -P: on macOS mktemp hands back a path under /var, which is a symlink to
# /private/var. git resolves it, so an unresolved TMPROOT never compares equal.
setup() {
  TMPROOT="$(builtin cd "$(mktemp -d)" && pwd -P)"
  export PATH="$BASE_PATH"
  hash -r
}
cleanup() {
  rm -rf "$TMPROOT"
  builtin cd "$SHELLSPEC_PROJECT_ROOT"
}
BeforeEach 'setup'
AfterEach 'cleanup'

# Create a git repo with one commit at $TMPROOT/repo and cd into it.
new_repo() {
  mkdir -p "$TMPROOT/repo" && builtin cd "$TMPROOT/repo"
  git init -q
  git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
}

Describe 'plant'
    It 'errors outside a git repository'
    run_it() {
      builtin cd "$TMPROOT"
      plant
    }
    When call run_it
    The status should be failure
    The stderr should include 'not inside a git repository'
    End

    It 'rejects unknown options'
    run_it() {
      new_repo
      plant --bogus
    }
    When call run_it
    The status should be failure
    The stderr should include 'unknown option'
    End

    It 'plants a worktree at <root>/.worktrees/<name> with a same-named branch'
    run_it() {
      new_repo
      plant --no-cd myfeature
      [ -d "$TMPROOT/repo/.worktrees/myfeature" ] && print 'dir yes'
      command git branch --list myfeature
    }
    When call run_it
    The output should include 'dir yes'
    The output should include 'myfeature'
    The stderr should include "planted 'myfeature'"
    End

    It 'defaults the name to a minute-grained timestamp'
    run_it() {
      new_repo
      plant --no-cd
      find "$TMPROOT/repo/.worktrees" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    }
    When call run_it
    The output should match pattern "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]"
    The stderr should include 'using timestamp'
    End

    It 'honors ZSH_PLANT_PATH'
    run_it() {
      new_repo
      ZSH_PLANT_PATH=scratch plant --no-cd feat
      [ -d "$TMPROOT/repo/scratch/feat" ] && print 'scratch yes'
    }
    When call run_it
    The output should equal 'scratch yes'
    The stderr should include 'planting'
    End

    It 'cds into the new worktree by default'
    run_it() {
      new_repo
      plant myfeature
      print -r -- "$PWD"
    }
    When call run_it
    The output should equal "$TMPROOT/repo/.worktrees/myfeature"
    The stderr should include "planted 'myfeature'"
    End

    It 'checks out an existing branch when given'
    run_it() {
      new_repo
      command git branch backend
      plant --no-cd feature backend
      command git -C "$TMPROOT/repo/.worktrees/feature" branch --show-current
    }
    When call run_it
    The output should equal 'backend'
    The stderr should include "planted 'feature'"
    End

    It 'accepts the -b flag form'
    run_it() {
      new_repo
      command git branch backend
      plant --no-cd -b backend feature
      command git -C "$TMPROOT/repo/.worktrees/feature" branch --show-current
    }
    When call run_it
    The output should equal 'backend'
    The stderr should include "planted 'feature'"
    End

    It 'refuses when the destination path already exists'
    run_it() {
      new_repo
      mkdir -p "$TMPROOT/repo/.worktrees/taken"
      plant --no-cd taken
    }
    When call run_it
    The status should be failure
    The stderr should include 'path already exists'
    End
    End

Describe 'plant_list'
    It 'fails outside a git repository'
    run_it() {
      builtin cd "$TMPROOT"
      plant_list
    }
    When call run_it
    The status should be failure
    End

    It 'lists only planted worktrees, not arbitrary ones'
    run_it() {
      new_repo
      plant --no-cd alpha
      plant --no-cd beta
      command git worktree add -q "$TMPROOT/other" -b other
      plant_list
    }
    When call run_it
    The output should include 'alpha'
    The output should include 'beta'
    The output should not include 'other'
    The stderr should include 'planted'
    End
    End
    End
