import Foundation

public struct HomeAwakeHeroCardViewState: Equatable, Sendable {
    /// The time the child woke up — the endedAt of the most recent completed sleep.
    /// Nil when no prior sleep has been recorded.
    public let awakeStartedAt: Date?

    public init(awakeStartedAt: Date?) {
        self.awakeStartedAt = awakeStartedAt
    }
}
