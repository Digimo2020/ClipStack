#!/bin/bash
# One command to ship an update: bump VERSION, build and test both apps, commit and push a tag.
# GitHub Actions builds both installers on their native runners and publishes the release.
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
npm version --prefix windows --no-git-tag-version "$NEW"
./build.sh
./scripts/make_dmg.sh
npm ci --prefix windows
npm run --prefix windows typecheck
npm run --prefix windows check:main
npm test --prefix windows

git add -- Sources Resources scripts README.md VERSION build.sh Package.swift LICENSE .gitignore .github/workflows/ci.yml .github/workflows/release.yml windows/package.json windows/package-lock.json windows/README.md windows/index.html windows/vite.config.ts windows/tsconfig.json windows/electron windows/src windows/assets/app-icon.png windows/scripts docs/cover.png docs/windows-history.png docs/windows-settings.png docs/ClipStack-Setup-Guide.pdf
git commit -m "feat: release ClipStack $NEW - $NOTES"
git push
git tag "v$NEW"
git push origin "v$NEW"
echo "Pushed v$NEW (was v$CUR). GitHub Actions will build and publish the DMG and Windows EXE."
