#!/bin/bash

# HealthAI 2030 Color Assets Generator
# This script generates all color assets for the unified design system

COLORS_DIR="Resources/Colors.xcassets"

# Function to create color asset
create_color_asset() {
    local color_name=$1
    local red=$2
    local green=$3
    local blue=$4
    local dark_red=$5
    local dark_green=$6
    local dark_blue=$7
    
    local color_dir="$COLORS_DIR/${color_name}.colorset"
    mkdir -p "$color_dir"
    
    cat > "$color_dir/Contents.json" << EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$blue",
          "green" : "$green",
          "red" : "$red"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$dark_blue",
          "green" : "$dark_green",
          "red" : "$dark_red"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
}

echo "Generating HealthAI 2030 color assets..."

# Create all color assets
create_color_asset "Accent" "0.200" "0.800" "0.600" "0.250" "0.850" "0.650"
create_color_asset "Warning" "1.000" "0.700" "0.000" "1.000" "0.750" "0.000"
create_color_asset "Info" "0.300" "0.700" "1.000" "0.350" "0.750" "1.000"

# Health-specific colors
create_color_asset "Sleep" "0.400" "0.200" "0.800" "0.450" "0.250" "0.850"
create_color_asset "Activity" "0.200" "0.800" "0.400" "0.250" "0.850" "0.450"
create_color_asset "Nutrition" "1.000" "0.800" "0.000" "1.000" "0.850" "0.000"
create_color_asset "MentalHealth" "0.800" "0.400" "0.800" "0.850" "0.450" "0.850"
create_color_asset "Respiratory" "0.200" "0.800" "0.800" "0.250" "0.850" "0.850"
create_color_asset "BloodPressure" "0.800" "0.300" "0.900" "0.850" "0.350" "0.950"
create_color_asset "Glucose" "0.600" "0.300" "0.900" "0.650" "0.350" "0.950"
create_color_asset "Weight" "0.400" "0.600" "0.800" "0.450" "0.650" "0.850"
create_color_asset "Temperature" "1.000" "0.600" "0.000" "1.000" "0.650" "0.000"

# Background colors
create_color_asset "Background" "0.040" "0.040" "0.040" "0.000" "0.000" "0.000"
create_color_asset "Surface" "0.120" "0.120" "0.160" "0.080" "0.080" "0.120"
create_color_asset "Card" "0.080" "0.080" "0.120" "0.120" "0.120" "0.160"
create_color_asset "Overlay" "0.000" "0.000" "0.000" "0.000" "0.000" "0.000"

# Text colors
create_color_asset "TextPrimary" "1.000" "1.000" "1.000" "1.000" "1.000" "1.000"
create_color_asset "TextSecondary" "0.800" "0.800" "0.800" "0.700" "0.700" "0.700"
create_color_asset "TextTertiary" "0.600" "0.600" "0.600" "0.500" "0.500" "0.500"
create_color_asset "TextInverse" "0.000" "0.000" "0.000" "0.000" "0.000" "0.000"

# Border colors
create_color_asset "Border" "0.300" "0.300" "0.300" "0.200" "0.200" "0.200"
create_color_asset "BorderLight" "0.200" "0.200" "0.200" "0.150" "0.150" "0.150"

# Status colors
create_color_asset "Healthy" "0.200" "0.800" "0.400" "0.250" "0.850" "0.450"
create_color_asset "Elevated" "1.000" "0.700" "0.000" "1.000" "0.750" "0.000"
create_color_asset "Critical" "0.900" "0.300" "0.300" "0.950" "0.350" "0.350"
create_color_asset "Unknown" "0.600" "0.600" "0.600" "0.500" "0.500" "0.500"

echo "✅ All color assets generated successfully!"
echo "Generated colors:"
ls -la "$COLORS_DIR"/*.colorset/Contents.json | wc -l | tr -d ' ' && echo " color assets" 