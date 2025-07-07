#!/usr/bin/env bash
# Simulate corruption of SwiftData store file for testing resilience
# Usage: ./Scripts/simulate_data_corruption.sh path/to/data/store/file

DATA_FILE="$1"
if [ -z "$DATA_FILE" ]; then
  echo "Usage: $0 path/to/data/store/file"
  exit 1
fi

# Corrupt random bytes in the middle of the file
FILE_SIZE=$(stat -c%s "$DATA_FILE")
CORRUPT_OFFSET=$(( FILE_SIZE / 2 ))
dd if=/dev/urandom bs=1 count=20 seek=$CORRUPT_OFFSET of="$DATA_FILE" conv=notrunc

echo "Corrupted $DATA_FILE at offset $CORRUPT_OFFSET" 