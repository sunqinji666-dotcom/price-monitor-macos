#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release

APP_NAME="价格监控.app"
APP_PATH="$APP_NAME"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp ".build/release/PriceMonitor" "$APP_PATH/Contents/MacOS/PriceMonitor"
cp "Info.plist" "$APP_PATH/Contents/Info.plist"
cp "Assets/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP_PATH" >/dev/null
echo "已生成：$(pwd)/$APP_PATH"
