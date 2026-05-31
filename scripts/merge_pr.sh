#!/usr/bin/env bash
# Merge a PR via GitHub (squash), delete its branch, and sync local main.
# Usage: scripts/merge_pr.sh <pr-number> [--merge|--rebase|--squash]

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <pr-number> [--merge|--rebase|--squash]" >&2
    exit 1
fi

PR="$1"
STRATEGY="${2:---squash}"

case "$STRATEGY" in
    --merge|--rebase|--squash) ;;
    *) echo "Invalid strategy: $STRATEGY (use --merge, --rebase, or --squash)" >&2; exit 1;;
esac

command -v gh >/dev/null || { echo "gh CLI not found"; exit 1; }

gh pr merge "$PR" "$STRATEGY" --delete-branch

git checkout main
git pull --ff-only
