# CloudKit Conflict Resolution Strategy

This document outlines the conflict resolution approach used in HealthAI 2030 when synchronizing models via CloudKit.

## Strategy

- Last-Write-Wins
  - When multiple devices modify the same record (identical `id`), the version with the most recent modification timestamp is retained.
  - Local offline updates are pending until sync; when syncing, CloudKit applies the entry with the latest timestamp.

## Implementation Details

- `SwiftDataManager` uses `CKSyncable.syncStatus` and model context save timestamps to determine which change to apply.
- During fetch, conflicts are resolved by comparing timestamps and keeping the newest record.

## Models Covered

- `TestModel`, `HealthDataEntry`, and all other models conforming to `PersistentModel & CKSyncable`.

## Rationale

- Ensures user actions are correctly preserved without data loss.
- Provides a simple and predictable merging strategy for multi-device scenarios. 