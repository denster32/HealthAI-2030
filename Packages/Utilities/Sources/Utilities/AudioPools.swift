import Foundation
import AVFoundation

// MARK: - AudioMemoryPool

/// A memory pool for reusing raw Float arrays to minimize allocations.
class AudioMemoryPool {
    static let shared = AudioMemoryPool()
    private var pool: [[Float]] = []
    private let lock = NSLock()

    private init() {}

    /// Obtains a Float array of the specified capacity from the pool, or creates a new one if none are available.
    /// - Parameter capacity: The desired capacity of the Float array.
    /// - Returns: A Float array ready for use.
    func obtainMemory(capacity: Int) -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        if let index = pool.firstIndex(where: { $0.capacity >= capacity }) {
            let buffer = pool.remove(at: index)
            return buffer
        } else {
            return [Float](repeating: 0.0, count: capacity)
        }
    }

    /// Releases a Float array back to the pool for reuse.
    /// - Parameter memory: The Float array to release.
    func releaseMemory(_ memory: [Float]) {
        lock.lock()
        defer { lock.unlock() }
        pool.append(memory)
    }

    /// Clears all memory from the pool.
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        pool.removeAll()
    }
}

// MARK: - AudioBufferPool

/// A buffer pool for reusing AVAudioPCMBuffer instances to minimize allocations.
class AudioBufferPool {
    static let shared = AudioBufferPool()
    private var pool: [AVAudioPCMBuffer] = []
    private let lock = NSLock()

    private init() {}

    /// Obtains an AVAudioPCMBuffer from the pool, or creates a new one if none are available.
    /// - Parameters:
    ///   - format: The audio format for the buffer.
    ///   - frameCapacity: The desired frame capacity of the buffer.
    /// - Returns: An AVAudioPCMBuffer ready for use.
    func obtainBuffer(format: AVAudioFormat, frameCapacity: AVAudioFrameCount) -> AVAudioPCMBuffer {
        lock.lock()
        defer { lock.unlock() }

        if let index = pool.firstIndex(where: { $0.format == format && $0.frameCapacity >= frameCapacity }) {
            let buffer = pool.remove(at: index)
            buffer.frameLength = 0 // Reset frameLength for reuse
            return buffer
        } else {
            return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)!
        }
    }

    /// Releases an AVAudioPCMBuffer back to the pool for reuse.
    /// - Parameter buffer: The AVAudioPCMBuffer to release.
    func releaseBuffer(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        // Reset buffer state before returning to pool
        buffer.frameLength = 0
        pool.append(buffer)
    }

    /// Clears all buffers from the pool.
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        pool.removeAll()
    }
}