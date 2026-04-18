import Foundation

public struct CalculateSleepDriftThresholdUseCase {
    public static let daytimeThreshold: TimeInterval = 6 * 60 * 60
    public static let defaultThreshold: TimeInterval = 12 * 60 * 60
    private static let daytimeStartHour = 5
    private static let nighttimeStartHour = 18

    public struct Input {
        /// Start time for the currently active sleep session.
        public let activeSleepStartedAt: Date

        public init(activeSleepStartedAt: Date) {
            self.activeSleepStartedAt = activeSleepStartedAt
        }
    }

    public init() {}

    /// Returns the duration after sleep start at which to fire a drift notification.
    public func execute(
        _ input: Input,
        randomMinuteOffset: () -> Int = { Int.random(in: 1...60) }
    ) -> TimeInterval {
        let randomOffset = TimeInterval(randomMinuteOffset() * 60)
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: input.activeSleepStartedAt)
        if hour >= Self.daytimeStartHour, hour < Self.nighttimeStartHour {
            return Self.daytimeThreshold + randomOffset
        }

        return Self.defaultThreshold + randomOffset
    }
}
