#!/bin/bash
set -e

echo "=== Starting Build for Touch-Tab ==="

# 1. Clean and create build directory structure
rm -rf build
mkdir -p build/Touch-Tab.app/Contents/MacOS
mkdir -p build/Touch-Tab.app/Contents/Resources

# 2. Compile the Swift files
echo "Compiling Swift source files..."
swiftc -o build/Touch-Tab.app/Contents/MacOS/Touch-Tab \
    Touch-Tab/AboutView.swift \
    Touch-Tab/SwipeManager.swift \
    Touch-Tab/TouchTabApp.swift

# 3. Copy resources (PNG assets mapped to standard macOS bundle naming)
echo "Copying asset resources..."
cp Touch-Tab/Assets.xcassets/StatusIcon.imageset/StatusIcon_16x16.png build/Touch-Tab.app/Contents/Resources/StatusIcon.png
cp Touch-Tab/Assets.xcassets/StatusIcon.imageset/StatusIcon_32x32.png build/Touch-Tab.app/Contents/Resources/StatusIcon@2x.png

cp Touch-Tab/Assets.xcassets/StatusIcon-Warning.imageset/StatusIcon-Warning_22x22.png build/Touch-Tab.app/Contents/Resources/StatusIcon-Warning.png
cp Touch-Tab/Assets.xcassets/StatusIcon-Warning.imageset/StatusIcon-Warning_44x44.png build/Touch-Tab.app/Contents/Resources/StatusIcon-Warning@2x.png

cp Touch-Tab/Assets.xcassets/MenuItem-Warning.imageset/MenuItem-Warning_16x16.png build/Touch-Tab.app/Contents/Resources/MenuItem-Warning.png
cp Touch-Tab/Assets.xcassets/MenuItem-Warning.imageset/MenuItem-Warning_32x32.png build/Touch-Tab.app/Contents/Resources/MenuItem-Warning@2x.png
cp Touch-Tab/Assets.xcassets/MenuItem-Warning.imageset/MenuItem-Warning_48x48.png build/Touch-Tab.app/Contents/Resources/MenuItem-Warning@3x.png

# 4. Generate AppIcon.icns
echo "Generating AppIcon.icns..."
mkdir -p build/AppIcon.iconset
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_16x16.png build/AppIcon.iconset/icon_16x16.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_32x32.png build/AppIcon.iconset/icon_16x16@2x.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_32x32.png build/AppIcon.iconset/icon_32x32.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_64x64.png build/AppIcon.iconset/icon_32x32@2x.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_128x128.png build/AppIcon.iconset/icon_128x128.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_256x256.png build/AppIcon.iconset/icon_128x128@2x.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_256x256.png build/AppIcon.iconset/icon_256x256.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_512x512.png build/AppIcon.iconset/icon_256x256@2x.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_512x512.png build/AppIcon.iconset/icon_512x512.png
cp Touch-Tab/Assets.xcassets/AppIcon.appiconset/AppIcon_1024x1024.png build/AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns build/AppIcon.iconset -o build/Touch-Tab.app/Contents/Resources/AppIcon.icns
rm -rf build/AppIcon.iconset

# 5. Create Info.plist
echo "Writing Info.plist..."
cat << 'EOF' > build/Touch-Tab.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Touch-Tab</string>
	<key>CFBundleExecutable</key>
	<string>Touch-Tab</string>
	<key>CFBundleIdentifier</key>
	<string>ris58h.Touch-Tab</string>
	<key>CFBundleName</key>
	<string>Touch-Tab</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSUIElement</key>
	<true/>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.productivity</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon.icns</string>
</dict>
</plist>
EOF

# 6. Ad-hoc codesign the App Bundle
echo "Signing the App Bundle..."
codesign --force --sign - --entitlements Touch-Tab/Touch-Tab.entitlements build/Touch-Tab.app

# 7. Package for Distribution (ZIP and DMG)
echo "Packaging App for distribution..."
# Create ZIP archive
zip -q -r build/Touch-Tab.zip build/Touch-Tab.app

# Create DMG Disk Image
mkdir -p build/dmg_temp
cp -R build/Touch-Tab.app build/dmg_temp/
ln -s /Applications build/dmg_temp/Applications
hdiutil create -volname "Touch-Tab" -srcfolder build/dmg_temp -ov -format UDZO build/Touch-Tab.dmg > /dev/null
rm -rf build/dmg_temp

echo "=== Build & Packaging Completed Successfully! ==="
echo "App Bundle:     $(pwd)/build/Touch-Tab.app"
echo "ZIP Archive:    $(pwd)/build/Touch-Tab.zip"
echo "DMG Installer:  $(pwd)/build/Touch-Tab.dmg"
