#!/bin/bash
set -e

# Locate repository root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

echo "==> Installing DockMin..."

SRC="$REPO_ROOT/Sources/main.swift"
ICON="$REPO_ROOT/Resources/AppIcon.icns"
APP_BUNDLE="$REPO_ROOT/DockMin.app"
BIN="$REPO_ROOT/DockMin"
TARGET_APP="/Applications/DockMin.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.github.fatthreeking.DockMin.plist"

# 1. Stop existing processes and LaunchAgent service
echo "==> Stopping existing service..."
launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
pkill -9 -f "DockMin" 2>/dev/null || true
killall -9 DockMin 2>/dev/null || true

# 2. Clean up previous installation and temporary artifacts
echo "==> Cleaning up old files..."
rm -rf "$TARGET_APP" 2>/dev/null || true
rm -rf "$HOME/Applications/DockMin.app" 2>/dev/null || true
rm -rf "$APP_BUNDLE"
rm -f "$BIN"

# 3. Compile Universal 2 binary (arm64 + x86_64)
echo "==> Compiling (arm64 + x86_64)..."
swiftc -O -target arm64-apple-macos14.0 "$SRC" -o "${BIN}_arm64"
swiftc -O -target x86_64-apple-macos14.0 "$SRC" -o "${BIN}_x86_64"
lipo -create -output "$BIN" "${BIN}_arm64" "${BIN}_x86_64"
rm -f "${BIN}_arm64" "${BIN}_x86_64"

# 4. Assemble standard macOS .app bundle
echo "==> Assembling DockMin.app..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/DockMin"
chmod +x "$APP_BUNDLE/Contents/MacOS/DockMin"

# Copy app icon
if [ -f "$ICON" ]; then
    cp "$ICON" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>DockMin</string>
    <key>CFBundleIdentifier</key>
    <string>com.github.fatthreeking.DockMin</string>
    <key>CFBundleName</key>
    <string>DockMin</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Ad-hoc code signing
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

# 5. Install to /Applications (fallback to ~/Applications if permission denied)
if cp -R "$APP_BUNDLE" "$TARGET_APP" 2>/dev/null; then
    touch "$TARGET_APP"
else
    TARGET_APP="$HOME/Applications/DockMin.app"
    mkdir -p "$HOME/Applications"
    cp -R "$APP_BUNDLE" "$TARGET_APP"
    touch "$TARGET_APP"
fi
rm -rf "$APP_BUNDLE" "$BIN"
echo "==> Installed to: $TARGET_APP"

# 6. Configure LaunchAgent for login auto-start
mkdir -p "$HOME/Library/LaunchAgents"
cat << EOF > "$LAUNCH_AGENT"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.fatthreeking.DockMin</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TARGET_APP/Contents/MacOS/DockMin</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardErrorPath</key>
    <string>/tmp/dockmin.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/dockmin.log</string>
</dict>
</plist>
EOF

# 7. Launch application
open -a "$TARGET_APP" 2>/dev/null || nohup "$TARGET_APP/Contents/MacOS/DockMin" >/dev/null 2>&1 &

echo "==> Done."
