#!/bin/bash
# HealthAI 2030 App Icon Generation Script
# Usage: ./generate_app_icons.sh [master_icon.png]

set -e

ICON_DIR="Sources/SharedResources/Assets.xcassets/AppIcon.appiconset"
MASTER_ICON="${1:-master_icon_1024.png}"

echo "🎨 HealthAI 2030 App Icon Generator"
echo "=================================="
echo ""

# Check if master icon exists
if [ ! -f "$MASTER_ICON" ]; then
    echo "❌ Master icon '$MASTER_ICON' not found"
    echo ""
    echo "📝 To use this script:"
    echo "1. Create a 1024x1024 PNG icon named 'master_icon_1024.png'"
    echo "2. Place it in the project root directory"
    echo "3. Run: ./generate_app_icons.sh"
    echo ""
    echo "Alternative: ./generate_app_icons.sh your_icon.png"
    echo ""
    echo "🎨 Design requirements:"
    echo "- Size: 1024x1024 pixels"
    echo "- Format: PNG with opaque background"
    echo "- Theme: HealthAI 2030 medical technology"
    echo "- Colors: Blue (#007AFF), Green (#30D158), Purple (#AF52DE)"
    echo ""
    exit 1
fi

# Check if sips is available (macOS image processing tool)
if ! command -v sips &> /dev/null; then
    echo "❌ 'sips' command not found"
    echo "This script requires macOS 'sips' tool for image processing"
    echo ""
    echo "Alternative: Use online icon generators:"
    echo "- AppIcon.co: https://appicon.co"
    echo "- MakeAppIcon: https://makeappicon.com"
    echo "- IconKitchen: https://icon.kitchen"
    exit 1
fi

# Verify master icon dimensions
DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$MASTER_ICON" | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
if [ "$DIMENSIONS" != "1024x1024" ]; then
    echo "⚠️  Warning: Master icon is $DIMENSIONS, recommended 1024x1024"
    echo "Continuing anyway..."
fi

echo "📱 Source icon: $MASTER_ICON ($DIMENSIONS)"
echo "📁 Output directory: $ICON_DIR"
echo ""

# Create backup of existing icons
if ls "$ICON_DIR"/*.png 1> /dev/null 2>&1; then
    echo "💾 Backing up existing icons..."
    mkdir -p "$ICON_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    cp "$ICON_DIR"/*.png "$ICON_DIR/backup_$(date +%Y%m%d_%H%M%S)/" 2>/dev/null || true
    echo "✅ Backup created"
fi

echo ""
echo "🔄 Generating iOS/iPadOS icons..."

# Generate iOS icons
sips -z 40 40 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-20@2x.png" > /dev/null
sips -z 60 60 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-20@3x.png" > /dev/null
sips -z 58 58 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-29@2x.png" > /dev/null
sips -z 87 87 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-29@3x.png" > /dev/null
sips -z 80 80 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-40@2x.png" > /dev/null
sips -z 120 120 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-40@3x.png" > /dev/null
sips -z 120 120 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-60@2x.png" > /dev/null
sips -z 180 180 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-60@3x.png" > /dev/null

# Generate iPad icons
sips -z 20 20 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-20.png" > /dev/null
sips -z 29 29 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-29.png" > /dev/null
sips -z 40 40 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-40.png" > /dev/null
sips -z 76 76 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-76.png" > /dev/null
sips -z 152 152 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-76@2x.png" > /dev/null
sips -z 167 167 "$MASTER_ICON" --out "$ICON_DIR/AppIcon-83.5@2x.png" > /dev/null

# Copy marketing icons (1024x1024)
cp "$MASTER_ICON" "$ICON_DIR/AppIcon-1024.png"

echo "✅ iOS/iPadOS icons generated (16 files)"

echo ""
echo "🖥️  Generating macOS icons..."

# Generate macOS icons
sips -z 16 16 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_16.png" > /dev/null
sips -z 32 32 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_32.png" > /dev/null
sips -z 64 64 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_64.png" > /dev/null
sips -z 128 128 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_128.png" > /dev/null
sips -z 256 256 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_256.png" > /dev/null
sips -z 512 512 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_512.png" > /dev/null
sips -z 1024 1024 "$MASTER_ICON" --out "$ICON_DIR/app_icon_mac_1024.png" > /dev/null

echo "✅ macOS icons generated (7 files)"

echo ""
echo "⌚ Generating watchOS icons..."

# Generate watchOS icons
sips -z 48 48 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_48.png" > /dev/null
sips -z 55 55 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_55.png" > /dev/null
sips -z 58 58 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_58.png" > /dev/null
sips -z 87 87 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_87.png" > /dev/null
sips -z 80 80 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_80.png" > /dev/null
sips -z 88 88 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_88.png" > /dev/null
sips -z 100 100 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_100.png" > /dev/null
sips -z 172 172 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_172.png" > /dev/null
sips -z 196 196 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_196.png" > /dev/null
sips -z 216 216 "$MASTER_ICON" --out "$ICON_DIR/app_icon_watch_216.png" > /dev/null

echo "✅ watchOS icons generated (10 files)"

echo ""
echo "📺 Generating tvOS icons..."

# Generate tvOS icons (maintaining 16:9.6 aspect ratio for TV)
sips -z 240 400 "$MASTER_ICON" --out "$ICON_DIR/app_icon_tv_400x240.png" > /dev/null
sips -z 768 1280 "$MASTER_ICON" --out "$ICON_DIR/app_icon_tv_1280x768.png" > /dev/null
sips -z 1080 1920 "$MASTER_ICON" --out "$ICON_DIR/app_icon_tv_1920x1080.png" > /dev/null

echo "✅ tvOS icons generated (3 files)"

echo ""
echo "🌙 Creating dark mode variant..."

# Create dark mode variant (copy for now, developer should customize)
cp "$MASTER_ICON" "$ICON_DIR/AppIcon-1024-dark.png"

echo ""
echo "🎨 Creating tinted variant..."

# Create tinted variant (copy for now, developer should customize)
cp "$MASTER_ICON" "$ICON_DIR/AppIcon-1024-tinted.png"

echo ""
echo "📊 Generation Summary"
echo "===================="

GENERATED_COUNT=$(ls "$ICON_DIR"/*.png 2>/dev/null | wc -l | xargs)
echo "✅ Generated: $GENERATED_COUNT icon files"
echo "📁 Location: $ICON_DIR"

# List generated files by category
echo ""
echo "📱 iOS/iPadOS: $(ls "$ICON_DIR"/AppIcon-*.png 2>/dev/null | wc -l | xargs) files"
echo "🖥️  macOS: $(ls "$ICON_DIR"/app_icon_mac_*.png 2>/dev/null | wc -l | xargs) files" 
echo "⌚ watchOS: $(ls "$ICON_DIR"/app_icon_watch_*.png 2>/dev/null | wc -l | xargs) files"
echo "📺 tvOS: $(ls "$ICON_DIR"/app_icon_tv_*.png 2>/dev/null | wc -l | xargs) files"

echo ""
echo "📝 Next Steps:"
echo "=============="
echo "1. 🎨 Customize dark mode: $ICON_DIR/AppIcon-1024-dark.png"
echo "2. 🎨 Customize tinted variant: $ICON_DIR/AppIcon-1024-tinted.png"
echo "3. 🔍 Review small icons (16x16, 20x20) for clarity"
echo "4. 🚀 Test in Xcode iOS Simulator"
echo "5. 📱 Test on physical devices"
echo "6. 🎯 Optimize with ImageOptim (optional)"

echo ""
echo "⚠️  Important Notes:"
echo "- Dark mode variant should have appropriate contrast adjustments"
echo "- Tinted variant should work well with system tinting"
echo "- Very small icons (16x16, 20x20) may need manual touch-ups"
echo "- Test visibility at all sizes before App Store submission"

echo ""
echo "✨ App icon generation complete!"
echo "🚀 Ready for testing in Xcode"

# Validate Contents.json exists
if [ -f "$ICON_DIR/Contents.json" ]; then
    echo "✅ Contents.json configuration file present"
else
    echo "⚠️  Contents.json missing - may need to regenerate AppIcon.appiconset"
fi