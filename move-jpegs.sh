#!/bin/bash
# Moves .jpg files from YYYY/MM/ folders into their jpegs/ subfolders.
# Usage: ./move-jpegs.sh [--dry-run]

set -euo pipefail
cd "$(dirname "$0")"

dry_run=false
[[ "${1:-}" == "--dry-run" ]] && dry_run=true

count=0
find . -path './*/[0-9][0-9]/*.jpg' -type f | while read -r file; do
  dir="$(dirname "$file")/jpegs"
  if $dry_run; then
    echo "[dry-run] $file -> $dir/$(basename "$file")"
  else
    mkdir -p "$dir"
    mv "$file" "$dir/"
    echo "moved $file -> $dir/"
  fi
  ((count++))
done

if $dry_run; then
  echo "Dry run complete."
else
  echo "Done."
fi
