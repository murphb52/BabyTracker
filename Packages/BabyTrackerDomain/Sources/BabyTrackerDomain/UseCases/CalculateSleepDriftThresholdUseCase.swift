import Foundation

public struct CalculateSleepDriftThresholdUseCase {
    public static let defaultThreshold: TimeInterval = 3 * 60 * 60

    public struct Input {
        /// Completed sleep events in any order — sorted internally by end date.
        public let completedSleepEvents: [SleepEvent]
        /// Number of most-recent sessions to average.
        public let windowSize: Int

        public init(completedSleepEvents: [SleepEvent], windowSize: Int = 10) {
            self.completedSleepEvents = completedSleepEvents
            self.windowSize = windowSize
        }
    }

    public init() {}

    /// Returns the duration after sleep start at which to fire a drift notification.
    public func execute(_ input: Input) -> TimeInterval {
        let durations: [TimeInterval] = input.completedSleepEvents
            .compactMap { sleep -> (endedAt: Date, duration: TimeInterval)? in
                guard let ended = sleep.endedAt else { return nil }
                let d = ended.timeIntervalSince(sleep.startedAt)
                // Discard sub-5-minute naps (likely accidental) and 14h+ sessions (likely errors)
                guard d >= 300, d <= 50_400 else { return nil }
                return (ended, d)
            }
            .sorted { $0.endedAt > $1.endedAt }
            .prefix(input.windowSize)
            .map(\.duration)

        guard durations.count >= 3 else {
            return Self.defaultThreshold
        }

        let average = durations.reduce(0, +) / Double(durations.count)

        // 20% buffer above average; cap at 6h to prevent outliers from creating excessive silence
        let threshold = min(average * 1.20, 6 * 60 * 60)
        // Always fire at least 30 minutes past the average
        return max(threshold, average + 30 * 60)
    }
}
