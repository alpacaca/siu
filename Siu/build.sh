#!/bin/bash
set -e

APP_NAME="Siu"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_NAME="${APP_NAME}.dmg"
DMG_TEMP="dmg_temp"

echo "🔨 Building ${APP_NAME}..."
swift build -c release 2>&1

echo "📦 Packaging ${APP_BUNDLE}..."

rm -rf "${APP_BUNDLE}" "${DMG_NAME}" "${DMG_TEMP}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
EXECUTABLE=$(find .build -name "${APP_NAME}" -type f -path "*release/${APP_NAME}" ! -path "*.dSYM*" | head -1)
if [ -z "$EXECUTABLE" ]; then
    echo "❌ Executable not found!"
    exit 1
fi
cp "${EXECUTABLE}" "${MACOS_DIR}/${APP_NAME}"

# Copy bundle resources
BUNDLE_RESOURCE=$(find .build -name "Siu_Siu.bundle" -type d -path "*release*" | head -1)
if [ -n "$BUNDLE_RESOURCE" ]; then
    cp -R "${BUNDLE_RESOURCE}" "${RESOURCES_DIR}/"
fi

# Generate .icns from icon PNGs
ICONSET_DIR="${APP_NAME}.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

ICON_SRC="Siu/Assets.xcassets/AppIcon.appiconset"
if [ -f "${ICON_SRC}/icon_16x16.png" ]; then
    cp "${ICON_SRC}/icon_16x16.png"     "${ICONSET_DIR}/icon_16x16.png"
    cp "${ICON_SRC}/icon_16x16@2x.png"  "${ICONSET_DIR}/icon_16x16@2x.png"
    cp "${ICON_SRC}/icon_32x32.png"     "${ICONSET_DIR}/icon_32x32.png"
    cp "${ICON_SRC}/icon_32x32@2x.png"  "${ICONSET_DIR}/icon_32x32@2x.png"
    cp "${ICON_SRC}/icon_128x128.png"   "${ICONSET_DIR}/icon_128x128.png"
    cp "${ICON_SRC}/icon_128x128@2x.png" "${ICONSET_DIR}/icon_128x128@2x.png"
    cp "${ICON_SRC}/icon_256x256.png"   "${ICONSET_DIR}/icon_256x256.png"
    cp "${ICON_SRC}/icon_256x256@2x.png" "${ICONSET_DIR}/icon_256x256@2x.png"
    cp "${ICON_SRC}/icon_512x512.png"   "${ICONSET_DIR}/icon_512x512.png"
    cp "${ICON_SRC}/icon_512x512@2x.png" "${ICONSET_DIR}/icon_512x512@2x.png"

    iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/${APP_NAME}.icns" 2>/dev/null && \
        echo "🎨 App icon created." || \
        echo "⚠️  iconutil failed, continuing without .icns"
fi
rm -rf "${ICONSET_DIR}"

# Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>Siu</string>
    <key>CFBundleExecutable</key>
    <string>Siu</string>
    <key>CFBundleIconFile</key>
    <string>Siu</string>
    <key>CFBundleIdentifier</key>
    <string>com.siu.clipboard</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Siu</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Siu. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

echo "✅ ${APP_BUNDLE} created."

# Build DMG with drag-to-install background
echo "💿 Creating ${DMG_NAME}..."

DMG_RW="${APP_NAME}_rw.dmg"
DMG_BG_DIR="dmg_bg_gen"
DMG_BG_IMG="${DMG_BG_DIR}/bg.png"

rm -rf "${DMG_TEMP}" "${DMG_RW}" "${DMG_NAME}" "${DMG_BG_DIR}"
mkdir -p "${DMG_TEMP}/.background"
mkdir -p "${DMG_BG_DIR}"

# Generate DMG background image with arrow using Swift/CoreGraphics
swift - "${DMG_BG_IMG}" << 'BGEOF'
import Foundation
import AppKit

let args = CommandLine.arguments
guard args.count > 1 else { exit(1) }
let outputPath = args[1]

let width: CGFloat = 660
let height: CGFloat = 400

guard let ctx = CGContext(
    data: nil, width: Int(width), height: Int(height),
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
) else { exit(1) }

// Background — Monokai Pro dark
let bgColor = CGColor(red: 45/255, green: 42/255, blue: 46/255, alpha: 1)
ctx.setFillColor(bgColor)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Subtle gradient overlay (bottom darker)
let gradColors = [
    CGColor(red: 35/255, green: 33/255, blue: 37/255, alpha: 0.6),
    CGColor(red: 45/255, green: 42/255, blue: 46/255, alpha: 0.0)
] as CFArray
if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradColors, locations: [0, 1]) {
    ctx.drawLinearGradient(gradient, start: CGPoint(x: width/2, y: 0), end: CGPoint(x: width/2, y: height), options: [])
}

// Draw arrow from left icon area to right Applications area
// Icons will be at roughly x=165 and x=495 (centered in 660px, spaced ~330px apart)
let arrowY = height / 2 - 10
let arrowStartX: CGFloat = 240
let arrowEndX: CGFloat = 420
let arrowColor = CGColor(red: 255/255, green: 216/255, blue: 102/255, alpha: 0.85) // Monokai yellow

// Arrow shaft
ctx.setStrokeColor(arrowColor)
ctx.setLineWidth(3.0)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: arrowStartX, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX, y: arrowY))
ctx.strokePath()

// Arrow head
ctx.setFillColor(arrowColor)
ctx.move(to: CGPoint(x: arrowEndX + 2, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX - 14, y: arrowY + 12))
ctx.addLine(to: CGPoint(x: arrowEndX - 14, y: arrowY - 12))
ctx.closePath()
ctx.fillPath()

// "Drag to install" text
let textY: CGFloat = arrowY - 40
let textColor = CGColor(red: 193/255, green: 192/255, blue: 192/255, alpha: 0.7)

// Use NSGraphicsContext to draw text
if let cgImage = ctx.makeImage() {
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    nsImage.lockFocus()

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 14, weight: .medium),
        .foregroundColor: NSColor(red: 193/255, green: 192/255, blue: 192/255, alpha: 0.7),
        .paragraphStyle: paragraphStyle
    ]
    let text = "拖入 Applications 文件夹安装"
    let textRect = NSRect(x: 0, y: height - textY - 20, width: width, height: 30)
    text.draw(in: textRect, withAttributes: attrs)

    nsImage.unlockFocus()

    // Save
    guard let tiff = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let pngData = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
    try! pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Background image generated: \(outputPath)")
} else {
    exit(1)
}
BGEOF

# Copy app and create Applications symlink
cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"
ln -s /Applications "${DMG_TEMP}/Applications"

# Copy background image
cp "${DMG_BG_IMG}" "${DMG_TEMP}/.background/bg.png"

# Create writable DMG first
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDRW \
    "${DMG_RW}" 2>/dev/null

# Mount and configure window layout via AppleScript
MOUNT_DIR="/Volumes/${APP_NAME}"

# Unmount if already mounted
hdiutil detach "${MOUNT_DIR}" 2>/dev/null || true

hdiutil attach "${DMG_RW}" -mountpoint "${MOUNT_DIR}" -noautoopen

# Apply Finder window settings
osascript << ASCRIPT
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 760, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set background picture of viewOptions to file ".background:bg.png"
        set position of item "${APP_BUNDLE}" of container window to {165, 200}
        set position of item "Applications" of container window to {495, 200}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
ASCRIPT

# Ensure changes are flushed
sync

hdiutil detach "${MOUNT_DIR}" 2>/dev/null

# Convert to compressed read-only DMG
hdiutil convert "${DMG_RW}" -format UDZO -o "${DMG_NAME}" 2>/dev/null

# Cleanup
rm -rf "${DMG_TEMP}" "${DMG_RW}" "${DMG_BG_DIR}"

echo ""
echo "✅ Build complete!"
echo "   📦 App:  $(pwd)/${APP_BUNDLE}"
echo "   💿 DMG:  $(pwd)/${DMG_NAME}"
echo ""
echo "🚀 To run directly:"
echo "   open ${APP_BUNDLE}"
echo ""
echo "📋 To install via DMG:"
echo "   open ${DMG_NAME}"
