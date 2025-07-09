#!/bin/bash

# HealthAI 2030 Bundle Optimization Script
# This script optimizes the app bundle size by compressing assets, removing unused resources, and optimizing configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$PROJECT_ROOT/Assets"
RESOURCES_DIR="$PROJECT_ROOT/Resources"
BUILD_DIR="$PROJECT_ROOT/Build"
TEMP_DIR="/tmp/healthai_optimization"

# Optimization settings
IMAGE_QUALITY=80
PNG_QUALITY="65-80"
AUDIO_BITRATE="128k"
VIDEO_CRF=23

echo -e "${BLUE}🚀 Starting HealthAI 2030 Bundle Optimization${NC}"
echo -e "${BLUE}================================================${NC}"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to get file size
get_file_size() {
    if [[ -f "$1" ]]; then
        stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if (( bytes > 1073741824 )); then
        echo "$(( bytes / 1073741824 ))GB"
    elif (( bytes > 1048576 )); then
        echo "$(( bytes / 1048576 ))MB"
    elif (( bytes > 1024 )); then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "${bytes}B"
    fi
}

# Calculate initial bundle size
calculate_initial_size() {
    echo -e "${BLUE}📊 Calculating initial bundle size...${NC}"
    
    local total_size=0
    
    # Images
    local images_size=0
    if [[ -d "$ASSETS_DIR" ]]; then
        images_size=$(find "$ASSETS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    # Audio files
    local audio_size=0
    if [[ -d "$RESOURCES_DIR" ]]; then
        audio_size=$(find "$RESOURCES_DIR" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.aac" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    # Video files
    local video_size=0
    if [[ -d "$RESOURCES_DIR" ]]; then
        video_size=$(find "$RESOURCES_DIR" -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.m4v" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    # CoreML models
    local ml_size=0
    ml_size=$(find "$PROJECT_ROOT" -name "*.mlmodel" -o -name "*.mlmodelc" -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    
    total_size=$((images_size + audio_size + video_size + ml_size))
    
    echo -e "  Images: $(format_bytes $images_size)"
    echo -e "  Audio: $(format_bytes $audio_size)"
    echo -e "  Video: $(format_bytes $video_size)"
    echo -e "  ML Models: $(format_bytes $ml_size)"
    echo -e "  ${YELLOW}Total: $(format_bytes $total_size)${NC}"
    
    echo "$total_size" > "$TEMP_DIR/initial_size"
}

# Optimize images
optimize_images() {
    echo -e "${BLUE}🖼️  Optimizing images...${NC}"
    
    local optimized_count=0
    local total_saved=0
    
    # Install optimization tools if not present
    if ! command -v pngquant &> /dev/null; then
        echo -e "${YELLOW}Installing pngquant...${NC}"
        if command -v brew &> /dev/null; then
            brew install pngquant
        else
            print_warning "pngquant not found. Please install it manually."
            return 1
        fi
    fi
    
    if ! command -v jpegoptim &> /dev/null; then
        echo -e "${YELLOW}Installing jpegoptim...${NC}"
        if command -v brew &> /dev/null; then
            brew install jpegoptim
        else
            print_warning "jpegoptim not found. Please install it manually."
            return 1
        fi
    fi
    
    # Optimize PNG files
    if [[ -d "$ASSETS_DIR" ]]; then
        while IFS= read -r -d '' png_file; do
            local original_size=$(get_file_size "$png_file")
            
            # Create backup
            cp "$png_file" "$png_file.backup"
            
            # Optimize
            if pngquant --quality="$PNG_QUALITY" --force --ext .png "$png_file" 2>/dev/null; then
                local new_size=$(get_file_size "$png_file")
                local saved=$((original_size - new_size))
                
                if (( saved > 0 )); then
                    total_saved=$((total_saved + saved))
                    optimized_count=$((optimized_count + 1))
                    echo -e "  ✅ $(basename "$png_file"): $(format_bytes $saved) saved"
                else
                    # Restore backup if no savings
                    mv "$png_file.backup" "$png_file"
                fi
            else
                # Restore backup on error
                mv "$png_file.backup" "$png_file"
            fi
            
            # Remove backup
            rm -f "$png_file.backup"
        done < <(find "$ASSETS_DIR" -name "*.png" -type f -print0)
    fi
    
    # Optimize JPEG files
    if [[ -d "$ASSETS_DIR" ]]; then
        while IFS= read -r -d '' jpg_file; do
            local original_size=$(get_file_size "$jpg_file")
            
            # Create backup
            cp "$jpg_file" "$jpg_file.backup"
            
            # Optimize
            if jpegoptim --max="$IMAGE_QUALITY" --strip-all "$jpg_file" 2>/dev/null; then
                local new_size=$(get_file_size "$jpg_file")
                local saved=$((original_size - new_size))
                
                if (( saved > 0 )); then
                    total_saved=$((total_saved + saved))
                    optimized_count=$((optimized_count + 1))
                    echo -e "  ✅ $(basename "$jpg_file"): $(format_bytes $saved) saved"
                else
                    # Restore backup if no savings
                    mv "$jpg_file.backup" "$jpg_file"
                fi
            else
                # Restore backup on error
                mv "$jpg_file.backup" "$jpg_file"
            fi
            
            # Remove backup
            rm -f "$jpg_file.backup"
        done < <(find "$ASSETS_DIR" -name "*.jpg" -o -name "*.jpeg" -type f -print0)
    fi
    
    print_status "Optimized $optimized_count images, saved $(format_bytes $total_saved)"
}

# Optimize audio files
optimize_audio() {
    echo -e "${BLUE}🎵 Optimizing audio files...${NC}"
    
    local optimized_count=0
    local total_saved=0
    
    # Install ffmpeg if not present
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${YELLOW}Installing ffmpeg...${NC}"
        if command -v brew &> /dev/null; then
            brew install ffmpeg
        else
            print_warning "ffmpeg not found. Please install it manually."
            return 1
        fi
    fi
    
    if [[ -d "$RESOURCES_DIR" ]]; then
        while IFS= read -r -d '' audio_file; do
            local original_size=$(get_file_size "$audio_file")
            local temp_file="$TEMP_DIR/$(basename "$audio_file").tmp"
            
            # Convert to optimized format
            if ffmpeg -i "$audio_file" -b:a "$AUDIO_BITRATE" -y "$temp_file" 2>/dev/null; then
                local new_size=$(get_file_size "$temp_file")
                local saved=$((original_size - new_size))
                
                if (( saved > 0 )); then
                    mv "$temp_file" "$audio_file"
                    total_saved=$((total_saved + saved))
                    optimized_count=$((optimized_count + 1))
                    echo -e "  ✅ $(basename "$audio_file"): $(format_bytes $saved) saved"
                else
                    rm -f "$temp_file"
                fi
            fi
        done < <(find "$RESOURCES_DIR" -name "*.mp3" -o -name "*.wav" -o -name "*.aac" -type f -print0)
    fi
    
    print_status "Optimized $optimized_count audio files, saved $(format_bytes $total_saved)"
}

# Optimize video files
optimize_video() {
    echo -e "${BLUE}🎥 Optimizing video files...${NC}"
    
    local optimized_count=0
    local total_saved=0
    
    if [[ -d "$RESOURCES_DIR" ]]; then
        while IFS= read -r -d '' video_file; do
            local original_size=$(get_file_size "$video_file")
            local temp_file="$TEMP_DIR/$(basename "$video_file").tmp"
            
            # Convert to optimized format
            if ffmpeg -i "$video_file" -crf "$VIDEO_CRF" -preset slow -y "$temp_file" 2>/dev/null; then
                local new_size=$(get_file_size "$temp_file")
                local saved=$((original_size - new_size))
                
                if (( saved > 0 )); then
                    mv "$temp_file" "$video_file"
                    total_saved=$((total_saved + saved))
                    optimized_count=$((optimized_count + 1))
                    echo -e "  ✅ $(basename "$video_file"): $(format_bytes $saved) saved"
                else
                    rm -f "$temp_file"
                fi
            fi
        done < <(find "$RESOURCES_DIR" -name "*.mp4" -o -name "*.mov" -o -name "*.m4v" -type f -print0)
    fi
    
    print_status "Optimized $optimized_count video files, saved $(format_bytes $total_saved)"
}

# Remove unused resources
remove_unused_resources() {
    echo -e "${BLUE}🗑️  Removing unused resources...${NC}"
    
    local removed_count=0
    local total_saved=0
    
    # Common unused file patterns
    local unused_patterns=(
        "*.DS_Store"
        "Thumbs.db"
        "*.tmp"
        "*.temp"
        "*.backup"
        "*.orig"
        "*.bak"
        "*~"
        "*.swp"
        "*.swo"
        ".git*"
        ".svn*"
        "*.log"
        "*.cache"
    )
    
    for pattern in "${unused_patterns[@]}"; do
        while IFS= read -r -d '' unused_file; do
            local file_size=$(get_file_size "$unused_file")
            rm -f "$unused_file"
            total_saved=$((total_saved + file_size))
            removed_count=$((removed_count + 1))
            echo -e "  🗑️  Removed $(basename "$unused_file"): $(format_bytes $file_size)"
        done < <(find "$PROJECT_ROOT" -name "$pattern" -type f -print0)
    done
    
    print_status "Removed $removed_count unused files, saved $(format_bytes $total_saved)"
}

# Optimize CoreML models
optimize_ml_models() {
    echo -e "${BLUE}🧠 Optimizing CoreML models...${NC}"
    
    local optimized_count=0
    local total_saved=0
    
    # Find and optimize CoreML models
    while IFS= read -r -d '' ml_file; do
        local original_size=$(get_file_size "$ml_file")
        
        # Skip if already optimized
        if [[ "$ml_file" == *.mlmodelc ]]; then
            continue
        fi
        
        # Create optimized version using coremltools (if available)
        if command -v python3 &> /dev/null; then
            local temp_script="$TEMP_DIR/optimize_model.py"
            cat > "$temp_script" << 'EOF'
import coremltools as ct
import sys
import os

if len(sys.argv) != 3:
    print("Usage: optimize_model.py <input_model> <output_model>")
    sys.exit(1)

input_model = sys.argv[1]
output_model = sys.argv[2]

try:
    # Load the model
    model = ct.models.MLModel(input_model)
    
    # Optimize for size
    model_optimized = ct.optimize.coreml.optimize_weights(model)
    
    # Save optimized model
    model_optimized.save(output_model)
    
    print(f"Optimized model saved to {output_model}")
except Exception as e:
    print(f"Error optimizing model: {e}")
    sys.exit(1)
EOF
            
            local optimized_file="${ml_file%.mlmodel}_optimized.mlmodel"
            
            if python3 "$temp_script" "$ml_file" "$optimized_file" 2>/dev/null; then
                local new_size=$(get_file_size "$optimized_file")
                local saved=$((original_size - new_size))
                
                if (( saved > 0 )); then
                    mv "$optimized_file" "$ml_file"
                    total_saved=$((total_saved + saved))
                    optimized_count=$((optimized_count + 1))
                    echo -e "  ✅ $(basename "$ml_file"): $(format_bytes $saved) saved"
                else
                    rm -f "$optimized_file"
                fi
            fi
        fi
    done < <(find "$PROJECT_ROOT" -name "*.mlmodel" -type f -print0)
    
    print_status "Optimized $optimized_count ML models, saved $(format_bytes $total_saved)"
}

# Create optimization report
create_report() {
    echo -e "${BLUE}📋 Creating optimization report...${NC}"
    
    local initial_size=$(cat "$TEMP_DIR/initial_size")
    local final_size=0
    
    # Recalculate final size
    local images_size=0
    if [[ -d "$ASSETS_DIR" ]]; then
        images_size=$(find "$ASSETS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    local audio_size=0
    if [[ -d "$RESOURCES_DIR" ]]; then
        audio_size=$(find "$RESOURCES_DIR" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.aac" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    local video_size=0
    if [[ -d "$RESOURCES_DIR" ]]; then
        video_size=$(find "$RESOURCES_DIR" -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.m4v" \) -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    fi
    
    local ml_size=0
    ml_size=$(find "$PROJECT_ROOT" -name "*.mlmodel" -o -name "*.mlmodelc" -exec stat -f%z {} \; 2>/dev/null | awk '{sum += $1} END {print sum+0}')
    
    final_size=$((images_size + audio_size + video_size + ml_size))
    
    local total_saved=$((initial_size - final_size))
    local percentage_saved=0
    
    if (( initial_size > 0 )); then
        percentage_saved=$((total_saved * 100 / initial_size))
    fi
    
    # Create report
    local report_file="$PROJECT_ROOT/optimization_report.md"
    cat > "$report_file" << EOF
# Bundle Optimization Report

Generated on: $(date)

## Summary

- **Initial Size**: $(format_bytes $initial_size)
- **Final Size**: $(format_bytes $final_size)
- **Total Saved**: $(format_bytes $total_saved)
- **Percentage Saved**: ${percentage_saved}%

## Optimization Details

### Images
- Final Size: $(format_bytes $images_size)

### Audio Files
- Final Size: $(format_bytes $audio_size)

### Video Files
- Final Size: $(format_bytes $video_size)

### CoreML Models
- Final Size: $(format_bytes $ml_size)

## Optimization Settings

- PNG Quality: $PNG_QUALITY
- JPEG Quality: $IMAGE_QUALITY%
- Audio Bitrate: $AUDIO_BITRATE
- Video CRF: $VIDEO_CRF

## Recommendations

1. Consider implementing on-demand asset loading for infrequently used resources
2. Use asset catalogs for better compression and device-specific optimization
3. Implement progressive loading for large media files
4. Consider using cloud-based storage for optional content

---

Generated by HealthAI 2030 Bundle Optimization Script
EOF
    
    echo -e "${GREEN}📊 Optimization Report:${NC}"
    echo -e "  Initial Size: $(format_bytes $initial_size)"
    echo -e "  Final Size: $(format_bytes $final_size)"
    echo -e "  Total Saved: $(format_bytes $total_saved)"
    echo -e "  Percentage Saved: ${percentage_saved}%"
    echo -e "  Report saved to: $report_file"
}

# Clean up
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    rm -rf "$TEMP_DIR"
    print_status "Cleanup completed"
}

# Main execution
main() {
    # Check if running from correct directory
    if [[ ! -f "$PROJECT_ROOT/Package.swift" ]]; then
        print_error "This script must be run from the project root directory"
        exit 1
    fi
    
    # Calculate initial size
    calculate_initial_size
    
    # Run optimizations
    optimize_images
    optimize_audio
    optimize_video
    optimize_ml_models
    remove_unused_resources
    
    # Create report
    create_report
    
    # Clean up
    cleanup
    
    echo -e "${GREEN}🎉 Bundle optimization completed successfully!${NC}"
    echo -e "${GREEN}Check the optimization report for detailed results.${NC}"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"