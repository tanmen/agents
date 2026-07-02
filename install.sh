#!/usr/bin/env bash
#
# install.sh — symlink this repo's Claude config into ~/.claude/
#
# This repo is the source of truth. Running this script makes ~/.claude/
# point at the files tracked here via symlinks, so editing a tracked file
# == editing the live config. Idempotent: safe to re-run after adding a
# skill / command / agent to the repo.
#
# Granularity:
#   - top-level files (CLAUDE.md, settings.json, statusline-command.sh) -> symlinked
#   - commands/*, agents/*, hooks/*, rules/*                            -> per-file symlink
#   - skills/*/                                                         -> per-skill-dir symlink
#   The containing ~/.claude/{commands,agents,skills} dirs stay real, so
#   untracked items installed there by other tooling are left untouched.
#
# Any real file/dir already at a destination is moved to a timestamped
# backup dir (printed at the end) before the symlink is created — never
# overwritten.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/claude"
DEST="$HOME/.claude"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.claude-config-backup-$TS"

if [ ! -d "$SRC" ]; then
  echo "error: $SRC not found — run from a clone of the agents repo" >&2
  exit 1
fi

mkdir -p "$DEST"
made_backup=0

# link <source-abs> <dest-abs> <backup-rel>
link() {
  local src="$1" dst="$2" rel="$3"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok      ~/.claude/$rel"
    return
  fi
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mkdir -p "$(dirname "$BACKUP/$rel")"
    mv "$dst" "$BACKUP/$rel"
    made_backup=1
    echo "  backup  ~/.claude/$rel  ->  ${BACKUP/#$HOME/~}/$rel"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  link    ~/.claude/$rel"
}

echo "Linking ${SRC/#$HOME/~}  ->  ~/.claude/"

# Top-level files
for f in CLAUDE.md settings.json statusline-command.sh; do
  [ -e "$SRC/$f" ] && link "$SRC/$f" "$DEST/$f" "$f"
done

# commands/*, agents/*, hooks/*, rules/* (per-file)
for sub in commands agents hooks rules; do
  [ -d "$SRC/$sub" ] || continue
  mkdir -p "$DEST/$sub"
  for item in "$SRC/$sub"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    link "$item" "$DEST/$sub/$name" "$sub/$name"
  done
done

# skills/* (per-skill directory)
if [ -d "$SRC/skills" ]; then
  mkdir -p "$DEST/skills"
  for item in "$SRC/skills"/*/; do
    [ -d "$item" ] || continue
    name="$(basename "$item")"
    link "${item%/}" "$DEST/skills/$name" "skills/$name"
  done
fi

echo "Done."
if [ "$made_backup" = 1 ]; then
  echo "Replaced originals backed up to: ${BACKUP/#$HOME/~}"
fi
