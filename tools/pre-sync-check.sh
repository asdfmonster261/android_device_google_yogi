#!/bin/bash
# Refuse to sync while local work could be lost. Run from anywhere in the tree.
#
# repo treats three states very differently, and only the first two lose work:
#
#   dirty tree      uncommitted changes are discarded outright
#   detached HEAD   a commit there is orphaned, recoverable from the reflog until it
#                   gets garbage collected
#   local branch    survives a sync, because repo rebases topic branches. It does NOT
#                   survive a re-init or a project identity change, and it exists on no
#                   other machine, so it is reported but is not fatal
#
# Exits non-zero for either of the first two.
set -u

cd "$(dirname "$0")/../../../.." || exit 2
[ -d .repo ] || { echo "not a repo tree: $PWD" >&2; exit 2; }

scan='
  dirty=$(git status --porcelain 2>/dev/null | wc -l)
  head=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  ahead=0
  up=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  [ -n "$up" ] && ahead=$(git rev-list --count "$up..HEAD" 2>/dev/null || echo 0)
  if [ "$dirty" != "0" ]; then
    echo "FATAL dirty=$dirty $REPO_PATH"
  elif [ "$head" = "HEAD" ] && [ "$ahead" != "0" ]; then
    echo "FATAL detached-with-${ahead}-commits $REPO_PATH"
  elif [ "$ahead" != "0" ]; then
    echo "LOCAL branch=$head ahead=$ahead $REPO_PATH"
  fi
'

out=$(repo forall -c bash -c "$scan" 2>/dev/null)
fatal=$(printf '%s\n' "$out" | grep -c '^FATAL')
localc=$(printf '%s\n' "$out" | grep -c '^LOCAL')

printf '%s\n' "$out" | grep . | sed 's/^/  /'
echo "  ---"
echo "  $fatal project(s) would lose work; $localc carry commits only on this machine"

if [ "$fatal" != "0" ]; then
  echo "  refusing to sync. Commit the dirty trees, and put detached commits on a" >&2
  echo "  branch with 'repo start <name> <project>' before committing." >&2
  exit 1
fi
exit 0
