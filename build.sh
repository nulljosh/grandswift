#!/bin/sh
# Builds "Rainjack.app" with its Dock icon. Usage: ./build.sh && open "Rainjack.app"
set -e
cd "$(dirname "$0")"
pkill -x rainjack || true
swiftc -O -parse-as-library main.swift -o rainjack
A="Rainjack.app/Contents"; rm -rf "Rainjack.app"; mkdir -p "$A/MacOS" "$A/Resources"
cp rainjack "$A/MacOS/rainjack"
GS_ICON=/tmp/gs_icon.png ./rainjack
I=/tmp/gs.iconset; rm -rf $I; mkdir $I
for s in 16 32 128 256 512; do sips -z $s $s /tmp/gs_icon.png --out $I/icon_${s}x${s}.png >/dev/null; sips -z $((s*2)) $((s*2)) /tmp/gs_icon.png --out $I/icon_${s}x${s}@2x.png >/dev/null; done
iconutil -c icns $I -o "$A/Resources/AppIcon.icns"
cat > "$A/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleShortVersionString</key><string>1.2.0</string><key>CFBundleName</key><string>Rainjack</string><key>CFBundleExecutable</key><string>rainjack</string><key>CFBundleIdentifier</key><string>com.jaybulb.rainjack</string><key>CFBundleIconFile</key><string>AppIcon</string><key>CFBundlePackageType</key><string>APPL</string><key>LSApplicationCategoryType</key><string>public.app-category.games</string><key>NSHighResolutionCapable</key><true/></dict></plist>
P
