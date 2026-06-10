#!/usr/bin/env bash
# build-app.sh — 将 Cal 打包成 macOS .app bundle
set -euo pipefail

APP_NAME="Cal"
BUNDLE_ID="com.scx.cal"
VERSION="1.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "▶ 清理旧构建..."
rm -rf "$APP_BUNDLE"

echo "▶ 编译 Release..."
swift build -c release 2>&1

echo "▶ 创建 .app 目录结构..."
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "▶ 复制可执行文件..."
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

echo "▶ 生成图标..."
ICONSET="$RESOURCES_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
SRC="icon_1024.png"   # 1024×1024 正方形源图

# macOS 标准 iconset 命名（10 个文件，大小严格对应）
sips -z 16   16   $SRC --out "$ICONSET/icon_16x16.png"     &>/dev/null
sips -z 32   32   $SRC --out "$ICONSET/icon_16x16@2x.png"  &>/dev/null
sips -z 32   32   $SRC --out "$ICONSET/icon_32x32.png"     &>/dev/null
sips -z 64   64   $SRC --out "$ICONSET/icon_32x32@2x.png"  &>/dev/null
sips -z 128  128  $SRC --out "$ICONSET/icon_128x128.png"   &>/dev/null
sips -z 256  256  $SRC --out "$ICONSET/icon_128x128@2x.png" &>/dev/null
sips -z 256  256  $SRC --out "$ICONSET/icon_256x256.png"   &>/dev/null
sips -z 512  512  $SRC --out "$ICONSET/icon_256x256@2x.png" &>/dev/null
sips -z 512  512  $SRC --out "$ICONSET/icon_512x512.png"   &>/dev/null
sips -z 1024 1024 $SRC --out "$ICONSET/icon_512x512@2x.png" &>/dev/null

iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET"

echo "▶ 写入 Info.plist..."
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "▶ 写入 PkgInfo..."
printf 'APPL????' > "$CONTENTS/PkgInfo"

echo "▶ 临时签名（ad-hoc）..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>&1 || \
  echo "  ⚠ 签名失败，App 仍可手动打开（右键 → 打开）"

echo ""
echo "✅ 打包完成：$(pwd)/$APP_BUNDLE"
echo ""
echo "  直接运行：open $APP_BUNDLE"
echo "  移入 /Applications：cp -r $APP_BUNDLE /Applications/"
