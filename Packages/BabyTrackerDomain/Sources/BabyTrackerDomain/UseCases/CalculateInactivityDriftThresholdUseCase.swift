import Foundation

public struct CalculateInactivityDriftThresholdUseCase {
    public static let defaultThreshold: TimeInterval = 4 * 60 * 60

    public struct Input {
        /// All non-deleted events for the child (any order — sorted internally).
        public let events: [BabyEvent]
        /// Number of most-recent gaps to average.
        public let windowSize: Int

        public init(events: [BabyEvent], windowSize: Int = 20) {
            self.events = events
            self.windowSize = windowSize
        }
    }

    public init() {}

    /// Returns the time interval after the last event at which to fire an inactivity notification.
    public func execute(_ input: Input) -> TimeInterval {
        let times = input.events
            .map(\.metadata.occurredAt)
            .sorted()

        guard times.count >= 4 else {
            return Self.defaultThreshold
        }

        var gaps: [TimeInterval] = []
        for i in 1..<times.count {
            let gap = times[i].timeIntervalSince(times[i - 1])
            // Ignore sub-minute duplicates and overnight gaps (>12h) that aren't
            // representative of normal waking-hours logging cadence
            guard gap > 60, gap < 12 * 60 * 60 else { continue }
            gaps.append(gap)
        }

        guard gaps.count >= 3 else {
            return Self.defaultThreshold
        }

        let recent = Array(gaps.suffix(input.windowSize))
        let average = recent.reduce(0, +) / Double(recent.count)

        // 2x average gives one full "expected next event window" of grace before nudging
        let threshold = min(average * 2.0, 8 * 60 * 60)
        return max(threshold, 60 * 60)
    }
}
