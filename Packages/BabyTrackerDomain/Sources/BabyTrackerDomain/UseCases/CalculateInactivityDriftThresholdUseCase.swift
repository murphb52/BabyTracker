import Foundation

public struct CalculateInactivityDriftThresholdUseCase {
    public static let defaultThreshold: TimeInterval = 4 * 60 * 60
    public static let minimumThreshold: TimeInterval = 2 * 60 * 60

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
        let sortedEvents = input.events.sorted { $0.metadata.occurredAt < $1.metadata.occurredAt }

        guard sortedEvents.count >= 4 else {
            return Self.defaultThreshold
        }

        var gaps: [TimeInterval] = []
        for index in 1..<sortedEvents.count {
            let previous = sortedEvents[index - 1]
            let current = sortedEvents[index]

            // Sleep transitions naturally create longer quiet periods that should not be
            // treated as normal "missed logging" cadence.
            guard previous.kind != .sleep, current.kind != .sleep else { continue }

            let gap = current.metadata.occurredAt.timeIntervalSince(previous.metadata.occurredAt)
            // Ignore sub-minute duplicates and overnight gaps (>12h) that aren't
            // representative of normal waking-hours logging cadence.
            guard gap > 60, gap < 12 * 60 * 60 else { continue }
            gaps.append(gap)
        }

        guard gaps.count >= 3 else {
            return Self.defaultThreshold
        }

        let recent = Array(gaps.suffix(input.windowSize))
        let medianGap = median(recent)

        // 2x median gives one full "expected next event window" of grace before nudging.
        let threshold = min(medianGap * 2.0, 8 * 60 * 60)
        return max(threshold, Self.minimumThreshold)
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
