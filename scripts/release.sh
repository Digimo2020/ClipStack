#!/bin/bash
# One command to ship an update: bump VERSION, build, make the DMG, commit, push and publish the GitHub release.
# The README badges (version, last update, released) refresh themselves from the release and the push.
# Usage: ./scripts/release.sh [patch|minor|major|X.Y.Z] "what changed"
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP="${1:-patch}"
NOTES="${2:-Update}"
CUR="$(cat VERSION)"
IFS=. read -r MA MI PA <<<"$CUR"
case "$BUMP" in
  patch) NEW="$MA.$MI.$((PA + 1))" ;;
  minor) NEW="$MA.$((MI + 1)).0" ;;
  major) NEW="$((MA + 1)).0.0" ;;
  *.*.*) NEW="$BUMP" ;;
  *) echo "Usage: $0 [patch|minor|major|X.Y.Z] \"notes\""; exit 1 ;;
esac

echo "$NEW" > VERSION
./build.sh
./scripts/make_dmg.sh

git add -A -- Sources Resources scripts README.md VERSION build.sh Package.swift LICENSE .gitignore docs/cover.png
git commit -m "v$NEW: $NOTES"
git push
gh release create "v$NEW" build/ClipStack.dmg --title "ClipStack $NEW" --notes "$NOTES"
echo "Released v$NEW (was v$CUR)"
