import Foundation
import Synchronization

/// Records which CloudKit requests are currently in flight and when each one
/// started, so a refresh pass can tell a slow-but-progressing sync (many
/// quick requests) apart from one stuck on a single request that never returns.
final class CloudKitRequestTracker: Sendable {
    private let startTimesByRequestID = Mutex<[UUID: ContinuousClock.Instant]>([:])

    func requestStarted() -> UUID {
        let requestID = UUID()
        startTimesByRequestID.withLock { $0[requestID] = .now }
        return requestID
    }

    func requestFinished(_ requestID: UUID) {
        startTimesByRequestID.withLock { $0[requestID] = nil }
    }

    /// How long the oldest request still in flight has been running, or nil
    /// when nothing is in flight.
    func longestRunningRequestDuration() -> Duration? {
        let oldestStart = startTimesByRequestID.withLock { $0.values.min() }
        return oldestStart.map { ContinuousClock.now - $0 }
    }
}
