import Foundation

/// Simple circuit breaker pattern implementation
enum CircuitState {
    case closed
    case open
    case halfOpen
}

public class CircuitBreaker {
    private let failureThreshold: Int
    private let resetTimeout: TimeInterval
    private var failureCount: Int = 0
    private var state: CircuitState = .closed
    private var lastFailureTime: Date?

    public init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 60) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    /// Call before attempting the operation to decide if allowed
    public func allowRequest() -> Bool {
        switch state {
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > resetTimeout {
                state = .halfOpen
                return true
            }
            return false
        case .halfOpen, .closed:
            return true
        }
    }

    /// Record a successful operation
    public func recordSuccess() {
        failureCount = 0
        state = .closed
    }

    /// Record a failed operation
    public func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
        if failureCount >= failureThreshold {
            state = .open
        }
    }
} 