#!/bin/bash

# HealthAI 2030 App Icon Generator Script
# This script generates all required app icon sizes from a single 1024x1024 source image

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed.${NC}"
    echo "Please install it using: brew install imagemagick"
    exit 1
fi

# Check command line arguments
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Usage: $0 <source-icon-1024x1024.png>${NC}"
    echo "Please provide the path to your 1024x1024 source icon"
    exit 1
fi

SOURCE_ICON="$1"

# Verify source file exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo -e "${RED}Error: Source icon file not found: $SOURCE_ICON${NC}"
    exit 1
fi

# Set output directory
ICONSET_PATH="Sources/SharedResources/Assets.xcassets/AppIcon.appiconset"

# Create directory if it doesn't exist
mkdir -p "$ICONSET_PATH"

echo -e "${GREEN}Starting app icon generation...${NC}"

# iOS Icons
echo "Generating iOS icons..."
convert "$SOURCE_ICON" -resize 40x40 "$ICONSET_PATH/AppIcon-20@2x.png"
convert "$SOURCE_ICON" -resize 60x60 "$ICONSET_PATH/AppIcon-20@3x.png"
convert "$SOURCE_ICON" -resize 58x58 "$ICONSET_PATH/AppIcon-29@2x.png"
convert "$SOURCE_ICON" -resize 87x87 "$ICONSET_PATH/AppIcon-29@3x.png"
convert "$SOURCE_ICON" -resize 80x80 "$ICONSET_PATH/AppIcon-40@2x.png"
convert "$SOURCE_ICON" -resize 120x120 "$ICONSET_PATH/AppIcon-40@3x.png"
convert "$SOURCE_ICON" -resize 120x120 "$ICONSET_PATH/AppIcon-60@2x.png"
convert "$SOURCE_ICON" -resize 180x180 "$ICONSET_PATH/AppIcon-60@3x.png"

# iPad Icons
echo "Generating iPad icons..."
convert "$SOURCE_ICON" -resize 20x20 "$ICONSET_PATH/AppIcon-20.png"
convert "$SOURCE_ICON" -resize 29x29 "$ICONSET_PATH/AppIcon-29.png"
convert "$SOURCE_ICON" -resize 40x40 "$ICONSET_PATH/AppIcon-40.png"
convert "$SOURCE_ICON" -resize 76x76 "$ICONSET_PATH/AppIcon-76.png"
convert "$SOURCE_ICON" -resize 152x152 "$ICONSET_PATH/AppIcon-76@2x.png"
convert "$SOURCE_ICON" -resize 167x167 "$ICONSET_PATH/AppIcon-83.5@2x.png"

# App Store Icon (remove alpha channel)
echo "Generating App Store icon..."
convert "$SOURCE_ICON" -alpha remove -background white -alpha off "$ICONSET_PATH/AppIcon-1024.png"

# Dark mode variant (optional - adjust brightness/contrast as needed)
echo "Generating dark mode variant..."
convert "$SOURCE_ICON" -modulate 110,100 -alpha remove -background black -alpha off "$ICONSET_PATH/AppIcon-1024-dark.png"

# Tinted variant (optional - apply blue tint)
echo "Generating tinted variant..."
convert "$SOURCE_ICON" -colorize 20,20,40 -alpha remove -background white -alpha off "$ICONSET_PATH/AppIcon-1024-tinted.png"

# macOS Icons
echo "Generating macOS icons..."
convert "$SOURCE_ICON" -resize 16x16 "$ICONSET_PATH/app_icon_mac_16.png"
convert "$SOURCE_ICON" -resize 32x32 "$ICONSET_PATH/app_icon_mac_32.png"
convert "$SOURCE_ICON" -resize 64x64 "$ICONSET_PATH/app_icon_mac_64.png"
convert "$SOURCE_ICON" -resize 128x128 "$ICONSET_PATH/app_icon_mac_128.png"
convert "$SOURCE_ICON" -resize 256x256 "$ICONSET_PATH/app_icon_mac_256.png"
convert "$SOURCE_ICON" -resize 512x512 "$ICONSET_PATH/app_icon_mac_512.png"
convert "$SOURCE_ICON" -resize 1024x1024 "$ICONSET_PATH/app_icon_mac_1024.png"

# watchOS Icons
echo "Generating watchOS icons..."
convert "$SOURCE_ICON" -resize 48x48 "$ICONSET_PATH/app_icon_watch_48.png"
convert "$SOURCE_ICON" -resize 55x55 "$ICONSET_PATH/app_icon_watch_55.png"
convert "$SOURCE_ICON" -resize 58x58 "$ICONSET_PATH/app_icon_watch_58.png"
convert "$SOURCE_ICON" -resize 87x87 "$ICONSET_PATH/app_icon_watch_87.png"
convert "$SOURCE_ICON" -resize 80x80 "$ICONSET_PATH/app_icon_watch_80.png"
convert "$SOURCE_ICON" -resize 88x88 "$ICONSET_PATH/app_icon_watch_88.png"
convert "$SOURCE_ICON" -resize 100x100 "$ICONSET_PATH/app_icon_watch_100.png"
convert "$SOURCE_ICON" -resize 172x172 "$ICONSET_PATH/app_icon_watch_172.png"
convert "$SOURCE_ICON" -resize 196x196 "$ICONSET_PATH/app_icon_watch_196.png"
convert "$SOURCE_ICON" -resize 216x216 "$ICONSET_PATH/app_icon_watch_216.png"

# tvOS Icons (special handling for different aspect ratios)
echo -e "${YELLOW}Note: tvOS icons require custom designs due to different aspect ratios${NC}"
echo "Creating placeholder tvOS icons..."

# Create a centered version for tvOS with padding
convert "$SOURCE_ICON" -resize 360x360 -gravity center -background transparent -extent 400x240 "$ICONSET_PATH/app_icon_tv_400x240.png"
convert "$SOURCE_ICON" -resize 768x768 -gravity center -background transparent -extent 1280x768 "$ICONSET_PATH/app_icon_tv_1280x768.png"
convert "$SOURCE_ICON" -resize 1080x1080 -gravity center -background transparent -extent 1920x1080 "$ICONSET_PATH/app_icon_tv_1920x1080.png"

# Count generated files
ICON_COUNT=$(ls -1 "$ICONSET_PATH"/*.png 2>/dev/null | wc -l)

echo -e "${GREEN}✓ Icon generation complete!${NC}"
echo -e "Generated ${GREEN}$ICON_COUNT${NC} icon files in $ICONSET_PATH"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review generated icons in Xcode"
echo "2. Adjust tvOS icons if needed (they have different aspect ratios)"
echo "3. Build and test on all platforms"
echo "4. Consider creating platform-specific designs for optimal appearance"

# Verify critical files exist
echo ""
echo "Verifying critical icons..."
MISSING_FILES=0

# Check a few critical files
critical_files=(
    "AppIcon-1024.png"
    "AppIcon-60@3x.png"
    "app_icon_mac_512.png"
    "app_icon_watch_100.png"
)

for file in "${critical_files[@]}"; do
    if [ -f "$ICONSET_PATH/$file" ]; then
        echo -e "✓ $file"
    else
        echo -e "${RED}✗ $file${NC}"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "${GREEN}✓ All critical icons generated successfully!${NC}"
else
    echo -e "${RED}Warning: Some critical icons are missing. Please check the output.${NC}"
fi