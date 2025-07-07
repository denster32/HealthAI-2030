#!/bin/bash

# Simulate SwiftData store corruption for testing resilience
# WARNING: This script is for testing purposes only and should not be used in production

# Check if a path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/swiftdata/store"
    exit 1
fi

STORE_PATH="$1"

# Backup the original store
cp -r "$STORE_PATH" "$STORE_PATH.backup"

# Simulate corruption by randomly modifying bytes
echo "Simulating SwiftData store corruption..."

# Use dd to write random data to a portion of the store
dd if=/dev/urandom of="$STORE_PATH" bs=1024 count=10 seek=$((RANDOM % 1000)) conv=notrunc

echo "Store corruption simulation complete. Original store backed up to $STORE_PATH.backup"
echo "WARNING: This is a simulated corruption for testing purposes only."

exit 0 