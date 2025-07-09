#!/bin/bash

# Simulate SwiftData store corruption for testing resilience
# WARNING: This script is for testing purposes only and should not be used in production

# Check if a path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/swiftdata/store [corruption_type]"
    echo "Corruption types:"
    echo "  random    - Random byte corruption (default)"
    echo "  header    - Corrupt store header"
    echo "  metadata  - Corrupt metadata section"
    echo "  partial   - Partial file corruption"
    echo "  complete  - Complete file corruption"
    exit 1
fi

STORE_PATH="$1"
CORRUPTION_TYPE="${2:-random}"

# Check if store exists
if [ ! -f "$STORE_PATH" ]; then
    echo "Error: Store file not found at $STORE_PATH"
    exit 1
fi

# Backup the original store
BACKUP_PATH="$STORE_PATH.backup.$(date +%Y%m%d_%H%M%S)"
cp "$STORE_PATH" "$BACKUP_PATH"
echo "Original store backed up to $BACKUP_PATH"

# Get file size
FILE_SIZE=$(stat -c%s "$STORE_PATH" 2>/dev/null || stat -f%z "$STORE_PATH" 2>/dev/null)
echo "Store file size: $FILE_SIZE bytes"

# Simulate different types of corruption
case "$CORRUPTION_TYPE" in
    "random")
        echo "Simulating random byte corruption..."
        # Corrupt random bytes throughout the file
        dd if=/dev/urandom of="$STORE_PATH" bs=1 count=100 seek=$((RANDOM % (FILE_SIZE - 100))) conv=notrunc
        ;;
    "header")
        echo "Simulating header corruption..."
        # Corrupt the first 1KB (likely contains header info)
        dd if=/dev/urandom of="$STORE_PATH" bs=1024 count=1 seek=0 conv=notrunc
        ;;
    "metadata")
        echo "Simulating metadata corruption..."
        # Corrupt a section that might contain metadata (around 10% into file)
        METADATA_OFFSET=$((FILE_SIZE / 10))
        dd if=/dev/urandom of="$STORE_PATH" bs=512 count=2 seek=$METADATA_OFFSET conv=notrunc
        ;;
    "partial")
        echo "Simulating partial file corruption..."
        # Corrupt the middle portion of the file
        MIDDLE_OFFSET=$((FILE_SIZE / 2))
        dd if=/dev/urandom of="$STORE_PATH" bs=1024 count=5 seek=$MIDDLE_OFFSET conv=notrunc
        ;;
    "complete")
        echo "Simulating complete file corruption..."
        # Corrupt the entire file
        dd if=/dev/urandom of="$STORE_PATH" bs=1024 count=$((FILE_SIZE / 1024)) seek=0 conv=notrunc
        ;;
    *)
        echo "Unknown corruption type: $CORRUPTION_TYPE"
        echo "Using random corruption..."
        dd if=/dev/urandom of="$STORE_PATH" bs=1 count=100 seek=$((RANDOM % (FILE_SIZE - 100))) conv=notrunc
        ;;
esac

echo "Store corruption simulation complete ($CORRUPTION_TYPE)"
echo "WARNING: This is a simulated corruption for testing purposes only."
echo "To restore: cp $BACKUP_PATH $STORE_PATH"

exit 0 