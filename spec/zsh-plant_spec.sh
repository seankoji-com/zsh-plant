# shellcheck shell=bash disable=all
# plant uses zsh-only syntax, so this suite runs under shellspec's zsh mode.
Describe 'zsh-plant.plugin.zsh'
  Include ./zsh-plant.plugin.zsh

  # Restrict PATH to avoid any real git on the developer's machine bleeding
  # in unexpectedly — git itself we do want, so keep /usr/bin.
  BASE_PATH="/usr/bin:/bin"

  setup() {
    TMPROOT="$(builtin cd "$(mktemp -d)" && pwd -P)"
    PATH="$BASE_PATH"
    hash -r
  }
  cleanup() { rm -rf "$TMPROOT"; builtin cd "$SHELLSPEC_PROJECT_ROOT"; }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  # Shared helper: init a repo with one commit so worktrees can be added.
  # commit.gpgsign=false is required because the stowed .gitconfig enables
  # SSH signing globally, and the 1Password agent is not available in tests.
  init_repo() {
    mkdir -p "$1" && builtin cd "$1"
    git init -q
    git -c user.email=t@t -c user.name=t -c commit.gpgsign=false \
      commit -q --allow-empty -m init
  }

  Describe 'plant — argument validation'
    It 'errors with no arguments'
      run_it() { builtin cd "$TMPROOT"; plant; }
      When call run_it
      The status should be failure
      The stderr should include 'a worktree name is required'
    End

    It 'errors on unknown flags'
      run_it() { builtin cd "$TMPROOT"; plant --unknown foo; }
      When call run_it
      The status should be failure
      The stderr should include 'unknown option'
    End

    It 'prints help with -h'
      run_it() { plant -h; }
      When call run_it
      The status should be success
      The output should include 'Usage'
    End
  End

  Describe 'plant — git context'
    It 'errors outside a git repository'
      run_it() { builtin cd "$TMPROOT"; plant my-feature; }
      When call run_it
      The status should be failure
      The stderr should include 'not inside a git repository'
    End
  End

  Describe 'plant — worktree creation'
    It 'creates .worktrees/<name> and cds into it'
      run_it() {
        init_repo "$TMPROOT/repo"
        plant my-feature 2>/dev/null
        print -r -- "$PWD"
      }
      When call run_it
      The status should be success
      The output should equal "$TMPROOT/repo/.worktrees/my-feature"
    End

    It 'creates the branch named after <name> by default'
      run_it() {
        init_repo "$TMPROOT/repo"
        plant my-feature 2>/dev/null
        git branch --show-current
      }
      When call run_it
      The status should be success
      The output should equal "my-feature"
    End

    It 'accepts an explicit branch name as the second positional argument'
      run_it() {
        init_repo "$TMPROOT/repo"
        plant wt feat/thing 2>/dev/null
        print -r -- "$PWD"
      }
      When call run_it
      The status should be success
      The output should equal "$TMPROOT/repo/.worktrees/wt"
    End

    It 'accepts -b <branch> <name> flag style'
      run_it() {
        init_repo "$TMPROOT/repo"
        plant -b feat/thing wt 2>/dev/null
        print -r -- "$PWD"
      }
      When call run_it
      The status should be success
      The output should equal "$TMPROOT/repo/.worktrees/wt"
    End

    It 'checks out an existing branch instead of creating a new one'
      run_it() {
        init_repo "$TMPROOT/repo"
        git branch existing-branch
        plant wt existing-branch 2>/dev/null
        git branch --show-current
      }
      When call run_it
      The status should be success
      The output should equal "existing-branch"
    End

    It 'errors when the destination already exists'
      run_it() {
        init_repo "$TMPROOT/repo"
        mkdir -p ".worktrees/my-feature"
        plant my-feature
      }
      When call run_it
      The status should be failure
      The stderr should include 'path already exists'
    End

    It 'works from a subdirectory of the repo (root is still the anchor)'
      run_it() {
        init_repo "$TMPROOT/repo"
        mkdir -p src && builtin cd src
        plant my-feature 2>/dev/null
        print -r -- "$PWD"
      }
      When call run_it
      The status should be success
      The output should equal "$TMPROOT/repo/.worktrees/my-feature"
    End
  End
End
