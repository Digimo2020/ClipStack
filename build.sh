#!/bin/bash
# Builds ClipStack.app into ./build. Pass --install to also copy it to /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

SP=${SCRATCH_PATH:+--scratch-path $SCRATCH_PATH}
swift build -c release $SP
BIN="$(swift build -c release $SP --show-bin-path)/ClipStack"

APP="build/ClipStack.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ClipStack"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>ClipStack</string>
  <key>CFBundleDisplayName</key><string>ClipStack</string>
  <key>CFBundleIdentifier</key><string>com.fahim.clipstack</string>
  <key>CFBundleExecutable</key><string>ClipStack</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x ClipStack 2>/dev/null || true
  rm -rf /Applications/ClipStack.app
  cp -R "$APP" /Applications/ClipStack.app
  open /Applications/ClipStack.app
  echo "Installed and launched /Applications/ClipStack.app"
fi
