#!/bin/bash
# Packages build/ClipStack.app into build/ClipStack.dmg (run ./build.sh first).
set -euo pipefail
cd "$(dirname "$0")/.."
STAGE="$(mktemp -d)"
cp -R build/ClipStack.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f build/ClipStack.dmg
hdiutil create -volname "ClipStack" -srcfolder "$STAGE" -ov -format UDZO build/ClipStack.dmg
rm -rf "$STAGE"
echo "Created build/ClipStack.dmg"
