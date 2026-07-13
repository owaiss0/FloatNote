#!/bin/bash
set -e

cd "$(dirname "$0")"

# Create temporary iconset folder
mkdir -p AppIcon.iconset

# Generate the required icon sizes for macOS Retina and Non-Retina screens
sips -s format png -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png
sips -s format png -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png
sips -s format png -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png
sips -s format png -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png
sips -s format png -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png
sips -s format png -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png
sips -s format png -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png
sips -s format png -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png
sips -s format png -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png
sips -s format png -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png

# Compile into .icns format
iconutil -c icns AppIcon.iconset

# Cleanup temp folder
rm -R AppIcon.iconset

echo "AppIcon.icns compiled successfully!"
