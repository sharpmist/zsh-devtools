alias gwl='git worktree list'
alias gsc='git branch --show-current'

# Pick a worktree of the current repo with fzf and print its path.
# The path rides along as a hidden tab-separated field, so paths with spaces work.
_pick_worktree() {
  _devtools_require git fzf || return 1
  setopt localoptions pipefail
  git worktree list --porcelain | awk '
    /^worktree / { wt = substr($0, 10); n = split(wt, parts, "/"); folder = parts[n] }
    /^branch /   { b = $2; sub("refs/heads/", "", b); printf "%-30s %s\t%s\n", folder, b, wt }
    /^detached$/ { printf "%-30s %s\t%s\n", folder, "(detached)", wt }
  ' | fzf --height=40% --reverse --delimiter='\t' --with-nth=1 --prompt="$1" | cut -f2
}

# Jump to a worktree of the current repo.
fwt() {
  local dir
  dir=$(_pick_worktree "worktree> ") || return 1
  [[ -n $dir ]] && cd "$dir"
}

# Delete a worktree of the current repo.
dwt() {
  local dir
  dir=$(_pick_worktree "delete worktree> ") || return 1
  [[ -z $dir ]] && return 1
  echo "Deleting worktree: $dir"
  git worktree remove "$dir"
}

alias wt='fwt'
alias dw='dwt'
