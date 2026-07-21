#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
ARCH="arm64"
ARCHIVE_NAME="PriceMonitor-v${VERSION}-macOS-${ARCH}.zip"

./build_app.sh
mkdir -p dist
rm -f "dist/$ARCHIVE_NAME" "dist/$ARCHIVE_NAME.sha256"
ditto -c -k --keepParent "价格监控.app" "dist/$ARCHIVE_NAME"
shasum -a 256 "dist/$ARCHIVE_NAME" > "dist/$ARCHIVE_NAME.sha256"
echo "发布包：$(pwd)/dist/$ARCHIVE_NAME"
