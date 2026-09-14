#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/moonrabbit-module-cache"
swift build -c release --disable-sandbox
BIN_DIR="$(swift build -c release --show-bin-path --disable-sandbox)"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/moonrabbit-build.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/MoonRabbit.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MoonRabbit" "$APP/Contents/MacOS/MoonRabbit"
cp -R "$BIN_DIR/MoonRabbit_MoonRabbit.bundle" "$APP/Contents/Resources/"
cp Sources/MoonRabbit/Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>MoonRabbit</string>
<key>CFBundleDisplayName</key><string>달토끼</string>
<key>CFBundleIdentifier</key><string>local.moonrabbit.desktop</string>
<key>CFBundleVersion</key><string>20</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>1.8.2</string>
<key>CFBundleExecutable</key><string>MoonRabbit</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
mkdir -p dist
ditto -c -k --norsrc --noextattr --keepParent "$APP" dist/MoonRabbit-macOS.zip
# Replace only the generated app, rather than merging stale resources/metadata.
rm -rf dist/MoonRabbit.app
ditto --norsrc --noextattr "$APP" dist/MoonRabbit.app
xattr -cr dist/MoonRabbit.app
codesign --verify --deep --strict dist/MoonRabbit.app
printf 'Built: %s/dist/MoonRabbit.app\n' "$PWD"
