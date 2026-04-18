import Foundation

public struct CalculateSleepDriftThresholdUseCase {
    public static let defaultThreshold: TimeInterval = 3 * 60 * 60
    public static let minimumThreshold: TimeInterval = 3 * 60 * 60

    public struct Input {
        /// Completed sleep events in any order — sorted internally by end date.
        public let completedSleepEvents: [SleepEvent]
        /// Active sleep start date used to select context-aware historical sessions.
        public let activeSleepStartedAt: Date?
        /// Number of most-recent sessions to consider.
        public let windowSize: Int

        public init(
            completedSleepEvents: [SleepEvent],
            activeSleepStartedAt: Date? = nil,
            windowSize: Int = 10
        ) {
            self.completedSleepEvents = completedSleepEvents
            self.activeSleepStartedAt = activeSleepStartedAt
            self.windowSize = windowSize
        }
    }

    public init() {}

    /// Returns the duration after sleep start at which to fire a drift notification.
    public func execute(_ input: Input) -> TimeInterval {
        let sessions: [SleepSession] = input.completedSleepEvents
            .compactMap { sleep -> SleepSession? in
                guard let endedAt = sleep.endedAt else { return nil }
                let duration = endedAt.timeIntervalSince(sleep.startedAt)
                // Discard sub-5-minute naps (likely accidental) and 14h+ sessions (likely errors)
                guard duration >= 300, duration <= 50_400 else { return nil }
                return SleepSession(startedAt: sleep.startedAt, endedAt: endedAt, duration: duration)
            }
            .sorted { $0.endedAt > $1.endedAt }

        guard sessions.count >= 3 else {
            return Self.defaultThreshold
        }

        let candidates = contextAwareSessions(from: sessions, activeSleepStartedAt: input.activeSleepStartedAt)
        let durations = Array(candidates.prefix(input.windowSize).map(\.duration))

        guard durations.count >= 3 else {
            return Self.defaultThreshold
        }

        let medianDuration = median(durations)

        // Buffer above typical session length, then apply safety floor and upper cap.
        let bufferedThreshold = medianDuration * 1.25
        let thresholdWithGrace = max(bufferedThreshold, medianDuration + 30 * 60)
        let cappedThreshold = min(thresholdWithGrace, 6 * 60 * 60)
        return max(cappedThreshold, Self.minimumThreshold)
    }

    private func contextAwareSessions(
        from sessions: [SleepSession],
        activeSleepStartedAt: Date?
    ) -> [SleepSession] {
        guard let activeSleepStartedAt else {
            return sessions
        }

        let calendar = Calendar.autoupdatingCurrent
        let activeBucket = sleepBucket(for: activeSleepStartedAt, calendar: calendar)
        let matching = sessions.filter { session in
            sleepBucket(for: session.startedAt, calendar: calendar) == activeBucket
        }

        if matching.count >= 3 {
            return matching
        }

        return sessions
    }

    private func sleepBucket(for date: Date, calendar: Calendar) -> SleepBucket {
        let hour = calendar.component(.hour, from: date)
        if hour >= 20 || hour < 6 {
            return .night
        }
        return .day
    }

    private func median(_ values: [TimeInterval]) -> TimeInterval {
        let sorted = values.sorted()
        let midpoint = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[midpoint - 1] + sorted[midpoint]) / 2
        }
        return sorted[midpoint]
    }
}

private struct SleepSession {
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
}

private enum SleepBucket {
    case day
    case night
}
