#!/bin/bash
set -e

usage() {
  cat <<EOF
Usage: $0 [sync|update|branch <branch-name>]
  sync             : Only synchronize submodule remote info
  update           : Reset and update submodules to the latest remote commit
  branch <name>    : Checkout all submodules to the specified branch and sync to latest
EOF
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

case "$1" in
  sync)
    echo "[1/1] Synchronizing submodule remote info..."
    git submodule sync
    echo "Submodule remote info synchronized!"
    ;;
  update)
    echo "[1/1] Resetting and updating submodules to latest commit..."
    git submodule update --init --recursive --remote
    echo "Submodules reset to latest commit!"
    ;;
  branch)
    if [ -z "$2" ]; then
      echo "Error: Please provide a branch name."
      usage
    fi
    BRANCH="$2"
    git submodule foreach --quiet '
      echo "\n--- Updating $name to branch '"$BRANCH"' ---"
      git fetch origin
      if git show-ref --verify --quiet refs/remotes/origin/'"$BRANCH"'; then
        if git show-ref --verify --quiet refs/heads/'"$BRANCH"'; then
          git checkout '"$BRANCH"'
        else
          git checkout -b '"$BRANCH"' origin/'"$BRANCH"'
        fi
        git pull origin '"$BRANCH"'
      else
        echo "  [!] origin/'"$BRANCH"' branch does not exist. Skipping."
      fi
    '
    echo "--- Staging submodule changes in superproject ---"
    for path in $(git config --file .gitmodules --get-regexp path | awk '{print $2}'); do
      git add "$path"
    done
    echo "Done. Now commit/push to the parent repository."
    ;;
  *)
    usage
    ;;
esac
