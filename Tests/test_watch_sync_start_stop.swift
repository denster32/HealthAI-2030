#!/usr/bin/env swift
import Foundation

class MockWatchManager {
    private(set) var backgroundSyncStarted = false
    private(set) var isSyncInProgress = false

    func startWatchDependentServices() {
        backgroundSyncStarted = true
    }

    func stopWatchDependentServices() {
        backgroundSyncStarted = false
        isSyncInProgress = false
    }

    func performBackgroundSync() {
        guard backgroundSyncStarted && !isSyncInProgress else { return }
        isSyncInProgress = true
        // simulate work
        isSyncInProgress = false
    }
}

let manager = MockWatchManager()

// Start/Stop basic
manager.startWatchDependentServices()
assert(manager.backgroundSyncStarted)
manager.stopWatchDependentServices()
assert(!manager.backgroundSyncStarted)

// Multiple starts should keep state true
manager.startWatchDependentServices()
manager.startWatchDependentServices()
assert(manager.backgroundSyncStarted)

// Perform sync twice to verify guard
manager.performBackgroundSync()
manager.performBackgroundSync() // should be ignored while already in progress
assert(!manager.isSyncInProgress)

// Interrupted sync
manager.performBackgroundSync()
manager.stopWatchDependentServices()
assert(!manager.isSyncInProgress)

print("All watch sync tests passed")
