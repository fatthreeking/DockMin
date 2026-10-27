#!/bin/bash
set -e

# Ensure Homebrew paths are included
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Locate repository root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

echo "==> Packaging DockMin.dmg..."

SRC="$REPO_ROOT/Sources/main.swift"
ICON="$REPO_ROOT/Resources/AppIcon.icns"
OUTPUT_DMG="$REPO_ROOT/DockMin.dmg"

# Create temporary build directory and clean up on exit
WORK_DIR=$(mktemp -d /tmp/dockmin_dmg_build.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

BIN="$WORK_DIR/DockMin"
APP_BUNDLE="$WORK_DIR/DockMin.app"
BG_1X="$WORK_DIR/background.png"
BG_2X="$WORK_DIR/background@2x.png"
DMGBUILD_SETTINGS="$WORK_DIR/dmg_settings.py"

# 1. Compile Universal 2 binary (arm64 + x86_64)
echo "==> Compiling (arm64 + x86_64)..."
swiftc -O -target arm64-apple-macos14.0 "$SRC" -o "${BIN}_arm64"
swiftc -O -target x86_64-apple-macos14.0 "$SRC" -o "${BIN}_x86_64"
lipo -create -output "$BIN" "${BIN}_arm64" "${BIN}_x86_64"
rm -f "${BIN}_arm64" "${BIN}_x86_64"

# 2. Assemble .app bundle
echo "==> Assembling DockMin.app..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/DockMin"
chmod +x "$APP_BUNDLE/Contents/MacOS/DockMin"

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

# 3. Build DMG (including guide text & arrow overlay)
echo "==> Building DMG..."
swift -e '
import Cocoa

func renderBackground(scale: CGFloat, outPath: String) {
    let width: CGFloat = 600
    let height: CGFloat = 400
    let size = NSSize(width: width, height: height)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(width * scale),
        pixelsHigh: Int(height * scale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { exit(1) }
    rep.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // 1. Pure white background matching native Finder window
    NSColor.white.setFill()
    NSBezierPath.fill(NSRect(x: 0, y: 0, width: width, height: height))

    // 2. Top centered guide text above the icons
    let font = NSFont.systemFont(ofSize: 14.0, weight: .medium)
    let textColor = NSColor(calibratedWhite: 0.38, alpha: 1.0)
    let text = "Drag DockMin to Applications" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: textColor
    ]
    let textSize = text.size(withAttributes: attrs)
    let textPoint = NSPoint(x: (width - textSize.width) / 2.0, y: 336)
    text.draw(at: textPoint, withAttributes: attrs)

    // 3. Center drag arrow between DockMin and Applications (aligned with y_top = 140 -> y_cocoa = 260)
    let arrowY: CGFloat = 260
    let arrowColor = NSColor(calibratedWhite: 0.55, alpha: 0.9)
    arrowColor.setStroke()

    let arrowPath = NSBezierPath()
    arrowPath.move(to: NSPoint(x: 262, y: arrowY))
    arrowPath.line(to: NSPoint(x: 334, y: arrowY))
    arrowPath.lineWidth = 3.0
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    let headPath = NSBezierPath()
    headPath.move(to: NSPoint(x: 322, y: arrowY + 11))
    headPath.line(to: NSPoint(x: 336, y: arrowY))
    headPath.line(to: NSPoint(x: 322, y: arrowY - 11))
    headPath.lineWidth = 3.0
    headPath.lineCapStyle = .round
    headPath.lineJoinStyle = .round
    headPath.stroke()

    NSGraphicsContext.restoreGraphicsState()

    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outPath))
    }
}

renderBackground(scale: 1.0, outPath: CommandLine.arguments[1])
renderBackground(scale: 2.0, outPath: CommandLine.arguments[2])
' "$BG_1X" "$BG_2X"

sips -s dpiWidth 72 -s dpiHeight 72 "$BG_1X" >/dev/null 2>&1 || true
sips -s dpiWidth 144 -s dpiHeight 144 "$BG_2X" >/dev/null 2>&1 || true

rm -rf "$OUTPUT_DMG" "$REPO_ROOT/DockMin.zip" "$REPO_ROOT/DockMin" "$REPO_ROOT/DockMin.app"
hdiutil detach "/Volumes/DockMin" -force >/dev/null 2>&1 || true

VENV_DIR="/tmp/dockmin_dmgbuild_venv"
if [ ! -x "$VENV_DIR/bin/dmgbuild" ]; then
    echo "==> Preparing dmgbuild..."
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --quiet --upgrade pip dmgbuild
fi

cat << EOF > "$DMGBUILD_SETTINGS"
import os
import subprocess
import mac_alias

# Generate compatible native macOS URL bookmark data via Foundation
class _NativeBookmark:
    def __init__(self, raw_bytes):
        self._bytes = raw_bytes
    def to_bytes(self):
        return self._bytes

def _native_bookmark_for_file(path):
    swift_snippet = '''
    import Foundation
    let url = URL(fileURLWithPath: CommandLine.arguments[1])
    let data = try! url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
    FileHandle.standardOutput.write(data)
    '''
    raw = subprocess.check_output(["/usr/bin/swift", "-e", swift_snippet, path])
    return _NativeBookmark(raw)

mac_alias.Bookmark.for_file = staticmethod(_native_bookmark_for_file)

application = "$APP_BUNDLE"
appname = os.path.basename(application)

format = "UDZO"
size = None
files = [application]
symlinks = {"Applications": "/Applications"}
hide_extensions = [appname]

if os.path.exists("$ICON"):
    badge_icon = "$ICON"

# Center icons vertically in the window
icon_locations = {
    appname: (160, 140),
    "Applications": (440, 140),
}

background = "$BG_1X"
lookForHiDPI = True
window_rect = ((400, 220), (600, 400))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = "bottom"
text_size = 12
icon_size = 128
EOF

"$VENV_DIR/bin/dmgbuild" -s "$DMGBUILD_SETTINGS" "DockMin" "$OUTPUT_DMG"

# 4. Set custom Finder icon on the generated .dmg file
if [ -f "$ICON" ] && [ -f "$OUTPUT_DMG" ]; then
    swift -e '
    import Cocoa
    let args = CommandLine.arguments
    if args.count >= 3 {
        let iconPath = args[1]
        let filePath = args[2]
        if let icon = NSImage(contentsOfFile: iconPath) {
            _ = NSWorkspace.shared.setIcon(icon, forFile: filePath, options: [])
        }
    }
    ' "$ICON" "$OUTPUT_DMG" 2>/dev/null || true
fi

DMG_SHA256=$(shasum -a 256 "$OUTPUT_DMG" | awk '{print $1}')
echo "==> Done: $OUTPUT_DMG"
echo "SHA256: $DMG_SHA256"
