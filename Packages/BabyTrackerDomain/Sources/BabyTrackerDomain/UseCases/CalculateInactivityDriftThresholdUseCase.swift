import Foundation

public struct CalculateInactivityDriftThresholdUseCase {
    public static let daytimeThreshold: TimeInterval = 6 * 60 * 60
    public static let defaultThreshold: TimeInterval = 12 * 60 * 60
    private static let daytimeStartHour = 5
    private static let nighttimeStartHour = 18

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
    public func execute(
        _ input: Input,
        randomMinuteOffset: () -> Int = { Int.random(in: 1...60) }
    ) -> TimeInterval {
        let randomOffset = TimeInterval(randomMinuteOffset() * 60)

        guard let lastEvent = input.events.max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt }) else {
            return Self.defaultThreshold + randomOffset
        }

        let hour = Calendar.autoupdatingCurrent.component(.hour, from: lastEvent.metadata.occurredAt)
        if hour >= Self.daytimeStartHour, hour < Self.nighttimeStartHour {
            return Self.daytimeThreshold + randomOffset
        }

        return Self.defaultThreshold + randomOffset
    }
}
