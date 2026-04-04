#!/usr/bin/env bash
# Removes worktrees for merged branches, then deletes merged local branches.
set -euo pipefail

BASE_BRANCH="${1:-main}"

# --- Worktrees ---
# Parse porcelain output into (path, branch, prunable) blocks
main_worktree=$(git rev-parse --show-toplevel)
prunable_worktrees=()

current_path=""
current_branch=""
is_prunable=false

add_if_candidate() {
  [ -z "$current_path" ] && return
  [ "$current_path" = "$main_worktree" ] && return

  if $is_prunable; then
    prunable_worktrees+=("$current_path")
  elif [ -n "$current_branch" ]; then
    if git branch --merged "$BASE_BRANCH" | grep -qE "^[+ ] $current_branch$"; then
      prunable_worktrees+=("$current_path")
    fi
  fi
}

while IFS= read -r line; do
  case "$line" in
    worktree\ *)
      add_if_candidate
      current_path="${line#worktree }"
      current_branch=""
      is_prunable=false
      ;;
    branch\ refs/heads/*)
      current_branch="${line#branch refs/heads/}"
      ;;
    prunable*)
      is_prunable=true
      ;;
  esac
done < <(git worktree list --porcelain)
add_if_candidate

if [ ${#prunable_worktrees[@]} -gt 0 ]; then
  echo "Worktrees to remove:"
  printf '  %s\n' "${prunable_worktrees[@]}"
  echo
  read -r -p "Remove these worktrees? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for wt in "${prunable_worktrees[@]}"; do
      git worktree remove --force "$wt" && echo "  Removed: $wt"
    done
    git worktree prune
    echo
  else
    echo "Skipped worktrees."
    echo
  fi
else
  echo "No worktrees to remove."
  echo
fi

# --- Branches ---
merged=$(git branch --merged "$BASE_BRANCH" | grep -v "^\*\|$BASE_BRANCH")

if [ -z "$merged" ]; then
  echo "No merged branches to delete."
  exit 0
fi

echo "Branches to delete:"
echo "$merged"
echo

read -r -p "Delete these branches? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  echo "$merged" | xargs git branch -d
  echo "Done."
else
  echo "Aborted."
fi
